import { Controller, Post, Body, Get, Param, UseGuards } from '@nestjs/common';
import { EscrowService } from './escrow.service';
import { CreateEscrowDto, AddMilestoneDto, EscrowActionDto } from '../blockchain/dto/blockchain.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('escrow')
@UseGuards(JwtAuthGuard)
export class EscrowController {
  constructor(private readonly escrowService: EscrowService) {}

  @Post('create')
  async createEscrow(@Body() createEscrowDto: CreateEscrowDto & { projectId: string }) {
    const { projectId, ...escrowData } = createEscrowDto;
    const escrow = await this.escrowService.createEscrow(escrowData, projectId);
    return { success: true, escrow };
  }

  @Post('add-milestone')
  async addMilestone(@Body() addMilestoneDto: AddMilestoneDto) {
    const escrow = await this.escrowService.addMilestone(addMilestoneDto);
    return { success: true, escrow };
  }

  @Post('deposit')
  async deposit(@Body() escrowActionDto: EscrowActionDto) {
    const escrow = await this.escrowService.deposit(escrowActionDto);
    return { success: true, escrow };
  }

  @Post('release')
  async release(@Body() escrowActionDto: EscrowActionDto) {
    const escrow = await this.escrowService.release(escrowActionDto);
    return { success: true, escrow };
  }

  @Post('raise-dispute')
  async raiseDispute(@Body() escrowActionDto: EscrowActionDto) {
    const escrow = await this.escrowService.raiseDispute(escrowActionDto);
    return { success: true, escrow };
  }

  @Post('admin/resolve-release')
  async adminResolveRelease(@Body() escrowActionDto: EscrowActionDto) {
    const escrow = await this.escrowService.adminResolveRelease(escrowActionDto);
    return { success: true, escrow };
  }

  @Post('admin/resolve-refund')
  async adminResolveRefund(@Body() escrowActionDto: EscrowActionDto) {
    const escrow = await this.escrowService.adminResolveRefund(escrowActionDto);
    return { success: true, escrow };
  }

  @Get(':escrowId')
  async getEscrow(@Param('escrowId') escrowId: string) {
    const escrow = await this.escrowService.getEscrowById(escrowId);
    return { escrow };
  }

  @Get('project/:projectId')
  async getEscrowByProject(@Param('projectId') projectId: string) {
    const escrow = await this.escrowService.getEscrowByProject(projectId);
    return { escrow };
  }

  @Get()
  async getAllEscrows() {
    const escrows = await this.escrowService.getAllEscrows();
    return { escrows };
  }
}