import { Controller, Post, Get, Body, Param, Query } from '@nestjs/common';
import { EscrowService } from './escrow.service';
import { EscrowTransaction } from './escrow.entity';
import { EscrowStatus, TokenType } from '../types';

@Controller('escrow')
export class EscrowController {
  constructor(private readonly escrowService: EscrowService) {}

  @Post('transaction')
  async createTransaction(
    @Body()
    body: {
      escrowId: string;
      projectId: string;
      milestoneIndex: number;
      clientId: string;
      developerId: string;
      amount: number;
      feeAmount: number;
      token: TokenType;
      tokenAddress?: string;
    },
  ): Promise<EscrowTransaction> {
    return this.escrowService.createTransaction(body);
  }

  @Post('transaction/:id/status')
  async updateTransactionStatus(
    @Param('id') id: string,
    @Body() body: { status: EscrowStatus; transactionHash?: string },
  ): Promise<EscrowTransaction> {
    return this.escrowService.updateTransactionStatus(id, body.status, body.transactionHash);
  }

  @Post('transaction/:id/dispute')
  async markAsDisputed(
    @Param('id') id: string,
    @Body() body: { reason: string },
  ): Promise<EscrowTransaction> {
    return this.escrowService.markAsDisputed(id, body.reason);
  }

  @Get('transaction/:id')
  async getTransaction(@Param('id') id: string): Promise<EscrowTransaction> {
    return this.escrowService.getTransactionById(id);
  }

  @Get('project/:projectId')
  async getProjectTransactions(
    @Param('projectId') projectId: string,
  ): Promise<EscrowTransaction[]> {
    return this.escrowService.getTransactionsByProject(projectId);
  }

  @Get('user/:userId')
  async getUserTransactions(@Param('userId') userId: string): Promise<EscrowTransaction[]> {
    return this.escrowService.getTransactionsByUser(userId);
  }

  @Get('fees/stats')
  async getFeeStatistics() {
    return this.escrowService.getFeeStatistics();
  }

  @Get('minimum-deposits')
  async getMinimumDepositAmounts() {
    return this.escrowService.getMinimumDepositAmounts();
  }

  @Get('calculate-fee')
  async calculateFee(@Query('amount') amount: string) {
    const numericAmount = parseFloat(amount);
    if (isNaN(numericAmount)) {
      throw new Error('Invalid amount provided');
    }
    return this.escrowService.calculateFee(numericAmount);
  }
}
