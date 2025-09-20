import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from './user.entity';
import { UserRole, KYCStatus } from '../types';
import * as bcrypt from 'bcrypt';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private usersRepository: Repository<User>,
  ) {}

  async createUser(createUserDto: {
    email: string;
    password?: string;
    name?: string;
    firstName?: string;
    lastName?: string;
    phone?: string;
    walletAddress?: string;
    role?: UserRole;
  }): Promise<User> {
    const user = new User();
    user.email = createUserDto.email;
    user.name = createUserDto.name;
    user.firstName = createUserDto.firstName;
    user.lastName = createUserDto.lastName;
    user.phone = createUserDto.phone;
    user.walletAddress = createUserDto.walletAddress;
    user.role = createUserDto.role || UserRole.CLIENT;
    user.kycStatus = KYCStatus.PENDING;
    user.emailVerified = false;
    user.phoneVerified = false;

    if (createUserDto.password) {
      this.validatePasswordStrength(createUserDto.password);
      user.password = await bcrypt.hash(createUserDto.password, 10);
      user.passwordHistory = [user.password];
      user.passwordExpiresAt = new Date(Date.now() + 90 * 24 * 60 * 60 * 1000); // 90 days from now
    }

    return this.usersRepository.save(user);
  }

  async findUserByEmail(email: string): Promise<User | null> {
    return this.usersRepository.findOne({ where: { email } });
  }

  async findUserByWalletAddress(walletAddress: string): Promise<User | null> {
    return this.usersRepository.findOne({ where: { walletAddress } });
  }

  async findUserById(id: string): Promise<User | null> {
    return this.usersRepository.findOne({ where: { id } });
  }

  async validatePassword(user: User, password: string, ipAddress?: string): Promise<boolean> {
    if (!user.password) return false;

    // Check if account is locked
    if (user.accountLockedUntil && user.accountLockedUntil > new Date()) {
      throw new BadRequestException('Account is temporarily locked. Please try again later.');
    }

    // Check password expiration
    if (user.passwordExpiresAt && user.passwordExpiresAt < new Date()) {
      throw new BadRequestException('Password has expired. Please reset your password.');
    }

    const isValid = await bcrypt.compare(password, user.password);

    if (!isValid) {
      await this.handleFailedLogin(user, ipAddress);
      return false;
    }

    // Reset failed attempts on successful login
    user.failedLoginAttempts = 0;
    user.lastFailedLoginAt = null;
    user.accountLockedUntil = null;

    // Track login IP
    if (ipAddress) {
      await this.trackLoginIP(user, ipAddress);
    }

    await this.usersRepository.save(user);
    return true;
  }

  async generateNonceForUser(email: string): Promise<string> {
    const user = await this.findUserByEmail(email);
    if (!user) {
      throw new NotFoundException('User not found');
    }

    const nonce =
      Math.random().toString(36).substring(2, 15) + Math.random().toString(36).substring(2, 15);

    user.nonce = nonce;
    await this.usersRepository.save(user);

    return nonce;
  }

  async updateUser(id: string, updateData: Partial<User>): Promise<User> {
    const result = await this.usersRepository.update(id, updateData);
    if (result.affected === 0) {
      throw new NotFoundException('User not found');
    }
    const user = await this.findUserById(id);
    if (!user) {
      throw new NotFoundException('User not found');
    }
    return user;
  }

  async verifyEmail(id: string): Promise<User> {
    return this.updateUser(id, { emailVerified: true });
  }

  async verifyPhone(id: string): Promise<User> {
    return this.updateUser(id, { phoneVerified: true });
  }

  async updateKYCStatus(id: string, status: KYCStatus): Promise<User> {
    return this.updateUser(id, { kycStatus: status });
  }

  async updateRefreshToken(id: string, refreshToken: string): Promise<User> {
    return this.updateUser(id, { refreshToken });
  }

  async updatePassword(userId: string, newPassword: string): Promise<User> {
    const user = await this.findUserById(userId);
    if (!user) {
      throw new NotFoundException('User not found');
    }

    this.validatePasswordStrength(newPassword);
    await this.checkPasswordHistory(user, newPassword);

    const hashedPassword = await bcrypt.hash(newPassword, 10);

    // Update password history (keep last 5)
    const newHistory = user.passwordHistory || [];
    newHistory.push(hashedPassword);
    if (newHistory.length > 5) {
      newHistory.shift();
    }

    return this.updateUser(userId, {
      password: hashedPassword,
      passwordHistory: newHistory,
      passwordExpiresAt: new Date(Date.now() + 90 * 24 * 60 * 60 * 1000), // Reset expiration
      failedLoginAttempts: 0, // Reset failed attempts
      accountLockedUntil: null,
    });
  }

  private validatePasswordStrength(password: string): void {
    if (password.length < 12) {
      throw new BadRequestException('Password must be at least 12 characters long');
    }

    const hasUpperCase = /[A-Z]/.test(password);
    const hasLowerCase = /[a-z]/.test(password);
    const hasNumbers = /\d/.test(password);
    const hasSpecialChar = /[!@#$%^&*(),.?":{}|<>]/.test(password);

    if (!hasUpperCase || !hasLowerCase || !hasNumbers || !hasSpecialChar) {
      throw new BadRequestException(
        'Password must contain uppercase, lowercase, numbers, and special characters',
      );
    }
  }

  private async checkPasswordHistory(user: User, newPassword: string): Promise<void> {
    if (!user.passwordHistory) return;

    for (const oldHash of user.passwordHistory) {
      if (await bcrypt.compare(newPassword, oldHash)) {
        throw new BadRequestException('Cannot reuse previous passwords');
      }
    }
  }

  private async handleFailedLogin(user: User, ipAddress?: string): Promise<void> {
    // Create a copy to avoid direct mutation before save
    const updatedUser = { ...user };
    updatedUser.failedLoginAttempts += 1;
    updatedUser.lastFailedLoginAt = new Date();

    if (updatedUser.failedLoginAttempts >= 5) {
      updatedUser.accountLockedUntil = new Date(Date.now() + 15 * 60 * 1000); // 15 minutes lockout
    }

    // Track failed login IP
    if (ipAddress) {
      await this.trackFailedLoginIP(updatedUser, ipAddress);
    }

    // Update only the necessary fields
    await this.usersRepository.update(updatedUser.id, {
      failedLoginAttempts: updatedUser.failedLoginAttempts,
      lastFailedLoginAt: updatedUser.lastFailedLoginAt,
      accountLockedUntil: updatedUser.accountLockedUntil,
    });
  }

  private async trackLoginIP(user: User, ipAddress: string): Promise<void> {
    const loginIPs = user.loginIPs || [];
    if (!loginIPs.includes(ipAddress)) {
      loginIPs.push(ipAddress);
      await this.usersRepository.update(user.id, { loginIPs });
    }
  }

  private async trackFailedLoginIP(user: User, ipAddress: string): Promise<void> {
    // Implement IP-based tracking for failed logins
    // This could be extended to flag suspicious IPs
    console.log(`Failed login attempt from IP: ${ipAddress} for user: ${user.email}`);
  }

  async getLoginStats(userId: string): Promise<{
    failedAttempts: number;
    lastFailedLogin: Date | null;
    accountLockedUntil: Date | null;
    knownIPs: string[];
  }> {
    const user = await this.findUserById(userId);
    if (!user) {
      throw new NotFoundException('User not found');
    }

    return {
      failedAttempts: user.failedLoginAttempts,
      lastFailedLogin: user.lastFailedLoginAt,
      accountLockedUntil: user.accountLockedUntil,
      knownIPs: user.loginIPs || [],
    };
  }
}
