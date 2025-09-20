import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, ManyToOne } from 'typeorm';
import { EscrowStatus } from '../blockchain/dto/blockchain.dto';
import { Project } from '../projects/project.entity';

@Entity('escrows')
export class Escrow {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true })
  escrowId: string; // Blockchain escrow ID

  @Column()
  projectId: string;

  @ManyToOne(() => Project, project => project.escrow)
  project: Project;

  @Column()
  clientId: string;

  @Column()
  developerId: string;

  @Column('decimal', { precision: 18, scale: 6 })
  totalAmount: number;

  @Column('decimal', { precision: 18, scale: 6 })
  releasedAmount: number = 0;

  @Column('decimal', { precision: 18, scale: 6 })
  feeAmount: number;

  @Column({ default: 'ETH' })
  currency: string;

  @Column({
    type: 'varchar',
    default: EscrowStatus.NONE
  })
  status: EscrowStatus;

  @Column({ nullable: true })
  blockchainTxHash: string;

  @Column({ nullable: true })
  contractAddress: string;

  @Column({ nullable: true })
  disputeReason: string;

  @Column({ default: false })
  isDisputed: boolean;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  @Column({ nullable: true })
  completedAt: Date;
}