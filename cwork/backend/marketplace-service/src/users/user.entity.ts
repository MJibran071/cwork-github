import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn } from 'typeorm';
import { UserTier } from './user-tier.enum';

@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true })
  authId: string; // Reference to auth service user ID

  @Column()
  email: string;

  @Column()
  username: string;

  @Column({ nullable: true })
  displayName: string;

  @Column({
    type: 'varchar',
    default: 'basic'
  })
  tier: UserTier;

  @Column({ default: 'freelancer' })
  role: string; // client, freelancer, admin

  @Column({ default: true })
  isActive: boolean;

  @Column({ nullable: true })
  profileImage: string;

  @Column({ nullable: true })
  walletAddress: string;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  @Column({ nullable: true })
  lastLoginAt: Date;
}