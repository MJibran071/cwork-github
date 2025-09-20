#!/bin/bash

# Cwork Smart Contracts Deployment Script
# This script deploys smart contracts to a specified network

set -e  # Exit on error

echo "🚀 Starting Cwork Smart Contracts Deployment..."

# Check if Hardhat is available
if ! command -v npx hardhat &> /dev/null; then
    echo "❌ Hardhat not found. Please install dependencies: cd contracts && npm install"
    exit 1
fi

# Set network (default to localhost)
NETWORK=${1:-"localhost"}

echo "📦 Deploying contracts to network: $NETWORK"

# Deploy contracts
cd contracts
npx hardhat run scripts/deploy.js --network $NETWORK

echo "✅ Smart contracts deployed successfully to $NETWORK!"
echo ""
echo "📋 Contract addresses:"
echo "   - Check the console output above for deployed contract addresses"
echo "   - Update your .env files with the correct contract addresses"