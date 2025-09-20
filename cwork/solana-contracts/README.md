
# CWork Solana Escrow Program

A secure Solana-based escrow program for freelance payments with built-in dispute resolution and fee system.

## Features

- **Multi-token Support**: Supports SOL, USDT, USDC, and other SPL tokens
- **Fee System**: 5% platform fee on successful transactions
- **Dispute Resolution**: Built-in dispute handling with admin oversight
- **Access Control**: Comprehensive authorization checks for all operations
- **Minimum Deposits**: Configurable minimum deposit amounts for different tokens

## Program Instructions

### 1. InitializeConfig
Initializes the program configuration with admin and treasury settings.

**Accounts:**
- `admin` (signer, writable) - The admin account
- `config_account` (writable) - The configuration account to initialize
- `treasury_wallet` (readonly) - The treasury wallet for fee collection

### 2. CreateEscrow
Creates a new escrow agreement between client and freelancer.

**Accounts:**
- `client` (signer, writable) - The client creating the escrow
- `escrow_account` (writable) - The escrow state account
- `freelancer` (readonly) - The freelancer's wallet address
- `client_token_account` (writable) - Client's token account (for SPL tokens) or client SOL account
- `escrow_token_account` (writable) - Escrow's token account (for SPL tokens) or escrow SOL account
- `token_mint` (readonly) - Token mint address (None for SOL)
- `token_program` (readonly) - SPL Token program ID
- `system_program` (readonly) - System program ID

**Data:**
- `amount: u64` - The amount to escrow
- `token_mint: Option<Pubkey>` - Optional token mint address

### 3. ReleaseFunds
Releases escrowed funds to the freelancer and pays platform fee.

**Accounts:**
- `client` (signer, writable) - The client releasing funds (must match escrow client)
- `escrow_account` (writable) - The escrow state account
- `freelancer` (writable) - Freelancer's wallet to receive funds
- `treasury_wallet` (writable) - Treasury wallet for fee collection
- `escrow_token_account` (writable) - Escrow's token account
- `token_program` (readonly) - SPL Token program ID
- `system_program` (readonly) - System program ID

### 4. CancelEscrow
Cancels an escrow and returns funds to the client.

**Accounts:**
- `client` (signer, writable) - The client canceling escrow (must match escrow client)
- `escrow_account` (writable) - The escrow state account
- `client_token_account` (writable) - Client's token account to receive refund
- `escrow_token_account` (writable) - Escrow's token account
- `token_program` (readonly) - SPL Token program ID
- `system_program` (readonly) - System program ID

### 5. RaiseDispute
Raises a dispute on an escrow agreement.

**Accounts:**
- `raiser` (signer, writable) - The party raising the dispute (client or freelancer)
- `escrow_account` (writable) - The escrow state account

### 6. ResolveDispute
Resolves a dispute and releases funds accordingly (admin only).

**Accounts:**
- `admin` (signer, writable) - The admin account (must match config admin)
- `config_account` (readonly) - The configuration account
- `escrow_account` (writable) - The escrow state account
- `freelancer` (writable) - Freelancer's wallet to receive funds
- `treasury_wallet` (writable) - Treasury wallet for fee collection
- `escrow_token_account` (writable) - Escrow's token account
- `token_program` (readonly) - SPL Token program ID
- `system_program` (readonly) - System program ID

## Minimum Deposit Requirements

- **SOL**: 0.05 SOL (50,000,000 lamports)
- **USDT**: 10 USDT (10,000,000 tokens)
- **USDC**: 10 USDC (10,000,000 tokens)

## Deployment

### Prerequisites

1. Install Solana CLI: `sh -c "$(curl -sSfL https://release.solana.com/v1.18.0/install)"`
2. Install Rust: `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh`
3. Install cargo-build-bpf: `cargo install cargo-build-bpf`

### Building the Program

```bash
cd cwork/solana-contracts
cargo build-bpf --manifest-path programs/escrow-program/Cargo.toml
```

### Deploying to Networks

Use the deployment script:

```bash
# Deploy to devnet (default)
./scripts/deploy.sh

# Deploy to testnet
./scripts/deploy.sh testnet

# Deploy to mainnet-beta
./scripts/deploy.sh mainnet-beta

# Use custom keypair
./scripts/deploy.sh devnet /path/to/keypair.json
```

### Manual Deployment

```bash
# Set network
solana config set --url https://api.devnet.solana.com

# Build program
cargo build-bpf --manifest-path programs/escrow-program/Cargo.toml --bpf-out-dir dist/program

# Deploy program
solana program deploy dist/program/escrow-program.so
```

## Testing

Run the integration tests:

```bash
cd cwork/solana-contracts
cargo test --test integration_test
```

## Program ID

After deployment, the program ID will be displayed and saved to a deployment info file. Use this ID when interacting with the program.

## Client Integration

To interact with the program from a client application, use the `@solana/web3.js` library and the program IDL (Interface Definition Language) generated from the Rust code.

Example client code:

```javascript
import