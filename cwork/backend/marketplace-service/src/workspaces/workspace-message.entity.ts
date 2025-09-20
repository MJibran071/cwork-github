import { Entity, Column, PrimaryGeneratedColumn, CreateDateColumn, UpdateDateColumn, ManyToOne } from 'typeorm';
import { Workspace, WorkspaceMember } from './index';
import { MessageType } from './message-type.enum';
import { ModerationStatus } from './moderation-status.enum';

@Entity('workspace_messages')
export class WorkspaceMessage {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid' })
  workspaceId: string;

  @ManyToOne(() => Workspace, workspace => workspace.messages)
  workspace: Workspace;

  @Column({ type: 'uuid' })
  senderId: string;

  @ManyToOne(() => WorkspaceMember, member => member.id)
  sender: WorkspaceMember;

  @Column({ type: 'varchar', length: 20 })
  type: MessageType;

  @Column({ type: 'text', nullable: true })
  content: string;

  @Column({ type: 'varchar', length: 255, nullable: true })
  fileUrl: string;

  @Column({ type: 'varchar', length: 100, nullable: true })
  fileName: string;

  @Column({ type: 'int', nullable: true })
  fileSize: number;

  @Column({ type: 'uuid', nullable: true })
  taskId: string;

  @Column({ type: 'boolean', default: false })
  isEdited: boolean;

  @Column({ type: 'datetime', nullable: true })
  editedAt: Date;

  @Column({ type: 'boolean', default: false })
  isDeleted: boolean;

  @Column({ type: 'datetime', nullable: true })
  deletedAt: Date;

  @Column({ type: 'int', default: 0 })
  replyCount: number;

  @Column({ type: 'uuid', nullable: true })
  parentMessageId: string;

  @Column({ type: 'simple-array', nullable: true })
  mentions: string[];

  @Column({ type: 'simple-array', nullable: true })
  reactions: string[];

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  @Column({ type: 'boolean', default: true })
  isActive: boolean;

  @Column({
    type: 'enum',
    enum: ModerationStatus,
    default: ModerationStatus.PENDING
  })
  moderationStatus: ModerationStatus;
}