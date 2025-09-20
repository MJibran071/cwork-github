#!/bin/bash

# Deployment script for CWork Solana Escrow Program
# Usage: ./deploy.sh [network] [keypair_path]

set -e

# Default values
NETWORK="devnet"
KEYPAIR_PATH="$HOME/.config/solana/id.json"
PROGRAM_NAME="escrow-program"
PROGRAM_DIR="programs/escrow-program"

# Parse command line arguments
if [ $# -ge 1 ]; then
    NETWORK="$1"
fi

if [ $# -ge 2 ]; then
    KEYPAIR_PATH="$2"
fi

# Validate network
case "$NETWORK" in
    "devnet"|"testnet"|"mainnet-beta")
        ;;
    *)
        echo "Error: Invalid network. Must be devnet, testnet, or mainnet-beta"
        exit 1
        ;;
esac

# Check if solana CLI is installed
if ! command -v solana &> /dev/null; then
    echo "Error: solana CLI is not installed. Please install it first."
    exit 1
fi

# Check if keypair file exists
if [ ! -f "$KEYPAIR_PATH" ]; then
    echo "Error: Keypair file not found at $KEYPAIR_PATH"
    exit 1
fi

echo "Deploying $PROGRAM_NAME to $NETWORK..."
echo "Using keypair: $KEYPAIR_PATH"

# Set Solana network
solana config set --url "https://api.$NETWORK.solana.com"

# Build the program
echo "Building program..."
cargo build-bpf --manifest-path "$PROGRAM_DIR/Cargo.toml" --bpf-out-dir dist/program

# Get the program ID
PROGRAM_ID=$(solana program id dist/program/$PROGRAM_NAME.so)

echo "Program ID: $PROGRAM_ID"

# Deploy the program
echo "Deploying program..."
solana program deploy \
    --keypair "$KEYPAIR_PATH" \
    dist/program/$PROGRAM_NAME.so

echo "Deployment completed successfully!"
echo "Program ID: $PROGRAM_ID"
echo "Network: $NETWORK"

# Save deployment info to file
DEPLOYMENT_INFO="deployment-$NETWORK-$(date +%Y%m%d-%H%M%S).txt"
echo "Program ID: $PROGRAM_ID" > "$DEPLOYMENT_INFO"
echo "Network: $NETWORK" >> "$DEPLOYMENT_INFO"
echo "Deployment Time: $(date)" >> "$DEPLOYMENT_INFO"
echo "Keypair: $KEYPAIR_PATH" >> "$DEPLOYMENT_INFO"

echo "Deployment information saved to $DEPLOYMENT_INFO"