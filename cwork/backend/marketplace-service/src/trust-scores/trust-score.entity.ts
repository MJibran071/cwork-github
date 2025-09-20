import { Entity, Column, PrimaryGeneratedColumn, CreateDateColumn, UpdateDateColumn } from 'typeorm';
import { UserTier } from '../users/user-tier.enum';

@Entity('trust_scores')
export class TrustScore {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid' })
  userId: string;

  @Column({ type: 'decimal', precision: 5, scale: 2, default: 0 })
  score: number;

  @Column({ type: 'varchar', length: 20, default: UserTier.BRONZE })
  tier: UserTier;

  @Column({ type: 'int', default: 0 })
  totalReviews: number;

  @Column({ type: 'int', default: 0 })
  positiveReviews: number;

  @Column({ type: 'int', default: 0 })
  negativeReviews: number;

  @Column({ type: 'int', default: 0 })
  completedProjects: number;

  @Column({ type: 'int', default: 0 })
  onTimeCompletions: number;

  @Column({ type: 'int', default: 0 })
  budgetAdherence: number;

  @Column({ type: 'int', default: 0 })
  communicationScore: number;

  @Column({ type: 'int', default: 0 })
  qualityScore: number;

  @Column({ type: 'int', default: 0 })
  professionalismScore: number;

  @Column({ type: 'int', default: 0 })
  responseTimeScore: number;

  @Column({ type: 'int', default: 0 })
  disputeCount: number;

  @Column({ type: 'int', default: 0 })
  successfulDisputeResolutions: number;

  @Column({ type: 'int', default: 0 })
  referralCount: number;

  @Column({ type: 'int', default: 0 })
  verifiedSkillsCount: number;

  @Column({ type: 'int', default: 0 })
  certificationsCount: number;

  @Column({ type: 'int', default: 0 })
  yearsOfExperience: number;

  @Column({ type: 'datetime', nullable: true })
  lastScoreUpdate: Date;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  @Column({ type: 'boolean', default: true })
  isActive: boolean;
}