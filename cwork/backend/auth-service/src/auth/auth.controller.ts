import { Controller, Post, Body, UseGuards, Request, HttpCode, Get, Req } from '@nestjs/common';
import { AuthService } from './auth.service';
import { LocalAuthGuard } from './local-auth.guard';
import { JwtAuthGuard } from './jwt-auth.guard';
import { AuthGuard } from '@nestjs/passport';
import { Web3LoginDto, AuthResponse, UserRole } from '../types';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('login')
  @UseGuards(LocalAuthGuard)
  @HttpCode(200)
  async login(@Request() req): Promise<AuthResponse> {
    const ipAddress = req.ip || req.connection?.remoteAddress || 'unknown';
    const userAgent = req.headers['user-agent'] || 'unknown';
    return this.authService.login(req.user.email, req.body.password, ipAddress, userAgent);
  }

  @Post('web3-login')
  @HttpCode(200)
  async web3Login(@Body() web3LoginDto: Web3LoginDto): Promise<AuthResponse> {
    return this.authService.web3Login(web3LoginDto);
  }

  @Post('register')
  @HttpCode(201)
  async register(
    @Body()
    registerDto: {
      email: string;
      password: string;
      name?: string;
      phone?: string;
      role?: UserRole;
    },
  ): Promise<AuthResponse> {
    return this.authService.register(registerDto);
  }

  @Post('refresh')
  @HttpCode(200)
  async refreshToken(@Body() body: { refreshToken: string }): Promise<AuthResponse> {
    return this.authService.refreshToken(body.refreshToken);
  }

  @Post('logout')
  @UseGuards(JwtAuthGuard)
  @HttpCode(200)
  async logout(@Request() req): Promise<void> {
    return this.authService.logout(req.user.sub);
  }

  @Get('google')
  @UseGuards(AuthGuard('google'))
  async googleAuth() {
    // Initiates the Google OAuth2 login flow
  }

  @Get('google/callback')
  @UseGuards(AuthGuard('google'))
  async googleAuthRedirect(@Req() req) {
    return this.authService.googleLogin(req.user);
  }

  @Post('google/login')
  @HttpCode(200)
  async googleLogin(@Body() body: { idToken: string }): Promise<AuthResponse> {
    return this.authService.googleLoginWithIdToken(body.idToken);
  }
}
