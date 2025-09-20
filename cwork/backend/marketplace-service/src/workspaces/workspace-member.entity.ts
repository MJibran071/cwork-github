import { Entity, Column, PrimaryGeneratedColumn, CreateDateColumn, UpdateDateColumn, ManyToOne } from 'typeorm';
import { Workspace } from './index';

export enum MemberRole {
  OWNER = 'owner',
  ADMIN = 'admin',
  MEMBER = 'member',
  GUEST = 'guest'
}

export enum MemberStatus {
  ACTIVE = 'active',
  INVITED = 'invited',
  PENDING = 'pending',
  REJECTED = 'rejected',
  LEFT = 'left'
}

@Entity('workspace_members')
export class WorkspaceMember {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid' })
  workspaceId: string;

  @ManyToOne(() => Workspace, workspace => workspace.members)
  workspace: Workspace;

  @Column({ type: 'uuid' })
  userId: string;

  @Column({ type: 'varchar', length: 255 })
  userName: string;

  @Column({ type: 'varchar', length: 255, nullable: true })
  userEmail: string;

  @Column({
    type: 'varchar',
    default: MemberRole.MEMBER
  })
  role: MemberRole;

  @Column({
    type: 'varchar',
    default: MemberStatus.INVITED
  })
  status: MemberStatus;

  @Column({ type: 'boolean', default: false })
  canEdit: boolean;

  @Column({ type: 'boolean', default: false })
  canDelete: boolean;

  @Column({ type: 'boolean', default: false })
  canInvite: boolean;

  @Column({ type: 'boolean', default: false })
  canManageTasks: boolean;

  @Column({ type: 'boolean', default: false })
  canUploadFiles: boolean;

  @Column({ type: 'datetime', nullable: true })
  joinedAt: Date;

  @Column({ type: 'datetime', nullable: true })
  leftAt: Date;

  @Column({ type: 'int', default: 0 })
  messageCount: number;

  @Column({ type: 'int', default: 0 })
  fileCount: number;

  @Column({ type: 'int', default: 0 })
  taskCount: number;

  @Column({ type: 'int', default: 0 })
  completedTaskCount: number;

  @Column({ type: 'datetime', nullable: true })
  lastSeenAt: Date;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  @Column({ type: 'boolean', default: true })
  isActive: boolean;
}