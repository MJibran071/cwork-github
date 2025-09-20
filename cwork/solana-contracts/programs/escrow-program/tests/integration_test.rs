use solana_program_test::*;
use solana_sdk::{
    account::Account,
    signature::{Signer, Keypair},
    transaction::Transaction,
    program_error::ProgramError,
    sysvar::Sysvar,
    pubkey::Pubkey,
};
use spl_token::state::{Mint, Account as TokenAccount};
use escrow_program::{
    instruction::EscrowInstruction,
    state::{EscrowState, EscrowConfig},
};

#[tokio::test]
async fn test_initialize_config() {
    let program_id = Pubkey::new_unique();
    let mut program_test = ProgramTest::new(
        "escrow-program",
        program_id,
        processor!(escrow_program::process_instruction),
    );

    let admin = Keypair::new();
    let treasury_wallet = Keypair::new().pubkey();

    let config_account = Keypair::new();
    let config_account_size = std::mem::size_of::<EscrowConfig>();
    let config_account_lamports = Rent::default().minimum_balance(config_account_size);

    program_test.add_account(
        config_account.pubkey(),
        Account {
            lamports: config_account_lamports,
            data: vec![0; config_account_size],
            owner: program_id,
            ..Account::default()
        },
    );

    program_test.add_account(
        admin.pubkey(),
        Account {
            lamports: 1000000000,
            data: vec![],
            owner: solana_sdk::system_program::id(),
            ..Account::default()
        },
    );

    let mut context = program_test.start_with_context().await;

    let instruction_data = vec![0]; // Tag 0 for InitializeConfig

    let transaction = Transaction::new_signed_with_payer(
        &[solana_program::instruction::Instruction {
            program_id,
            accounts: vec![
                solana_sdk::instruction::AccountMeta::new(admin.pubkey(), true),
                solana_sdk::instruction::AccountMeta::new(config_account.pubkey(), false),
                solana_sdk::instruction::AccountMeta::new_readonly(treasury_wallet, false),
            ],
            data: instruction_data,
        }],
        Some(&admin.pubkey()),
        &[&admin],
        context.last_blockhash,
    );

    context
        .banks_client
        .process_transaction(transaction)
        .await
        .unwrap();

    // Verify config account data
    let config_account_data = context
        .banks_client
        .get_account(config_account.pubkey())
        .await
        .unwrap()
        .unwrap()
        .data;

    let config = EscrowConfig::try_from_slice(&config_account_data).unwrap();
    assert_eq!(config.treasury_wallet, treasury_wallet);
    assert_eq!(config.min_deposit_sol, 50000000); // 0.05 SOL
    assert_eq!(config.min_deposit_usdt, 10000000); // 10 USDT
    assert_eq!(config.min_deposit_usdc, 10000000); // 10 USDC
}

#[tokio::test]
async fn test_create_escrow_sol() {
    let program_id = Pubkey::new_unique();
    let mut program_test = ProgramTest::new(
        "escrow-program",
        program_id,
        processor!(escrow_program::process_instruction),
    );

    let client = Keypair::new();
    let freelancer = Keypair::new().pubkey();
    let escrow_account = Keypair::new();
    let escrow_account_size = std::mem::size_of::<EscrowState>();
    let escrow_account_lamports = Rent::default().minimum_balance(escrow_account_size);

    program_test.add_account(
        escrow_account.pubkey(),
        Account {
            lamports: escrow_account_lamports,
            data: vec![0; escrow_account_size],
            owner: program_id,
            ..Account::default()
        },
    );

    program_test.add_account(
        client.pubkey(),
        Account {
            lamports: 1000000000, // 1 SOL
            data: vec![],
            owner: solana_sdk::system_program::id(),
            ..Account::default()
        },
    );

    let mut context = program_test.start_with_context().await;

    let amount = 100000000; // 0.1 SOL
    let mut instruction_data = vec![1]; // Tag 1 for CreateEscrow
    instruction_data.extend_from_slice(&amount.to_le_bytes());
    // For None token_mint, we don't add anything else

    let transaction = Transaction::new_signed_with_payer(
        &[solana_program::instruction::Instruction {
            program_id,
            accounts: vec![
                solana_sdk::instruction::AccountMeta::new(client.pubkey(), true),
                solana_sdk::instruction::AccountMeta::new(escrow_account.pubkey(), false),
                solana_sdk::instruction::AccountMeta::new_readonly(freelancer, false),
                solana_sdk::instruction::AccountMeta::new(client.pubkey(), false), // client SOL account
                solana_sdk::instruction::AccountMeta::new(escrow_account.pubkey(), false), // escrow SOL account
                solana_sdk::instruction::AccountMeta::new_readonly(Pubkey::default(), false), // token mint (none)
                solana_sdk::instruction::AccountMeta::new_readonly(spl_token::id(), false), // token program
                solana_sdk::instruction::AccountMeta::new_readonly(solana_sdk::system_program::id(), false), // system program
            ],
            data: instruction_data,
        }],
        Some(&client.pubkey()),
        &[&client],
        context.last_blockhash,
    );

    context
        .banks_client
        .process_transaction(transaction)
        .await
        .unwrap();

    // Verify escrow account data
    let escrow_account_data = context
        .banks_client
        .get_account(escrow_account.pubkey())
        .await
        .unwrap()
        .unwrap()
        .data;

    let escrow_state = EscrowState::try_from_slice(&escrow_account_data).unwrap();
    assert_eq!(escrow_state.client, client.pubkey());
    assert_eq!(escrow_state.freelancer, freelancer);
    assert_eq!(escrow_state.amount, amount);
    assert!(escrow_state.token_mint.is_none());
    assert!(!escrow_state.released);
    assert!(!escrow_state.fee_paid);

    // Verify client balance decreased
    let client_account = context
        .banks_client
        .get_account(client.pubkey())
        .await
        .unwrap()
        .unwrap();
    assert!(client_account.lamports < 1000000000); // should have less than 1 SOL after transfer
}

#[tokio::test]
async fn test_minimum_deposit_validation() {
    let program_id = Pubkey::new_unique();
    let mut program_test = ProgramTest::new(
        "escrow-program",
        program_id,
        processor!(escrow_program::process_instruction),
    );

    let client = Keypair::new();
    let freelancer = Keypair::new().pubkey();
    let escrow_account = Keypair::new();
    let escrow_account_size = std::mem::size_of::<EscrowState>();
    let escrow_account_lamports = Rent::default().minimum_balance(escrow_account_size);

    program_test.add_account(
        escrow_account.pubkey(),
        Account {
            lamports: escrow_account_lamports,
            data: vec![0; escrow_account_size],
            owner: program_id,
            ..Account::default()
        },
    );

    program_test.add_account(
        client.pubkey(),
        Account {
            lamports: 1000000000,
            data: vec![],
            owner: solana_sdk::system_program::id(),
            ..Account::default()
        },
    );

    let mut context = program_test.start_with_context().await;

    let amount = 40000000; // 0.04 SOL, below minimum of 0.05 SOL
    let mut instruction_data = vec![1]; // Tag 1 for CreateEscrow
    instruction_data.extend_from_slice(&amount.to_le_bytes());
    // For None token_mint, we don't add anything else

    let transaction = Transaction::new_signed_with_payer(
        &[solana_program::instruction::Instruction {
            program_id,
            accounts: vec![
                solana_sdk::instruction::AccountMeta::new(client.pubkey(), true),
                solana_sdk::instruction::AccountMeta::new(escrow_account.pubkey(), false),
                solana_sdk::instruction::AccountMeta::new_readonly(freelancer, false),
                solana_sdk::instruction::AccountMeta::new(client.pubkey(), false),
                solana_sdk::instruction::AccountMeta::new(escrow_account.pubkey(), false),
                solana_sdk::instruction::AccountMeta::new_readonly(Pubkey::default(), false),
                solana_sdk::instruction::AccountMeta::new_readonly(spl_token::id(), false),
                solana_sdk::instruction::AccountMeta::new_readonly(solana_sdk::system_program::id(), false),
            ],
            data: instruction_data,
        }],
        Some(&client.pubkey()),
        &[&client],
        context.last_blockhash,
    );

    let result = context
        .banks_client
        .process_transaction(transaction)
        .await;

    assert!(result.is_err()); // Should fail due to insufficient deposit
}

#[tokio::test]
async fn test_release_funds_sol() {
    let program_id = Pubkey::new_unique();
    let mut program_test = ProgramTest::new(
        "escrow-program",
        program_id,
        processor!(escrow_program::process_instruction),
    );

    let client = Keypair::new();
    let freelancer = Keypair::new();
    let treasury = Keypair::new();
    let escrow_account = Keypair::new();
    let escrow_account_size = std::mem::size_of::<EscrowState>();
    let escrow_account_lamports = Rent::default().minimum_balance(escrow_account_size);

    // Pre-fund the escrow account with SOL
    let initial_escrow_balance = 100000000; // 0.1 SOL
    program_test.add_account(
        escrow_account.pubkey(),
        Account {
            lamports: escrow_account_lamports + initial_escrow_balance,
            data: vec![0; escrow_account_size],
            owner: program_id,
            ..Account::default()
        },
    );

    // Initialize escrow state
    let escrow_state = EscrowState {
        client: client.pubkey(),
        freelancer: freelancer.pubkey(),
        amount: initial_escrow_balance,
        token_mint: None,
        released: false,
        fee_paid: false,
    };
    let mut escrow_data = vec![0; escrow_account_size];
    escrow_state.serialize(&mut &mut escrow_data[..]).unwrap();

    program_test.add_account(
        escrow_account.pubkey(),
        Account {
            lamports: escrow_account_lamports + initial_escrow_balance,
            data: escrow_data,
            owner: program_id,
            ..Account::default()
        },
    );

    program_test.add_account(
        client.pubkey(),
        Account {
            lamports: 1000000000,
            data: vec![],
            owner: solana_sdk::system_program::id(),
            ..Account::default()
        },
    );

    program_test.add_account(
        freelancer.pubkey(),
        Account {
            lamports: 100000000,
            data: vec![],
            owner: solana_sdk::system_program::id(),
            ..Account::default()
        },
    );

    program_test.add_account(
        treasury.pubkey(),
        Account {
            lamports: 100000000,
            data: vec![],
            owner: solana_sdk::system_program::id(),
            ..Account::default()
        },
    );

    let mut context = program_test.start_with_context().await;

    let instruction_data = vec![2]; // Tag 2 for ReleaseFunds

    let transaction = Transaction::new_signed_with_payer(
        &[solana_program::instruction::Instruction {
            program_id,
            accounts: vec![
                solana_sdk::instruction::AccountMeta::new(client.pubkey(), true),
                solana_sdk::instruction::AccountMeta::new(escrow_account.pubkey(), false),
                solana_sdk::instruction::AccountMeta::new(freelancer.pubkey(), false),
                solana_sdk::instruction::AccountMeta::new(treasury.pubkey(), false),
                solana_sdk::instruction::AccountMeta::new(escrow_account.pubkey(), false), // escrow SOL account
                solana_sdk::instruction::AccountMeta::new_readonly(spl_token::id(), false),
                solana_sdk::instruction::AccountMeta::new_readonly(solana_sdk::system_program::id(), false),
            ],
            data: instruction_data,
        }],
        Some(&client.pubkey()),
        &[&client],
        context.last_blockhash,
    );

    context
        .banks_client
        .process_transaction(transaction)
        .await
        .unwrap();

    // Verify escrow state updated
    let escrow_account_data = context
        .banks_client
        .get_account(escrow_account.pubkey())
        .await
        .unwrap()
        .unwrap()
        .data;

    let escrow_state = EscrowState::try_from_slice(&escrow_account_data).unwrap();
    assert!(escrow_state.released);
    assert!(escrow_state.fee_paid);

    // Verify funds distributed (5% fee)
    let fee_amount = (initial_escrow_balance * 500) / 10000; // 5% fee
    let freelancer_amount = initial_escrow_balance - fee_amount;

    let freelancer_account = context
        .banks_client
        .get_account(freelancer.pubkey())
        .await
        .unwrap()
        .unwrap();
    assert!(freelancer_account.lamports > 100000000); // should have received funds

    let treasury_account = context
        .banks_client
        .get_account(treasury.pubkey())
        .await
        .unwrap()
        .unwrap();
    assert!(treasury_account.lamports > 100000000); // should have received fee
}

#[tokio::test]
async fn test_raise_dispute() {
    let program_id = Pubkey::new_unique();
    let mut program_test = ProgramTest::new(
        "escrow-program",
        program_id,
        processor!(escrow_program::process_instruction),
    );

    let client = Keypair::new();
    let freelancer = Keypair::new();
    let escrow_account = Keypair::new();
    let escrow_account_size = std::mem::size_of::<EscrowState>();
    let escrow_account_lamports = Rent::default().minimum_balance(escrow_account_size);

    // Pre-fund the escrow account with SOL
    let initial_escrow_balance = 100000000; // 0.1 SOL
    program_test.add_account(
        escrow_account.pubkey(),
        Account {
            lamports: escrow_account_lamports + initial_escrow_balance,
            data: vec![0; escrow_account_size],
            owner: program_id,
            ..Account::default()
        },
    );

    // Initialize escrow state
    let escrow_state = EscrowState {
        client: client.pubkey(),
        freelancer: freelancer.pubkey(),
        amount: initial_escrow_balance,
        token_mint: None,
        released: false,
        fee_paid: false,
    };
    let mut escrow_data = vec![0; escrow_account_size];
    escrow_state.serialize(&mut &mut escrow_data[..]).unwrap();

    program_test.add_account(
        escrow_account.pubkey(),
        Account {
            lamports: escrow_account_lamports + initial_escrow_balance,
            data: escrow_data,
            owner: program_id,
            ..Account::default()
        },
    );

    program_test.add_account(
        client.pubkey(),
        Account {
            lamports: 1000000000,
            data: vec![],
            owner: solana_sdk::system_program::id(),
            ..Account::default()
        },
    );

    program_test.add_account(
        freelancer.pubkey(),
        Account {
            lamports: 100000000,
            data: vec![],
            owner: solana_sdk::system_program::id(),
            ..Account::default()
        },
    );

    let mut context = program_test.start_with_context().await;

    let instruction_data = vec![4]; // Tag 4 for RaiseDispute

    let transaction = Transaction::new_signed_with_payer(
        &[solana_program::instruction::Instruction {
            program_id,
            accounts: vec![
                solana_sdk::instruction::AccountMeta::new(client.pubkey(), true),
                solana_sdk::instruction::AccountMeta::new(escrow_account.pubkey(), false),
            ],
            data: instruction_data,
        }],
        Some(&client.pubkey()),
        &[&client],
        context.last_blockhash,
    );

    context
        .banks_client
        .process_transaction(transaction)
        .await
        .unwrap();

    // Verify escrow state updated with dispute
    let escrow_account_data = context
        .banks_client
        .get_account(escrow_account.pubkey())
        .await
        .unwrap()
        .unwrap()
        .data;

    let escrow_state = EscrowState::try_from_slice(&escrow_account_data).unwrap();
    assert!(escrow_state.dispute_raised);
    assert_eq!(escrow_state.dispute_raiser, Some(client.pubkey()));
}

#[tokio::test]
async fn test_resolve_dispute() {
    let program_id = Pubkey::new_unique();
    let mut program_test = ProgramTest::new(
        "escrow-program",
        program_id,
        processor!(escrow_program::process_instruction),
    );

    let admin = Keypair::new();
    let client = Keypair::new();
    let freelancer = Keypair::new();
    let treasury = Keypair::new();
    let escrow_account = Keypair::new();
    let config_account = Keypair::new();
    
    let escrow_account_size = std::mem::size_of::<EscrowState>();
    let escrow_account_lamports = Rent::default().minimum_balance(escrow_account_size);
    let config_account_size = std::mem::size_of::<EscrowConfig>();
    let config_account_lamports = Rent::default().minimum_balance(config_account_size);

    // Initialize config account
    let config_state = EscrowConfig {
        treasury_wallet: treasury.pubkey(),
        min_deposit_sol: 50000000,
        min_deposit_usdt: 10000000,
        min_deposit_usdc: 10000000,
        admin: admin.pubkey(),
    };
    let mut config_data = vec![0; config_account_size];
    config_state.serialize(&mut &mut config_data[..]).unwrap();

    program_test.add_account(
        config_account.pubkey(),
        Account {
            lamports: config_account_lamports,
            data: config_data,
            owner: program_id,
            ..Account::default()
        },
    );

    // Pre-fund the escrow account with SOL and set dispute state
    let initial_escrow_balance = 100000000; // 0.1 SOL
    let escrow_state = EscrowState {
        client: client.pubkey(),
        freelancer: freelancer.pubkey(),
        amount: initial_escrow_balance,
        token_mint: None,
        released: false,
        fee_paid: false,
        dispute_raised: true,
        dispute_raiser: Some(client.pubkey()),
    };
    let mut escrow_data = vec![0; escrow_account_size];
    escrow_state.serialize(&mut &mut escrow_data[..]).unwrap();

    program_test.add_account(
        escrow_account.pubkey(),
        Account {
            lamports: escrow_account_lamports + initial_escrow_balance,
            data: escrow_data,
            owner: program_id,
            ..Account::default()
        },
    );

    program_test.add_account(
        admin.pubkey(),
        Account {
            lamports: 1000000000,
            data: vec![],
            owner: solana_sdk::system_program::id(),
            ..Account::default()
        },
    );

    program_test.add_account(
        freelancer.pubkey(),
        Account {
            lamports: 100000000,
            data: vec![],
            owner: solana_sdk::system_program::id(),
            ..Account::default()
        },
    );

    program_test.add_account(
        treasury.pubkey(),
        Account {
            lamports: 100000000,
            data: vec![],
            owner: solana_sdk::system_program::id(),
            ..Account::default()
        },
    );

    let mut context = program_test.start_with_context().await;

    let instruction_data = vec![5]; // Tag 5 for ResolveDispute

    let transaction = Transaction::new_signed_with_payer(
        &[solana_program::instruction::Instruction {
            program_id,
            accounts: vec![
                solana_sdk::instruction::AccountMeta::new(admin.pubkey(), true),
                solana_sdk::instruction::AccountMeta::new(config_account.pubkey(), false),
                solana_sdk::instruction::AccountMeta::new(escrow_account.pubkey(), false),
                solana_sdk::instruction::AccountMeta::new(freelancer.pubkey(), false),
                solana_sdk::instruction::AccountMeta::new(treasury.pubkey(), false),
                solana_sdk::instruction::AccountMeta::new(escrow_account.pubkey(), false), // escrow SOL account
                solana_sdk::instruction::AccountMeta::new_readonly(spl_token::id(), false),
                solana_sdk::instruction::AccountMeta::new_readonly(solana_sdk::system_program::id(), false),
            ],
            data: instruction_data,
        }],
        Some(&admin.pubkey()),
        &[&admin],
        context.last_blockhash,
    );

    context
        .banks_client
        .process_transaction(transaction)
        .await
        .unwrap();

    // Verify escrow state updated
    let escrow_account_data = context
        .banks_client
        .get_account(escrow_account.pubkey())
        .await
        .unwrap()
        .unwrap()
        .data;

    let escrow_state = EscrowState::try_from_slice(&escrow_account_data).unwrap();
    assert!(escrow_state.released);
    assert!(escrow_state.fee_paid);
    assert!(!escrow_state.dispute_raised); // dispute should be resolved

    // Verify funds distributed
    let freelancer_account = context
        .banks_client
        .get_account(freelancer.pubkey())
        .await
        .unwrap()
        .unwrap();
    assert!(freelancer_account.lamports > 100000000); // should have received funds

    let treasury_account = context
        .banks_client
        .get_account(treasury.pubkey())
        .await
        .unwrap()
        .unwrap();
    assert!(treasury_account.lamports > 100000000); // should have received fee
}

#[tokio::test]
async fn test_unauthorized_access_control() {
    let program_id = Pubkey::new_unique();
    let mut program_test = ProgramTest::new(
        "escrow-program",
        program_id,
        processor!(escrow_program::process_instruction),
    );

    let client = Keypair::new();
    let unauthorized_user = Keypair::new();
    let freelancer = Keypair::new();
    let escrow_account = Keypair::new();
    let escrow_account_size = std::mem::size_of::<EscrowState>();
    let escrow_account_lamports = Rent::default().minimum_balance(escrow_account_size);

    // Pre-fund the escrow account with SOL
    let initial_escrow_balance = 100000000; // 0.1 SOL
    program_test.add_account(
        escrow_account.pubkey(),
        Account {
            lamports: escrow_account_lamports + initial_escrow_balance,
            data: vec![0; escrow_account_size],
            owner: program_id,
            ..Account::default()
        },
    );

    // Initialize escrow state
    let escrow_state = EscrowState {
        client: client.pubkey(),
        freelancer: freelancer.pubkey(),
        amount: initial_escrow_balance,
        token_mint: None,
        released: false,
        fee_paid: false,
    };
    let mut escrow_data = vec![0; escrow_account_size];
    escrow_state.serialize(&mut &mut escrow_data[..]).unwrap();

    program_test.add_account(
        escrow_account.pubkey(),
        Account {
            lamports: escrow_account_lamports + initial_escrow_balance,
            data: escrow_data,
            owner: program_id,
            ..Account::default()
        },
    );

    program_test.add_account(
        client.pubkey(),
        Account {
            lamports: 1000000000,
            data: vec![],
            owner: solana_sdk::system_program::id(),
            ..Account::default()
        },
    );

    program_test.add_account(
        unauthorized_user.pubkey(),
        Account {
            lamports: 1000000000,
            data: vec![],
            owner: solana_sdk::system_program::id(),
            ..Account::default()
        },
    );

    program_test.add_account(
        freelancer.pubkey(),
        Account {
            lamports: 100000000,
            data: vec![],
            owner: solana_sdk::system_program::id(),
            ..Account::default()
        },
    );

    let mut context = program_test.start_with_context().await;

    let instruction_data = vec![2]; // Tag 2 for ReleaseFunds

    let transaction = Transaction::new_signed_with_payer(
        &[solana_program::instruction::Instruction {
            program_id,
            accounts: vec![
                solana_sdk::instruction::AccountMeta::new(unauthorized_user.pubkey(), true),
                solana_sdk::instruction::AccountMeta::new(escrow_account.pubkey(), false),
                solana_sdk::instruction::AccountMeta::new(freelancer.pubkey(), false),
                solana_sdk::instruction::AccountMeta::new(Pubkey::default(), false), // treasury (placeholder)
                solana_sdk::instruction::AccountMeta::new(escrow_account.pubkey(), false),
                solana_sdk::instruction::AccountMeta::new_readonly(spl_token::id(), false),
                solana_sdk::instruction::AccountMeta::new_readonly(solana_sdk::system_program::id(), false),
            ],
            data: instruction_data,
        }],
        Some(&unauthorized_user.pubkey()),
        &[&unauthorized_user],
        context.last_blockhash,
    );

    let result = context
        .banks_client
        .process_transaction(transaction)
        .await;

    assert!(result.is_err()); // Should fail due to unauthorized access
}