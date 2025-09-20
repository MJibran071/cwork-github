import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Escrow } from './escrow.entity';
import { BlockchainService } from '../blockchain/blockchain.service';
import { CreateEscrowDto, AddMilestoneDto, EscrowActionDto, EscrowStatus } from '../blockchain/dto/blockchain.dto';

@Injectable()
export class EscrowService {
  constructor(
    @InjectRepository(Escrow)
    private readonly escrowRepository: Repository<Escrow>,
    private readonly blockchainService: BlockchainService,
  ) {}

  async createEscrow(createEscrowDto: CreateEscrowDto, projectId: string): Promise<Escrow> {
    const { escrowId, client, developer } = createEscrowDto;

    // Create escrow on blockchain
    const txHash = await this.blockchainService.createEscrow(createEscrowDto);

    // Save to database
    const escrow = this.escrowRepository.create({
      escrowId,
      projectId,
      clientId: client,
      developerId: developer,
      totalAmount: 0,
      feeAmount: 0,
      currency: 'ETH',
      status: EscrowStatus.NONE,
      blockchainTxHash: txHash,
    });

    return await this.escrowRepository.save(escrow);
  }

  async addMilestone(addMilestoneDto: AddMilestoneDto): Promise<Escrow> {
    const { escrowId, principalAmount, token } = addMilestoneDto;

    // Add milestone on blockchain
    const txHash = await this.blockchainService.addMilestone(addMilestoneDto);

    // Calculate fee (5%)
    const feeAmount = principalAmount * 0.05;
    const totalAmount = principalAmount + feeAmount;

    // Update database
    const escrow = await this.escrowRepository.findOne({ where: { escrowId } });
    if (!escrow) {
      throw new NotFoundException('Escrow not found');
    }

    escrow.totalAmount += totalAmount;
    escrow.feeAmount += feeAmount;
    escrow.currency = token || 'ETH';

    return await this.escrowRepository.save(escrow);
  }

  async deposit(escrowActionDto: EscrowActionDto): Promise<Escrow> {
    const { escrowId } = escrowActionDto;

    // Deposit on blockchain
    const txHash = await this.blockchainService.deposit(escrowActionDto);

    // Update database
    const escrow = await this.escrowRepository.findOne({ where: { escrowId } });
    if (!escrow) {
      throw new NotFoundException('Escrow not found');
    }

    escrow.status = EscrowStatus.DEPOSITED;
    escrow.blockchainTxHash = txHash;

    return await this.escrowRepository.save(escrow);
  }

  async release(escrowActionDto: EscrowActionDto): Promise<Escrow> {
    const { escrowId, milestoneIndex } = escrowActionDto;

    // Release on blockchain
    const txHash = await this.blockchainService.release(escrowActionDto);

    // Update database
    const escrow = await this.escrowRepository.findOne({ where: { escrowId } });
    if (!escrow) {
      throw new NotFoundException('Escrow not found');
    }

    // For simplicity, we'll assume each milestone release adds to released amount
    // In a real implementation, you'd track individual milestones
    const milestoneAmount = await this.blockchainService.getEscrowTotalAmount(escrowId);
    escrow.releasedAmount += milestoneAmount;
    escrow.status = EscrowStatus.RELEASED;
    escrow.blockchainTxHash = txHash;

    if (escrow.releasedAmount >= escrow.totalAmount) {
      escrow.completedAt = new Date();
    }

    return await this.escrowRepository.save(escrow);
  }

  async raiseDispute(escrowActionDto: EscrowActionDto): Promise<Escrow> {
    const { escrowId, reason } = escrowActionDto;

    if (!reason) {
      throw new BadRequestException('Dispute reason is required');
    }

    // Raise dispute on blockchain
    const txHash = await this.blockchainService.raiseDispute(escrowActionDto);

    // Update database
    const escrow = await this.escrowRepository.findOne({ where: { escrowId } });
    if (!escrow) {
      throw new NotFoundException('Escrow not found');
    }

    escrow.status = EscrowStatus.DISPUTED;
    escrow.isDisputed = true;
    escrow.disputeReason = reason;
    escrow.blockchainTxHash = txHash;

    return await this.escrowRepository.save(escrow);
  }

  async adminResolveRelease(escrowActionDto: EscrowActionDto): Promise<Escrow> {
    const { escrowId } = escrowActionDto;

    // Admin resolve release on blockchain
    const txHash = await this.blockchainService.adminResolveRelease(escrowActionDto);

    // Update database
    const escrow = await this.escrowRepository.findOne({ where: { escrowId } });
    if (!escrow) {
      throw new NotFoundException('Escrow not found');
    }

    escrow.status = EscrowStatus.RELEASED;
    escrow.isDisputed = false;
    escrow.blockchainTxHash = txHash;

    return await this.escrowRepository.save(escrow);
  }

  async adminResolveRefund(escrowActionDto: EscrowActionDto): Promise<Escrow> {
    const { escrowId } = escrowActionDto;

    // Admin resolve refund on blockchain
    const txHash = await this.blockchainService.adminResolveRefund(escrowActionDto);

    // Update database
    const escrow = await this.escrowRepository.findOne({ where: { escrowId } });
    if (!escrow) {
      throw new NotFoundException('Escrow not found');
    }

    escrow.status = EscrowStatus.REFUNDED;
    escrow.isDisputed = false;
    escrow.blockchainTxHash = txHash;

    return await this.escrowRepository.save(escrow);
  }

  async getEscrowById(escrowId: string): Promise<Escrow> {
    const escrow = await this.escrowRepository.findOne({ where: { escrowId } });
    if (!escrow) {
      throw new NotFoundException('Escrow not found');
    }
    return escrow;
  }

  async getEscrowByProject(projectId: string): Promise<Escrow> {
    const escrow = await this.escrowRepository.findOne({ where: { projectId } });
    if (!escrow) {
      throw new NotFoundException('Escrow not found for this project');
    }
    return escrow;
  }

  async getAllEscrows(): Promise<Escrow[]> {
    return await this.escrowRepository.find();
  }
}