import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, ManyToOne } from 'typeorm';
import { Project } from '../projects/project.entity';

export enum ReviewType {
  CLIENT_TO_FREELANCER = 'client_to_freelancer',
  FREELANCER_TO_CLIENT = 'freelancer_to_client',
  PROJECT_REVIEW = 'project_review'
}

export enum ReviewStatus {
  PENDING = 'pending',
  PUBLISHED = 'published',
  FLAGGED = 'flagged',
  REMOVED = 'removed'
}

@Entity('reviews')
export class Review {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => Project, project => project.reviews)
  project: Project;

  @Column()
  projectId: string;

  @Column()
  reviewerId: string; // User who wrote the review

  @Column()
  reviewedUserId: string; // User being reviewed

  @Column({ type: 'varchar', length: 20 })
  type: ReviewType;

  @Column({ type: 'int' })
  rating: number; // 1-5 stars

  @Column({ type: 'text' })
  title: string;

  @Column({ type: 'text' })
  content: string;

  @Column({ type: 'simple-json', nullable: true })
  criteriaScores: {
    quality?: number;
    communication?: number;
    professionalism?: number;
    deadline?: number;
    budget?: number;
  };

  @Column({ type: 'varchar', length: 20, default: ReviewStatus.PUBLISHED })
  status: ReviewStatus;

  @Column({ type: 'boolean', default: false })
  isVerified: boolean; // Whether the review is from a verified transaction

  @Column({ type: 'int', default: 0 })
  helpfulCount: number;

  @Column({ type: 'int', default: 0 })
  reportCount: number;

  @Column({ type: 'simple-json', nullable: true })
  metadata: {
    projectCompletion?: boolean;
    paymentVerified?: boolean;
    responseTime?: number; // in hours
    revisionCount?: number;
  };

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  @Column({ type: 'datetime', nullable: true })
  publishedAt: Date;

  @Column({ type: 'datetime', nullable: true })
  flaggedAt: Date;

  @Column({ type: 'text', nullable: true })
  flagReason: string;
}