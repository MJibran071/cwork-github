import { Controller, Get, Post, Body, Param, UseGuards } from '@nestjs/common';
import { UsersService } from './users.service';
import { User } from './user.entity';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get(':id')
  @UseGuards(JwtAuthGuard)
  async getUser(@Param('id') id: string): Promise<User> {
    const user = await this.usersService.findUserById(id);
    if (!user) {
      throw new Error('User not found');
    }
    return user;
  }

  @Post('nonce')
  async generateNonce(@Body() body: { email: string }): Promise<{ nonce: string }> {
    const nonce = await this.usersService.generateNonceForUser(body.email);
    return { nonce };
  }
}
