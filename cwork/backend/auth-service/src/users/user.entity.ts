import {
  Entity,
  Column,
  PrimaryGeneratedColumn,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';
import { UserRole, KYCStatus } from '../types';

@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ nullable: true, name: 'first_name' })
  firstName: string;

  @Column({ nullable: true, name: 'last_name' })
  lastName: string;

  @Column({ nullable: true })
  name: string;

  @Column({ unique: true })
  email: string;

  @Column({ nullable: true, unique: true })
  phone: string;

  @Column({ nullable: true })
  password: string;

  @Column({ nullable: true, name: 'wallet_address' })
  walletAddress: string;

  @Column({
    type: 'varchar',
    length: 20,
    default: UserRole.CLIENT,
  })
  role: UserRole;

  @Column({
    type: 'varchar',
    length: 20,
    default: KYCStatus.PENDING,
    name: 'kyc_status',
  })
  kycStatus: KYCStatus;

  @Column({ type: 'numeric', precision: 3, scale: 2, default: 0 })
  rating: number;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;

  @Column({ nullable: true, name: 'email_verified' })
  emailVerified: boolean;

  @Column({ nullable: true, name: 'phone_verified' })
  phoneVerified: boolean;

  @Column({ nullable: true, name: 'nonce' })
  nonce: string;

  @Column({ nullable: true, name: 'refresh_token' })
  refreshToken: string;

  @Column({ type: 'simple-json', nullable: true, name: 'password_history' })
  passwordHistory: string[];

  @Column({ nullable: true, name: 'password_expires_at' })
  passwordExpiresAt: Date;

  @Column({ default: 0, name: 'failed_login_attempts' })
  failedLoginAttempts: number;

  @Column({ nullable: true, name: 'last_failed_login_at' })
  lastFailedLoginAt: Date;

  @Column({ nullable: true, name: 'account_locked_until' })
  accountLockedUntil: Date;

  @Column({ type: 'simple-json', nullable: true, name: 'login_ips' })
  loginIPs: string[];

  @Column({ type: 'simple-json', nullable: true, name: 'login_history' })
  loginHistory: Array<{
    timestamp: Date;
    ipAddress: string;
    userAgent?: string;
    success: boolean;
    method: string;
  }>;
}
