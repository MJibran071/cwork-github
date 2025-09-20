export enum UserRole {
  CLIENT = 'client',
  DEVELOPER = 'developer',
  ADMIN = 'admin',
}

export enum KYCStatus {
  PENDING = 'pending',
  VERIFIED = 'verified',
  REJECTED = 'rejected',
}

export interface JwtPayload {
  sub: string;
  email: string;
  role: UserRole;
  walletAddress?: string;
}

export interface Web3LoginDto {
  address: string;
  signature: string;
  nonce: string;
}

export interface AuthResponse {
  accessToken: string;
  refreshToken: string;
  user: {
    id: string;
    email: string;
    role: UserRole;
    walletAddress?: string;
    kycStatus: KYCStatus;
  };
}

export enum EscrowStatus {
  PENDING = 'pending',
  DEPOSITED = 'deposited',
  RELEASED = 'released',
  REFUNDED = 'refunded',
  DISPUTED = 'disputed',
}

export enum TokenType {
  ETH = 'eth',
  USDT = 'usdt',
  USDC = 'usdc',
  DAI = 'dai',
  OTHER = 'other',
}
