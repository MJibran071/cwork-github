import { Controller, Post, Body, Get, Param } from '@nestjs/common';
import { BlockchainService } from './blockchain.service';
import { CreateEscrowDto, AddMilestoneDto, EscrowActionDto } from './dto/blockchain.dto';

@Controller('blockchain')
export class BlockchainController {
  constructor(private readonly blockchainService: BlockchainService) {}

  @Post('create-escrow')
  async createEscrow(@Body() createEscrowDto: CreateEscrowDto) {
    const txHash = await this.blockchainService.createEscrow(createEscrowDto);
    return { success: true, txHash };
  }

  @Post('add-milestone')
  async addMilestone(@Body() addMilestoneDto: AddMilestoneDto) {
    const txHash = await this.blockchainService.addMilestone(addMilestoneDto);
    return { success: true, txHash };
  }

  @Post('deposit')
  async deposit(@Body() escrowActionDto: EscrowActionDto) {
    const txHash = await this.blockchainService.deposit(escrowActionDto);
    return { success: true, txHash };
  }

  @Post('release')
  async release(@Body() escrowActionDto: EscrowActionDto) {
    const txHash = await this.blockchainService.release(escrowActionDto);
    return { success: true, txHash };
  }

  @Post('raise-dispute')
  async raiseDispute(@Body() escrowActionDto: EscrowActionDto) {
    const txHash = await this.blockchainService.raiseDispute(escrowActionDto);
    return { success: true, txHash };
  }

  @Post('admin-resolve-release')
  async adminResolveRelease(@Body() escrowActionDto: EscrowActionDto) {
    const txHash = await this.blockchainService.adminResolveRelease(escrowActionDto);
    return { success: true, txHash };
  }

  @Post('admin-resolve-refund')
  async adminResolveRefund(@Body() escrowActionDto: EscrowActionDto) {
    const txHash = await this.blockchainService.adminResolveRefund(escrowActionDto);
    return { success: true, txHash };
  }

  @Get('escrow/:escrowId/milestone-count')
  async getEscrowMilestoneCount(@Param('escrowId') escrowId: string) {
    const count = await this.blockchainService.getEscrowMilestoneCount(escrowId);
    return { escrowId, milestoneCount: count };
  }

  @Get('escrow/:escrowId/total-amount')
  async getEscrowTotalAmount(@Param('escrowId') escrowId: string) {
    const amount = await this.blockchainService.getEscrowTotalAmount(escrowId);
    return { escrowId, totalAmount: amount };
  }

  @Get('compute-escrow-id/:contractId')
  computeEscrowId(@Param('contractId') contractId: string) {
    const escrowId = this.blockchainService.computeEscrowId(contractId);
    return { contractId, escrowId };
  }
}