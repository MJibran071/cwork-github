import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, ManyToOne, OneToMany, OneToOne } from 'typeorm';
import { User } from '../users/user.entity'; // Local user entity
import { Proposal } from '../proposals/proposal.entity';
import { Category } from '../categories/category.entity';
import { Escrow } from '../escrow/escrow.entity';
import { Review } from '../reviews/review.entity';
import { Workspace } from '../workspaces/workspace.entity';

export enum ProjectStatus {
  DRAFT = 'draft',
  PUBLISHED = 'published',
  IN_PROGRESS = 'in_progress',
  COMPLETED = 'completed',
  CANCELLED = 'cancelled',
  DISPUTED = 'disputed'
}

export enum ProjectType {
  FIXED_PRICE = 'fixed_price',
  HOURLY = 'hourly',
  MILESTONE = 'milestone'
}

export enum ExperienceLevel {
  ENTRY = 'entry',
  INTERMEDIATE = 'intermediate',
  EXPERT = 'expert'
}

@Entity('projects')
export class Project {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  title: string;

  @Column('text')
  description: string;

  @Column({ type: 'decimal', precision: 10, scale: 2 })
  budget: number;

  @Column({ nullable: true })
  currency: string;

  @Column({ type: 'varchar', length: 20, default: ProjectType.FIXED_PRICE })
  type: ProjectType;

  @Column({ type: 'varchar', length: 20, default: ProjectStatus.DRAFT })
  status: ProjectStatus;

  @Column({ type: 'varchar', length: 20, default: ExperienceLevel.INTERMEDIATE })
  experienceLevel: ExperienceLevel;

  @Column({ nullable: true })
  duration: string; // e.g., "1-3 months", "Less than 1 month"

  @Column({ default: false })
  featured: boolean;

  @Column({ default: 0 })
  views: number;

  @Column({ default: 0 })
  proposalsCount: number;

  @Column({ type: 'simple-array', nullable: true })
  skills: string[];

  @Column({ nullable: true })
  clientId: string; // Reference to user from auth service

  @Column({ nullable: true })
  freelancerId: string; // Reference to user from auth service

  @Column({ nullable: true })
  categoryId: string;

  @ManyToOne(() => Category, category => category.projects)
  category: Category;

  @OneToMany(() => Proposal, proposal => proposal.project)
  proposals: Proposal[];

  @OneToMany(() => Review, review => review.project)
  reviews: Review[];

  @OneToMany(() => Workspace, workspace => workspace.project)
  workspaces: Workspace[];

  @OneToOne(() => Escrow, escrow => escrow.project)
  escrow: Escrow;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  @Column({ nullable: true })
  publishedAt: Date;

  @Column({ nullable: true })
  completedAt: Date;

  @Column({ default: false })
  isDeleted: boolean;
}