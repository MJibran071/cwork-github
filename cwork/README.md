# Cwork - Crypto Escrow Platform

A comprehensive freelance crypto escrow platform built with blockchain technology, featuring smart contracts, backend services, and a mobile application.

## 🏗️ Architecture Overview

Cwork consists of three main components:

1. **Smart Contracts** (`contracts/`): Ethereum-based escrow system with milestone payments
2. **Backend Services** (`backend/`): NestJS API for authentication, user management, and escrow operations
3. **Mobile App** (`mobile-app/`): Flutter application with wallet connect integration

## 🚀 Quick Start

### Prerequisites

- Node.js 18+ (verified compatible with current dependencies)
- Flutter 3.13.0+ (compatible with current pubspec.yaml)
- PostgreSQL database
- Ethereum wallet (MetaMask, WalletConnect compatible)

### 1. Smart Contracts Setup

```bash
cd contracts
npm install
# Verify all dependencies are installed correctly
npm run compile
npm test
```

### 2. Backend Setup

```bash
cd backend/auth-service
npm install
# Note: @nestjs/axios dependency has been added for HTTP requests

# Set up environment variables
cp .env.example .env
# Edit .env with your database and JWT settings

npm run start:dev
```

### 3. Mobile App Setup

```bash
cd mobile-app
flutter pub get

# Set up environment variables
cp .env.example .env
# Edit .env with your API endpoint and Infura settings

flutter run
```

## 📁 Project Structure

```
cwork/
├── contracts/                 # Hardhat smart contracts
│   ├── contracts/            # Solidity contracts
│   ├── test/                 # Contract tests
│   ├── scripts/              # Deployment scripts
│   └── hardhat.config.js      # Hardhat configuration
├── backend/                  # NestJS backend services
│   └── auth-service/         # Authentication service
│       ├── src/
│       │   ├── auth/         # Authentication module
│       │   ├── users/        # User management
│       │   ├── web3/         # Web3 integration
│       │   └── types/        # Type definitions
│       └── package.json
├── mobile-app/               # Flutter mobile application
│   ├── lib/
│   │   ├── screens/          # App screens
│   │   ├── services/         # API and wallet services
│   │   ├── providers/        # State management
│   │   └── main.dart         # App entry point
│   └── pubspec.yaml
└── .github/workflows/        # CI/CD pipelines
```

## 🔧 Key Features

### Smart Contracts
- **FreelanceEscrow.sol**: Main escrow contract with milestone management
- **MockERC20.sol**: Test ERC20 token for development
- Multi-signature escrow releases
- Dispute resolution mechanism
- Time-based milestone completion

### Backend Services
- JWT-based authentication
- Web3 wallet integration
- User role management (Client/Developer/Admin)
- PostgreSQL database integration
- RESTful API endpoints

### Mobile App
- WalletConnect integration
- Ethereum wallet management
- Real-time escrow monitoring
- Push notifications
- Cross-platform support (iOS/Android)

## 🛠️ Development

### Running Tests

**Smart Contracts:**
```bash
cd contracts
npm test
npm run coverage
```

**Backend:**
```bash
cd backend/auth-service
npm test
```

**Mobile App:**
```bash
cd mobile-app
flutter test
```

### Environment Variables

Create `.env` files in each component directory:

**Backend (.env):**
```
DATABASE_URL=postgres://user:pass@localhost:5432/cwork
JWT_SECRET=your-jwt-secret
PORT=3000
```

**Mobile App (.env):**
```
API_BASE_URL=http://localhost:3000
INFURA_PROJECT_ID=your-infura-project-id
ETHERSCAN_API_KEY=your-etherscan-api-key
CHAIN_ID=1
```

## 📊 CI/CD Pipeline

The project includes GitHub Actions workflows for:
- Automated testing on push/pull requests
- Code coverage reporting
- Security analysis (Slither, Mythril)
- Build verification
- Formatting checks

## 🔒 Security Features

- Smart contract security audits (Slither/Mythril)
- JWT token authentication
- Wallet signature verification
- Input validation and sanitization
- Role-based access control

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For support and questions:
- Create an issue in the GitHub repository
- Join our Discord community
- Check the documentation wiki

## 🚨 Important Notes

- Always test with testnet ETH before deploying to mainnet
- Use secure environment variables in production
- Regular security audits recommended
- Keep dependencies updated for security patches
- **Security Note**: Recent dependency updates have addressed several vulnerabilities. Run `npm audit` regularly to monitor for new issues.