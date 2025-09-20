import { Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { UsersService } from '../users/users.service';
import { Web3Service } from '../web3/web3.service';
import { OAuth2Client } from 'google-auth-library';
import { UserRole, JwtPayload, Web3LoginDto, AuthResponse } from '../types';
import * as bcrypt from 'bcrypt';
import { LoggingService } from '../logging/logging.service';
import { AlertsService } from '../alerts/alerts.service';

@Injectable()
export class AuthService {
  constructor(
    private usersService: UsersService,
    private jwtService: JwtService,
    private web3Service: Web3Service,
    private loggingService: LoggingService,
    private alertsService: AlertsService,
  ) {}

  async validateUser(email: string, password: string, ipAddress?: string): Promise<any> {
    const user = await this.usersService.findUserByEmail(email);
    if (user && (await this.usersService.validatePassword(user, password, ipAddress))) {
      const { password: _, ...result } = user;
      return result;
    }
    return null;
  }

  async login(
    email: string,
    password: string,
    ipAddress: string,
    userAgent: string,
  ): Promise<AuthResponse> {
    this.loggingService.info('Login attempt', 'AuthService', { email, ipAddress });
    const user = await this.validateUser(email, password, ipAddress);
    if (!user) {
      this.loggingService.warn('Login failed: invalid credentials', 'AuthService', {
        email,
        ipAddress,
      });
      // Send alert for failed login attempt with IP and user agent
      await this.alertsService.failedLoginAttempt(email, ipAddress, userAgent);

      throw new UnauthorizedException('Invalid credentials');
    }

    this.loggingService.info('Login successful', 'AuthService', {
      userId: user.id,
      email: user.email,
      ipAddress,
    });

    // Analyze login location for security alerts
    await this.alertsService.analyzeLoginLocation(email, ipAddress);

    // Record successful login in history
    await this.recordLoginHistory(user, {
      timestamp: new Date(),
      ipAddress,
      userAgent,
      success: true,
      method: 'email',
    });

    return this.generateTokens(user);
  }

  async web3Login(web3LoginDto: Web3LoginDto): Promise<AuthResponse> {
    const { address, signature, nonce } = web3LoginDto;
    this.loggingService.info('Web3 login attempt', 'AuthService', { address });

    // Verify the signature
    const isValid = await this.web3Service.verifySignature({ address, signature, nonce });
    if (!isValid) {
      this.loggingService.warn('Web3 login failed: invalid signature', 'AuthService', { address });
      // Send alert for failed Web3 login attempt
      await this.alertsService.failedLoginAttempt(address, 'unknown', 'Web3 login');
      throw new UnauthorizedException('Invalid signature');
    }

    // Find or create user
    let user = await this.usersService.findUserByWalletAddress(address);
    if (!user) {
      this.loggingService.info('Creating new user for Web3 login', 'AuthService', { address });
      user = await this.usersService.createUser({
        email: `${address}@cwork.io`, // Temporary email
        walletAddress: address,
        role: UserRole.CLIENT,
      });
    }

    // Verify nonce matches
    if (user.nonce !== nonce) {
      this.loggingService.warn('Web3 login failed: invalid nonce', 'AuthService', {
        address,
        expectedNonce: user.nonce,
        receivedNonce: nonce,
      });
      // Send alert for invalid nonce attempt
      await this.alertsService.failedLoginAttempt(address, 'unknown', 'Web3 login');
      throw new UnauthorizedException('Invalid nonce');
    }

    this.loggingService.info('Web3 login successful', 'AuthService', { userId: user.id, address });
    return this.generateTokens(user);
  }

  async register(registerDto: {
    email: string;
    password: string;
    name?: string;
    phone?: string;
    role?: UserRole;
  }): Promise<AuthResponse> {
    this.loggingService.info('Registration attempt', 'AuthService', { email: registerDto.email });
    const existingUser = await this.usersService.findUserByEmail(registerDto.email);
    if (existingUser) {
      this.loggingService.warn('Registration failed: user already exists', 'AuthService', {
        email: registerDto.email,
      });
      // Send alert for duplicate registration attempt
      await this.alertsService.securityAlert(
        'Duplicate registration attempt',
        'medium',
        { email: registerDto.email },
        'registration',
      );
      throw new UnauthorizedException('User already exists');
    }

    const user = await this.usersService.createUser(registerDto);
    this.loggingService.info('Registration successful', 'AuthService', {
      userId: user.id,
      email: user.email,
    });
    return this.generateTokens(user);
  }

  async refreshToken(refreshToken: string): Promise<AuthResponse> {
    this.loggingService.info('Refresh token attempt', 'AuthService');
    try {
      const payload = this.jwtService.verify(refreshToken, {
        secret: process.env.JWT_REFRESH_SECRET || 'refresh-secret',
      });

      const user = await this.usersService.findUserById(payload.sub);
      if (!user || user.refreshToken !== refreshToken) {
        this.loggingService.warn('Refresh token failed: invalid token', 'AuthService', {
          userId: payload.sub,
        });
        // Send alert for invalid refresh token attempt
        await this.alertsService.securityAlert(
          'Invalid refresh token attempt',
          'high',
          { userId: payload.sub },
          'authentication',
        );
        throw new UnauthorizedException('Invalid refresh token');
      }

      this.loggingService.info('Refresh token successful', 'AuthService', { userId: user.id });
      return this.generateTokens(user);
    } catch (error) {
      this.loggingService.warn('Refresh token failed: verification error', 'AuthService', {
        error: error.message,
      });
      // Send alert for refresh token verification error
      await this.alertsService.securityAlert(
        'Refresh token verification failed',
        'high',
        { error: error.message },
        'authentication',
      );
      throw new UnauthorizedException('Invalid refresh token');
    }
  }

  private async generateTokens(user: any): Promise<AuthResponse> {
    const payload: JwtPayload = {
      sub: user.id,
      email: user.email,
      role: user.role,
      walletAddress: user.walletAddress,
    };

    const accessToken = this.jwtService.sign(payload);
    const refreshToken = this.jwtService.sign(payload, {
      expiresIn: '7d',
      secret: process.env.JWT_REFRESH_SECRET || 'refresh-secret',
    });

    // Save refresh token to user
    await this.usersService.updateRefreshToken(user.id, refreshToken);

    this.loggingService.info('Tokens generated', 'AuthService', { userId: user.id });

    return {
      accessToken,
      refreshToken,
      user: {
        id: user.id,
        email: user.email,
        role: user.role,
        walletAddress: user.walletAddress,
        kycStatus: user.kycStatus,
      },
    };
  }

  async logout(userId: string): Promise<void> {
    this.loggingService.info('Logout', 'AuthService', { userId });
    await this.usersService.updateRefreshToken(userId, null);
  }

  async googleLogin(googleUser: any): Promise<AuthResponse> {
    const { email, firstName, lastName } = googleUser;
    this.loggingService.info('Google login attempt', 'AuthService', { email });

    // Find existing user by email
    let user = await this.usersService.findUserByEmail(email);

    if (!user) {
      this.loggingService.info('Creating new user for Google login', 'AuthService', { email });
      // Create new user with Google profile information
      user = await this.usersService.createUser({
        email,
        firstName: firstName || 'Google',
        lastName: lastName || 'User',
        password: await bcrypt.hash(Math.random().toString(36), 10), // Random password for Google users
        role: UserRole.CLIENT,
      });
    }

    this.loggingService.info('Google login successful', 'AuthService', { userId: user.id, email });
    return this.generateTokens(user);
  }

  async googleLoginWithIdToken(idToken: string): Promise<AuthResponse> {
    this.loggingService.info('Google login with ID token attempt', 'AuthService');
    const client = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

    try {
      const ticket = await client.verifyIdToken({
        idToken,
        audience: process.env.GOOGLE_CLIENT_ID,
      });

      const payload = ticket.getPayload();
      const { email, given_name: firstName, family_name: lastName } = payload;

      // Find existing user by email
      let user = await this.usersService.findUserByEmail(email);

      if (!user) {
        this.loggingService.info('Creating new user for Google ID token login', 'AuthService', {
          email,
        });
        // Create new user with Google profile information
        user = await this.usersService.createUser({
          email,
          firstName: firstName || 'Google',
          lastName: lastName || 'User',
          password: await bcrypt.hash(Math.random().toString(36), 10), // Random password for Google users
          role: UserRole.CLIENT,
        });
      }

      this.loggingService.info('Google login with ID token successful', 'AuthService', {
        userId: user.id,
        email,
      });
      return this.generateTokens(user);
    } catch (error) {
      this.loggingService.warn('Google login with ID token failed: invalid token', 'AuthService', {
        error: error.message,
      });
      // Send alert for failed Google login
      await this.alertsService.failedLoginAttempt('unknown', 'unknown', 'Google OAuth');
      throw new UnauthorizedException('Invalid Google ID token');
    }
  }

  private async recordLoginHistory(
    user: any,
    entry: {
      timestamp: Date;
      ipAddress: string;
      userAgent?: string;
      success: boolean;
      method: string;
    },
  ): Promise<void> {
    try {
      // Ensure user exists before trying to update
      if (!user || !user.id) {
        this.loggingService.warn('Cannot record login history: user not found', 'AuthService');
        return;
      }

      const loginHistory = user.loginHistory || [];
      // Keep only the last 100 login attempts
      if (loginHistory.length >= 100) {
        loginHistory.shift();
      }
      loginHistory.push(entry);

      await this.usersService.updateUser(user.id, { loginHistory });

      // Log the security event
      this.loggingService.securityEvent(`Login ${entry.success ? 'successful' : 'failed'}`, {
        userId: user.id,
        email: user.email,
        ipAddress: entry.ipAddress,
        method: entry.method,
        success: entry.success,
      });
    } catch (error) {
      this.loggingService.error('Failed to record login history', 'AuthService', {
        error: error.message,
      });
    }
  }
}
