use solana_program::{
    account_info::{next_account_info, AccountInfo},
    entrypoint,
    entrypoint::ProgramResult,
    msg,
    program::{invoke, invoke_signed},
    program_error::ProgramError,
    pubkey::Pubkey,
    system_instruction,
    sysvar::{rent::Rent, Sysvar},
};
use spl_token::{
    instruction::{approve, transfer},
    state::Account as TokenAccount,
};
use borsh::{BorshDeserialize, BorshSerialize};
use std::mem;

pub mod instruction;
pub mod state;

use instruction::{EscrowInstruction, EscrowError};
use state::{EscrowState, EscrowConfig, EscrowStatus, FEE_BASIS_POINTS, BASIS_POINTS_DIVISOR, MIN_DEPOSIT_SOL, MIN_DEPOSIT_USDT, MIN_DEPOSIT_USDC};

entrypoint!(process_instruction);

pub fn process_instruction(
    program_id: &Pubkey,
    accounts: &[AccountInfo],
    instruction_data: &[u8],
) -> ProgramResult {
    msg!("Escrow Program Entrypoint");

    let instruction = EscrowInstruction::unpack(instruction_data)?;

    match instruction {
        EscrowInstruction::InitializeConfig => {
            initialize_config(program_id, accounts)
        }
        EscrowInstruction::CreateEscrow { amount, token_mint } => {
            create_escrow(program_id, accounts, amount, token_mint)
        }
        EscrowInstruction::ReleaseFunds => {
            release_funds(program_id, accounts)
        }
        EscrowInstruction::CancelEscrow => {
            cancel_escrow(program_id, accounts)
        }
        EscrowInstruction::RaiseDispute { reason } => {
            raise_dispute(program_id, accounts, reason)
        }
        EscrowInstruction::ResolveDispute { release_to_freelancer } => {
            resolve_dispute(program_id, accounts, release_to_freelancer)
        }
    }
}

fn initialize_config(program_id: &Pubkey, accounts: &[AccountInfo]) -> ProgramResult {
    let accounts_iter = &mut accounts.iter();
    let admin = next_account_info(accounts_iter)?;
    let config_account = next_account_info(accounts_iter)?;
    let treasury_wallet = next_account_info(accounts_iter)?;

    if !admin.is_signer {
        return Err(EscrowError::NotAuthorized.into());
    }

    // Prevent re-initialization
    if config_account.data.borrow()[0] != 0 {
        return Err(EscrowError::InvalidInstruction.into());
    }

    // Initialize config with admin and treasury
    let config = EscrowConfig::new(*admin.key, *treasury_wallet.key);
    config.serialize(&mut &mut config_account.data.borrow_mut()[..])?;

    msg!("Escrow config initialized with admin: {}", admin.key);
    Ok(())
}

fn create_escrow(
    program_id: &Pubkey,
    accounts: &[AccountInfo],
    amount: u64,
    token_mint: Option<Pubkey>,
) -> ProgramResult {
    let accounts_iter = &mut accounts.iter();
    let client = next_account_info(accounts_iter)?;
    let escrow_account = next_account_info(accounts_iter)?;
    let freelancer = next_account_info(accounts_iter)?;
    let client_token_account = next_account_info(accounts_iter)?;
    let escrow_token_account = next_account_info(accounts_iter)?;
    let token_mint_account = next_account_info(accounts_iter)?;
    let token_program = next_account_info(accounts_iter)?;
    let system_program = next_account_info(accounts_iter)?;

    if !client.is_signer {
        return Err(EscrowError::NotAuthorized.into());
    }

    // Validate minimum deposit amount
    validate_minimum_deposit(amount, token_mint)?;

    // Handle SOL or SPL token transfer
    if token_mint.is_none() {
        // SOL transfer
        let transfer_instruction = system_instruction::transfer(
            client.key,
            escrow_account.key,
            amount,
        );
        invoke(
            &transfer_instruction,
            &[
                client.clone(),
                escrow_account.clone(),
                system_program.clone(),
            ],
        )?;
    } else {
        // SPL token transfer
        let transfer_instruction = transfer(
            token_program.key,
            client_token_account.key,
            escrow_token_account.key,
            client.key,
            &[],
            amount,
        )?;
        invoke(
            &transfer_instruction,
            &[
                token_program.clone(),
                client_token_account.clone(),
                escrow_token_account.clone(),
                client.clone(),
            ],
        )?;
    }

    // Initialize escrow state
    let escrow_state = EscrowState::new(*client.key, *freelancer.key, amount, token_mint);
    escrow_state.serialize(&mut &mut escrow_account.data.borrow_mut()[..])?;

    msg!("Escrow created with amount: {}", amount);
    Ok(())
}

fn release_funds(program_id: &Pubkey, accounts: &[AccountInfo]) -> ProgramResult {
    let accounts_iter = &mut accounts.iter();
    let client = next_account_info(accounts_iter)?;
    let escrow_account = next_account_info(accounts_iter)?;
    let freelancer_account = next_account_info(accounts_iter)?;
    let treasury_account = next_account_info(accounts_iter)?;
    let escrow_token_account = next_account_info(accounts_iter)?;
    let token_program = next_account_info(accounts_iter)?;
    let system_program = next_account_info(accounts_iter)?;

    if !client.is_signer {
        return Err(EscrowError::NotAuthorized.into());
    }

    // Deserialize escrow state
    let mut escrow_state = EscrowState::try_from_slice(&escrow_account.data.borrow())?;

    // Verify client matches escrow client
    if *client.key != escrow_state.client {
        return Err(EscrowError::NotAuthorized.into());
    }

    if escrow_state.is_released() {
        return Err(EscrowError::AlreadyReleased.into());
    }

    if !escrow_state.can_be_released() {
        return Err(EscrowError::InvalidInstruction.into());
    }

    // Calculate fee (5% of amount)
    let fee_amount = (escrow_state.amount * FEE_BASIS_POINTS) / BASIS_POINTS_DIVISOR;
    let freelancer_amount = escrow_state.amount - fee_amount;

    if escrow_state.token_mint.is_none() {
        // SOL transfer - release to freelancer and treasury
        let transfer_freelancer = system_instruction::transfer(
            escrow_account.key,
            freelancer_account.key,
            freelancer_amount,
        );
        invoke(
            &transfer_freelancer,
            &[
                escrow_account.clone(),
                freelancer_account.clone(),
                system_program.clone(),
            ],
        )?;

        let transfer_treasury = system_instruction::transfer(
            escrow_account.key,
            treasury_account.key,
            fee_amount,
        );
        invoke(
            &transfer_treasury,
            &[
                escrow_account.clone(),
                treasury_account.clone(),
                system_program.clone(),
            ],
        )?;
    } else {
        // SPL token transfer
        let transfer_freelancer = transfer(
            token_program.key,
            escrow_token_account.key,
            freelancer_account.key,
            escrow_account.key,
            &[],
            freelancer_amount,
        )?;
        invoke(
            &transfer_freelancer,
            &[
                token_program.clone(),
                escrow_token_account.clone(),
                freelancer_account.clone(),
                escrow_account.clone(),
            ],
        )?;

        let transfer_treasury = transfer(
            token_program.key,
            escrow_token_account.key,
            treasury_account.key,
            escrow_account.key,
            &[],
            fee_amount,
        )?;
        invoke(
            &transfer_treasury,
            &[
                token_program.clone(),
                escrow_token_account.clone(),
                treasury_account.clone(),
                escrow_account.clone(),
            ],
        )?;
    }

    // Update escrow state
    escrow_state.mark_released();
    escrow_state.serialize(&mut &mut escrow_account.data.borrow_mut()[..])?;

    msg!("Funds released. Freelancer: {}, Fee: {}", freelancer_amount, fee_amount);
    Ok(())
}

fn cancel_escrow(program_id: &Pubkey, accounts: &[AccountInfo]) -> ProgramResult {
    let accounts_iter = &mut accounts.iter();
    let client = next_account_info(accounts_iter)?;
    let escrow_account = next_account_info(accounts_iter)?;
    let client_refund_account = next_account_info(accounts_iter)?;
    let escrow_token_account = next_account_info(accounts_iter)?;
    let token_program = next_account_info(accounts_iter)?;
    let system_program = next_account_info(accounts_iter)?;

    if !client.is_signer {
        return Err(EscrowError::NotAuthorized.into());
    }

    // Deserialize escrow state
    let mut escrow_state = EscrowState::try_from_slice(&escrow_account.data.borrow())?;

    // Verify client matches escrow client
    if *client.key != escrow_state.client {
        return Err(EscrowError::NotAuthorized.into());
    }

    if escrow_state.is_released() {
        return Err(EscrowError::AlreadyReleased.into());
    }

    if !escrow_state.can_be_cancelled() {
        return Err(EscrowError::InvalidInstruction.into());
    }

    if escrow_state.token_mint.is_none() {
        // SOL refund
        let transfer_instruction = system_instruction::transfer(
            escrow_account.key,
            client_refund_account.key,
            escrow_state.amount,
        );
        invoke(
            &transfer_instruction,
            &[
                escrow_account.clone(),
                client_refund_account.clone(),
                system_program.clone(),
            ],
        )?;
    } else {
        // SPL token refund
        let transfer_instruction = transfer(
            token_program.key,
            escrow_token_account.key,
            client_refund_account.key,
            escrow_account.key,
            &[],
            escrow_state.amount,
        )?;
        invoke(
            &transfer_instruction,
            &[
                token_program.clone(),
                escrow_token_account.clone(),
                client_refund_account.clone(),
                escrow_account.clone(),
            ],
        )?;
    }

    // Update escrow state
    escrow_state.mark_cancelled();
    escrow_state.serialize(&mut &mut escrow_account.data.borrow_mut()[..])?;

    msg!("Escrow cancelled and funds refunded");
    Ok(())
}

fn raise_dispute(program_id: &Pubkey, accounts: &[AccountInfo], reason: String) -> ProgramResult {
    let accounts_iter = &mut accounts.iter();
    let disputer = next_account_info(accounts_iter)?;
    let escrow_account = next_account_info(accounts_iter)?;

    if !disputer.is_signer {
        return Err(EscrowError::NotAuthorized.into());
    }

    // Deserialize escrow state
    let mut escrow_state = EscrowState::try_from_slice(&escrow_account.data.borrow())?;

    if escrow_state.is_released() {
        return Err(EscrowError::AlreadyReleased.into());
    }

    if escrow_state.is_disputed() {
        return Err(EscrowError::DisputeAlreadyRaised.into());
    }

    // Only client or freelancer can raise dispute
    if *disputer.key != escrow_state.client && *disputer.key != escrow_state.freelancer {
        return Err(EscrowError::NotAuthorized.into());
    }

    // Mark as disputed
    escrow_state.mark_disputed(*disputer.key, reason);
    escrow_state.serialize(&mut &mut escrow_account.data.borrow_mut()[..])?;

    msg!("Dispute raised by: {}", disputer.key);
    Ok(())
}

fn resolve_dispute(program_id: &Pubkey, accounts: &[AccountInfo], release_to_freelancer: bool) -> ProgramResult {
    let accounts_iter = &mut accounts.iter();
    let admin = next_account_info(accounts_iter)?;
    let config_account = next_account_info(accounts_iter)?;
    let escrow_account = next_account_info(accounts_iter)?;
    let freelancer_account = next_account_info(accounts_iter)?;
    let client_account = next_account_info(accounts_iter)?;
    let treasury_account = next_account_info(accounts_iter)?;
    let escrow_token_account = next_account_info(accounts_iter)?;
    let token_program = next_account_info(accounts_iter)?;
    let system_program = next_account_info(accounts_iter)?;

    if !admin.is_signer {
        return Err(EscrowError::NotAuthorized.into());
    }

    // Verify admin matches config admin
    let config = EscrowConfig::try_from_slice(&config_account.data.borrow())?;
    if *admin.key != config.admin {
        return Err(EscrowError::NotAuthorized.into());
    }

    // Deserialize escrow state
    let mut escrow_state = EscrowState::try_from_slice(&escrow_account.data.borrow())?;

    if !escrow_state.is_disputed() {
        return Err(EscrowError::NotInDispute.into());
    }

    if escrow_state.is_released() {
        return Err(EscrowError::AlreadyReleased.into());
    }

    // Calculate fee (5% of amount)
    let fee_amount = (escrow_state.amount * FEE_BASIS_POINTS) / BASIS_POINTS_DIVISOR;

    if release_to_freelancer {
        // Release funds to freelancer (minus fee)
        let freelancer_amount = escrow_state.amount - fee_amount;

        if escrow_state.token_mint.is_none() {
            // SOL transfer
            let transfer_freelancer = system_instruction::transfer(
                escrow_account.key,
                freelancer_account.key,
                freelancer_amount,
            );
            invoke(
                &transfer_freelancer,
                &[
                    escrow_account.clone(),
                    freelancer_account.clone(),
                    system_program.clone(),
                ],
            )?;

            let transfer_treasury = system_instruction::transfer(
                escrow_account.key,
                treasury_account.key,
                fee_amount,
            );
            invoke(
                &transfer_treasury,
                &[
                    escrow_account.clone(),
                    treasury_account.clone(),
                    system_program.clone(),
                ],
            )?;
        } else {
            // SPL token transfer
            let transfer_freelancer = transfer(
                token_program.key,
                escrow_token_account.key,
                freelancer_account.key,
                escrow_account.key,
                &[],
                freelancer_amount,
            )?;
            invoke(
                &transfer_freelancer,
                &[
                    token_program.clone(),
                    escrow_token_account.clone(),
                    freelancer_account.clone(),
                    escrow_account.clone(),
                ],
            )?;

            let transfer_treasury = transfer(
                token_program.key,
                escrow_token_account.key,
                treasury_account.key,
                escrow_account.key,
                &[],
                fee_amount,
            )?;
            invoke(
                &transfer_treasury,
                &[
                    token_program.clone(),
                    escrow_token_account.clone(),
                    treasury_account.clone(),
                    escrow_account.clone(),
                ],
            )?;
        }

        escrow_state.mark_released();
    } else {
        // Refund to client
        if escrow_state.token_mint.is_none() {
            // SOL refund
            let transfer_instruction = system_instruction::transfer(
                escrow_account.key,
                client_account.key,
                escrow_state.amount,
            );
            invoke(
                &transfer_instruction,
                &[
                    escrow_account.clone(),
                    client_account.clone(),
                    system_program.clone(),
                ],
            )?;
        } else {
            // SPL token refund
            let transfer_instruction = transfer(
                token_program.key,
                escrow_token_account.key,
                client_account.key,
                escrow_account.key,
                &[],
                escrow_state.amount,
            )?;
            invoke(
                &transfer_instruction,
                &[
                    token_program.clone(),
                    escrow_token_account.clone(),
                    client_account.clone(),
                    escrow_account.clone(),
                ],
            )?;
        }

        escrow_state.mark_cancelled();
    }

    escrow_state.serialize(&mut &mut escrow_account.data.borrow_mut()[..])?;
    msg!("Dispute resolved. Release to freelancer: {}", release_to_freelancer);
    Ok(())
}

fn validate_minimum_deposit(amount: u64, token_mint: Option<Pubkey>) -> ProgramResult {
    // For simplicity, we'll use hardcoded minimums
    // In a real implementation, you'd read from config account
    let min_amount = match token_mint {
        None => MIN_DEPOSIT_SOL, // SOL
        Some(mint) => {
            // In real implementation, you'd check mint address against known USDT/USDC addresses
            // For now, we'll use the same minimum for all SPL tokens
            MIN_DEPOSIT_USDT
        }
    };

    if amount < min_amount {
        msg!("Deposit amount {} below minimum {}", amount, min_amount);
        return Err(EscrowError::InsufficientFunds.into());
    }

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use solana_program::clock::Epoch;
    use solana_sdk::{account_info::AccountInfo, signature::Signer, signer::keypair::Keypair};
    use std::mem;

    #[test]
    fn test_validate_minimum_deposit() {
        // Test SOL minimum
        assert!(validate_minimum_deposit(MIN_DEPOSIT_SOL, None).is_ok());
        assert!(validate_minimum_deposit(MIN_DEPOSIT_SOL - 1, None).is_err());
        
        // Test SPL token minimum
        let test_mint = Pubkey::new_unique();
        assert!(validate_minimum_deposit(MIN_DEPOSIT_USDT, Some(test_mint)).is_ok());
        assert!(validate_minimum_deposit(MIN_DEPOSIT_USDT - 1, Some(test_mint)).is_err());
    }
}