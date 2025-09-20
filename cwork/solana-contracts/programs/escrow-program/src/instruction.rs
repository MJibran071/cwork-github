use solana_program::{
    program_error::ProgramError,
    pubkey::Pubkey,
};
use borsh::{BorshDeserialize, BorshSerialize};
use thiserror::Error;

#[derive(BorshSerialize, BorshDeserialize, Debug)]
pub enum EscrowInstruction {
    /// Initialize escrow with configuration
    InitializeConfig,
    
    /// Create a new escrow deposit
    CreateEscrow {
        amount: u64,
        token_mint: Option<Pubkey>,
    },
    
    /// Release funds from escrow to freelancer (minus fee)
    ReleaseFunds,
    
    /// Cancel escrow and refund client
    CancelEscrow,
    
    /// Raise a dispute on an escrow
    RaiseDispute {
        reason: String,
    },
    
    /// Resolve a dispute (admin only)
    ResolveDispute {
        release_to_freelancer: bool,
    },
}

#[derive(Error, Debug, Copy, Clone)]
pub enum EscrowError {
    #[error("Invalid instruction")]
    InvalidInstruction,
    #[error("Not authorized")]
    NotAuthorized,
    #[error("Insufficient funds")]
    InsufficientFunds,
    #[error("Escrow already released")]
    AlreadyReleased,
    #[error("Escrow not found")]
    EscrowNotFound,
    #[error("Invalid token mint")]
    InvalidTokenMint,
    #[error("Dispute already raised")]
    DisputeAlreadyRaised,
    #[error("Not in dispute state")]
    NotInDispute,
}

impl From<EscrowError> for ProgramError {
    fn from(e: EscrowError) -> Self {
        ProgramError::Custom(e as u32)
    }
}

impl EscrowInstruction {
    pub fn unpack(input: &[u8]) -> Result<Self, ProgramError> {
        let (tag, rest) = input.split_first().ok_or(EscrowError::InvalidInstruction)?;
        
        Ok(match tag {
            0 => EscrowInstruction::InitializeConfig,
            1 => {
                let (amount, rest) = rest.split_at(8);
                let amount = u64::from_le_bytes(amount.try_into().unwrap());
                let token_mint = if rest.len() >= 32 {
                    Some(Pubkey::new_from_array(rest[..32].try_into().unwrap()))
                } else {
                    None
                };
                EscrowInstruction::CreateEscrow { amount, token_mint }
            }
            2 => EscrowInstruction::ReleaseFunds,
            3 => EscrowInstruction::CancelEscrow,
            4 => {
                let reason_len = rest.get(0).ok_or(EscrowError::InvalidInstruction)?;
                let reason_bytes = rest.get(1..1 + *reason_len as usize).ok_or(EscrowError::InvalidInstruction)?;
                let reason = String::from_utf8(reason_bytes.to_vec()).map_err(|_| EscrowError::InvalidInstruction)?;
                EscrowInstruction::RaiseDispute { reason }
            }
            5 => {
                let release_flag = rest.get(0).ok_or(EscrowError::InvalidInstruction)?;
                EscrowInstruction::ResolveDispute { release_to_freelancer: *release_flag != 0 }
            }
            _ => return Err(EscrowError::InvalidInstruction.into()),
        })
    }
}