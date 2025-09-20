import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { EscrowTransaction } from './escrow.entity';
import { EscrowStatus, TokenType } from '../types';
import { ConfigService } from '@nestjs/config';
import { ethers } from 'ethers';

@Injectable()
export class EscrowService {
  private provider: ethers.Provider;
  private contract: ethers.Contract;

  constructor(
    @InjectRepository(EscrowTransaction)
    private readonly escrowRepository: Repository<EscrowTransaction>,
    private configService: ConfigService,
  ) {
    this.initializeWeb3();
  }

  private initializeWeb3() {
    const rpcUrl = this.configService.get<string>('ETHEREUM_RPC_URL');
    const contractAddress = this.configService.get<string>('ESCROW_CONTRACT_ADDRESS');
    const privateKey = this.configService.get<string>('ADMIN_PRIVATE_KEY');

    if (rpcUrl && contractAddress) {
      this.provider = new ethers.JsonRpcProvider(rpcUrl);

      if (privateKey) {
        new ethers.Wallet(privateKey, this.provider); // Wallet created but not used yet
        // Initialize contract with signer for admin operations
        // this.contract = new ethers.Contract(contractAddress, abi, wallet);
      } else {
        // Initialize contract without signer for read-only operations
        // this.contract = new ethers.Contract(contractAddress, abi, this.provider);
      }
    }
  }

  async createTransaction(transactionData: {
    escrowId: string;
    projectId: string;
    milestoneIndex: number;
    clientId: string;
    developerId: string;
    amount: number;
    feeAmount: number;
    token: TokenType;
    tokenAddress?: string;
  }): Promise<EscrowTransaction> {
    const transaction = this.escrowRepository.create({
      ...transactionData,
      status: EscrowStatus.PENDING,
    });

    return await this.escrowRepository.save(transaction);
  }

  async updateTransactionStatus(
    transactionId: string,
    status: EscrowStatus,
    transactionHash?: string,
  ): Promise<EscrowTransaction> {
    const updateData: Partial<EscrowTransaction> = { status };

    if (transactionHash) {
      if (status === EscrowStatus.DEPOSITED) {
        updateData.transactionHash = transactionHash;
        updateData.depositedAt = new Date();
      } else if (status === EscrowStatus.RELEASED) {
        updateData.releaseTransactionHash = transactionHash;
        updateData.releasedAt = new Date();
      } else if (status === EscrowStatus.REFUNDED) {
        updateData.refundTransactionHash = transactionHash;
        updateData.refundedAt = new Date();
      }
    }

    await this.escrowRepository.update(transactionId, updateData);
    return this.escrowRepository.findOne({ where: { id: transactionId } });
  }

  async markAsDisputed(transactionId: string, reason: string): Promise<EscrowTransaction> {
    await this.escrowRepository.update(transactionId, {
      status: EscrowStatus.DISPUTED,
      disputeReason: reason,
      disputedAt: new Date(),
    });

    return this.escrowRepository.findOne({ where: { id: transactionId } });
  }

  async getTransactionById(id: string): Promise<EscrowTransaction> {
    return this.escrowRepository.findOne({ where: { id } });
  }

  async getTransactionsByProject(projectId: string): Promise<EscrowTransaction[]> {
    return this.escrowRepository.find({
      where: { projectId },
      order: { createdAt: 'DESC' },
    });
  }

  async getTransactionsByUser(userId: string): Promise<EscrowTransaction[]> {
    return this.escrowRepository.find({
      where: [{ clientId: userId }, { developerId: userId }],
      order: { createdAt: 'DESC' },
    });
  }

  async getFeeStatistics(): Promise<{
    totalFees: number;
    totalFeesByToken: Record<TokenType, number>;
    totalTransactions: number;
  }> {
    const result = await this.escrowRepository
      .createQueryBuilder('transaction')
      .select('transaction.token', 'token')
      .addSelect('SUM(transaction.feeAmount)', 'totalFees')
      .addSelect('COUNT(transaction.id)', 'transactionCount')
      .where('transaction.status IN (:...statuses)', {
        statuses: [EscrowStatus.RELEASED, EscrowStatus.REFUNDED],
      })
      .groupBy('transaction.token')
      .getRawMany();

    const totalFeesByToken: Record<TokenType, number> = {
      [TokenType.ETH]: 0,
      [TokenType.USDT]: 0,
      [TokenType.USDC]: 0,
      [TokenType.DAI]: 0,
      [TokenType.OTHER]: 0,
    };

    let totalFees = 0;
    let totalTransactions = 0;

    result.forEach((row) => {
      const token = row.token as TokenType;
      const fees = parseFloat(row.totalFees) || 0;
      const count = parseInt(row.transactionCount) || 0;

      totalFeesByToken[token] = fees;
      totalFees += fees;
      totalTransactions += count;
    });

    return { totalFees, totalFeesByToken, totalTransactions };
  }

  async getMinimumDepositAmounts(): Promise<{
    eth: number;
    usdt: number;
    usdc: number;
  }> {
    return {
      eth: 0.05,
      usdt: 10,
      usdc: 10,
    };
  }

  async calculateFee(amount: number): Promise<{ amount: number; fee: number }> {
    const feePercentage = 5; // 5% service fee
    const fee = (amount * feePercentage) / 100;
    return { amount, fee };
  }
}
