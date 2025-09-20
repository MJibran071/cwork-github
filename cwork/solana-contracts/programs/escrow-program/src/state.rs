use borsh::{BorshDeserialize, BorshSerialize};
use solana_program::pubkey::Pubkey;

// Constants for fee calculation (5% service fee)
pub const FEE_BASIS_POINTS: u64 = 500; // 5% = 500 basis points
pub const BASIS_POINTS_DIVISOR: u64 = 10000;

// Minimum deposit amounts (in lamports for SOL, in tokens for SPL tokens)
pub const MIN_DEPOSIT_SOL: u64 = 50_000_000; // 0.05 SOL
pub const MIN_DEPOSIT_USDT: u64 = 10_000_000; // 10 USDT (6 decimals)
pub const MIN_DEPOSIT_USDC: u64 = 10_000_000; // 10 USDC (6 decimals)

// Escrow status enum
#[derive(BorshSerialize, BorshDeserialize, Debug, PartialEq, Clone, Copy)]
pub enum EscrowStatus {
    Created,
    Funded,
    Released,
    Cancelled,
    Disputed,
    Resolved,
}

#[derive(BorshSerialize, BorshDeserialize, Debug)]
pub struct EscrowState {
    pub client: Pubkey,
    pub freelancer: Pubkey,
    pub amount: u64,
    pub token_mint: Option<Pubkey>, // None for SOL, Some for SPL tokens
    pub status: EscrowStatus,
    pub fee_paid: bool,
    pub dispute_raised_by: Option<Pubkey>,
    pub dispute_reason: Option<String>,
}

#[derive(BorshSerialize, BorshDeserialize, Debug)]
pub struct EscrowConfig {
    pub admin: Pubkey,
    pub treasury_wallet: Pubkey,
    pub min_deposit_sol: u64,
    pub min_deposit_usdt: u64,
    pub min_deposit_usdc: u64,
    pub fee_basis_points: u64,
    pub basis_points_divisor: u64,
}

impl EscrowConfig {
    pub fn new(admin: Pubkey, treasury_wallet: Pubkey) -> Self {
        Self {
            admin,
            treasury_wallet,
            min_deposit_sol: MIN_DEPOSIT_SOL,
            min_deposit_usdt: MIN_DEPOSIT_USDT,
            min_deposit_usdc: MIN_DEPOSIT_USDC,
            fee_basis_points: FEE_BASIS_POINTS,
            basis_points_divisor: BASIS_POINTS_DIVISOR,
        }
    }
}

impl EscrowState {
    pub fn new(client: Pubkey, freelancer: Pubkey, amount: u64, token_mint: Option<Pubkey>) -> Self {
        Self {
            client,
            freelancer,
            amount,
            token_mint,
            status: EscrowStatus::Created,
            fee_paid: false,
            dispute_raised_by: None,
            dispute_reason: None,
        }
    }

    pub fn mark_funded(&mut self) {
        self.status = EscrowStatus::Funded;
    }

    pub fn mark_released(&mut self) {
        self.status = EscrowStatus::Released;
        self.fee_paid = true;
    }

    pub fn mark_cancelled(&mut self) {
        self.status = EscrowStatus::Cancelled;
    }

    pub fn mark_disputed(&mut self, raised_by: Pubkey, reason: String) {
        self.status = EscrowStatus::Disputed;
        self.dispute_raised_by = Some(raised_by);
        self.dispute_reason = Some(reason);
    }

    pub fn mark_resolved(&mut self) {
        self.status = EscrowStatus::Resolved;
    }

    pub fn is_released(&self) -> bool {
        matches!(self.status, EscrowStatus::Released | EscrowStatus::Resolved)
    }

    pub fn is_disputed(&self) -> bool {
        self.status == EscrowStatus::Disputed
    }

    pub fn can_be_released(&self) -> bool {
        matches!(self.status, EscrowStatus::Funded | EscrowStatus::Disputed)
    }

    pub fn can_be_cancelled(&self) -> bool {
        matches!(self.status, EscrowStatus::Created | EscrowStatus::Funded)
    }
}