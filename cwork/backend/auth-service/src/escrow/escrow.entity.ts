import {
  Entity,
  Column,
  PrimaryGeneratedColumn,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';
import { EscrowStatus, TokenType } from '../types';

@Entity('escrow_transactions')
export class EscrowTransaction {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'escrow_id' })
  escrowId: string;

  @Column({ name: 'project_id' })
  projectId: string;

  @Column({ name: 'milestone_index' })
  milestoneIndex: number;

  @Column({ name: 'client_id' })
  clientId: string;

  @Column({ name: 'developer_id' })
  developerId: string;

  @Column({ type: 'decimal', precision: 28, scale: 18 })
  amount: number;

  @Column({ type: 'decimal', precision: 28, scale: 18, name: 'fee_amount' })
  feeAmount: number;

  @Column({ type: 'varchar', length: 10, default: TokenType.ETH })
  token: TokenType;

  @Column({ nullable: true })
  tokenAddress: string;

  @Column({ type: 'varchar', length: 20, default: EscrowStatus.PENDING })
  status: EscrowStatus;

  @Column({ nullable: true, name: 'transaction_hash' })
  transactionHash: string;

  @Column({ nullable: true, name: 'release_transaction_hash' })
  releaseTransactionHash: string;

  @Column({ nullable: true, name: 'refund_transaction_hash' })
  refundTransactionHash: string;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;

  @Column({ nullable: true, name: 'deposited_at' })
  depositedAt: Date;

  @Column({ nullable: true, name: 'released_at' })
  releasedAt: Date;

  @Column({ nullable: true, name: 'refunded_at' })
  refundedAt: Date;

  @Column({ nullable: true, name: 'disputed_at' })
  disputedAt: Date;

  @Column({ nullable: true, name: 'dispute_reason' })
  disputeReason: string;
}
