# Cwork Full Stack Integration Testing Guide

This guide provides instructions for testing the complete Cwork freelance crypto escrow platform, including smart contracts, backend services, and mobile frontend.

## Prerequisites

- Node.js (v18+)
- Flutter SDK (v3.0+)
- PostgreSQL database
- MetaMask or other Ethereum wallet
- Hardhat installed globally (`npm install -g hardhat`)
- NestJS CLI installed globally (`npm install -g @nestjs/cli`)

## Environment Setup

### 1. Configure Environment Variables

Copy the example environment files and update with your actual values:

```bash
# Contracts directory
cp cwork/contracts/.env.example cwork/contracts/.env

# Backend directory
cp cwork/backend/auth-service/.env.example cwork/backend/auth-service/.env
```

Update the following in `cwork/contracts/.env`:
- `PRIVATE_KEY`: Your Ethereum private key for deployment
- `BSCSCAN_API_KEY`: BscScan API key (optional)
- `ETHERSCAN_API_KEY`: Etherscan API key (optional)

Update the following in `cwork/backend/auth-service/.env`:
- `DB_*`: PostgreSQL database credentials
- `JWT_SECRET`: Strong secret for JWT tokens
- `FRONTEND_URL`: URL of your Flutter app (http://localhost:3000 for web)

### 2. Install Dependencies

```bash
# Install contract dependencies
cd cwork/contracts
npm install

# Install backend dependencies
cd ../backend/auth-service
npm install

# Install Flutter dependencies
cd ../../mobile-app
flutter pub get
```

## Smart Contract Deployment

### Local Development Network

```bash
cd cwork/contracts

# Start local Hardhat network
npx hardhat node

# In separate terminal, deploy contracts
npx hardhat run scripts/deploy.js --network localhost
```

### Test Network Deployment (BSC Testnet)

```bash
cd cwork/contracts

# Deploy to BSC Testnet
npx hardhat run scripts/deploy.js --network bscTestnet
```

After deployment, contract addresses will be saved to `frontend/contracts/` directory. Update your Flutter app configuration with these addresses.

## Backend Service Setup

### 1. Database Setup

Ensure PostgreSQL is running and create the database:

```sql
CREATE DATABASE cwork_auth;
```

### 2. Start Backend Services

```bash
cd cwork/backend/auth-service

# Development mode with auto-reload
npm run start:dev

# Or production mode
npm run build
npm run start:prod
```

The auth service will run on port 3001 by default.

## Mobile App Testing

### 1. Configure Mobile App

Update `cwork/mobile-app/.env` with your backend URL and contract addresses:

```
API_BASE_URL=http://localhost:3001
CONTRACT_ADDRESS=0xYourDeployedContractAddress
```

### 2. Run Flutter App

```bash
cd cwork/mobile-app

# For Android
flutter run -d android

# For iOS
flutter run -d ios

# For web
flutter run -d chrome
```

## Test Scenarios

### 1. User Authentication
- Register new user with email/password
- Login with web3 wallet (MetaMask/WalletConnect)
- Verify JWT token generation

### 2. Project Management
- Create new project as client
- View project list
- Submit proposal as freelancer
- Accept/reject proposals

### 3. Escrow Functionality
- Deposit funds to escrow (ETH/ERC20 tokens)
- Verify smart contract interaction
- Check balance updates
- Test release/refund flows

### 4. Real-time Messaging
- Send messages between client and freelancer
- Verify WebSocket connectivity
- Test message persistence

### 5. Profile Management
- Update user profile information
- Verify profile picture upload
- Test settings persistence

## Troubleshooting

### Common Issues

1. **Contract deployment fails**: Check private key and network configuration
2. **Database connection errors**: Verify PostgreSQL is running and credentials are correct
3. **CORS errors**: Ensure FRONTEND_URL is set correctly in backend environment
4. **Wallet connection issues**: Check WalletConnect configuration and network settings

### Logs and Debugging

- Backend logs: Check console output from NestJS service
- Contract logs: Use Hardhat console or blockchain explorers
- Mobile app logs: Use Flutter debug console or device logs

## Network Configuration

For testing on different networks, update the following:

### BSC Testnet RPC URL:
```
https://data-seed-prebsc-1-s1.binance.org:8545
```

### Ethereum Goerli Testnet RPC URL:
```
https://goerli.infura.io/v3/your-infura-key
```

Update the mobile app's WalletService to use the appropriate RPC URL for the network you're testing on.

## Verification

After successful testing, verify:

1. ✅ Contracts deployed and addresses recorded
2. ✅ Backend services running and accessible
3. ✅ Mobile app connects to backend APIs
4. ✅ Wallet integration working properly
5. ✅ Smart contract interactions successful
6. ✅ Real-time features functioning
7. ✅ All user flows working end-to-end