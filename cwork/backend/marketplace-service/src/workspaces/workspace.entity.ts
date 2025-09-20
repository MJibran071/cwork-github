import { Entity, Column, PrimaryGeneratedColumn, CreateDateColumn, UpdateDateColumn, ManyToOne, OneToMany } from 'typeorm';
import { Project } from '../projects/project.entity';
import { WorkspaceMember, WorkspaceMessage, WorkspaceFile } from './index';

export enum WorkspaceStatus {
  ACTIVE = 'active',
  ARCHIVED = 'archived',
  COMPLETED = 'completed'
}

@Entity('workspaces')
export class Workspace {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid' })
  projectId: string;

  @ManyToOne(() => Project, project => project.workspaces)
  project: Project;

  @Column({ type: 'uuid' })
  creatorId: string;

  @Column({ type: 'varchar', length: 255 })
  title: string;

  @Column({ type: 'text', nullable: true })
  description: string;

  @Column({
    type: 'varchar',
    default: WorkspaceStatus.ACTIVE
  })
  status: WorkspaceStatus;

  @Column({ type: 'datetime', nullable: true })
  startDate: Date;

  @Column({ type: 'datetime', nullable: true })
  endDate: Date;

  @Column({ type: 'boolean', default: false })
  isPublic: boolean;

  @Column({ type: 'varchar', length: 50, nullable: true })
  accessCode: string;

  @Column({ type: 'int', default: 0 })
  messageCount: number;

  @Column({ type: 'int', default: 0 })
  fileCount: number;

  @Column({ type: 'int', default: 0 })
  taskCount: number;

  @Column({ type: 'int', default: 0 })
  completedTaskCount: number;

  @OneToMany(() => WorkspaceMember, member => member.workspace)
  members: WorkspaceMember[];

  @OneToMany(() => WorkspaceMessage, message => message.workspace)
  messages: WorkspaceMessage[];

  @OneToMany(() => WorkspaceFile, file => file.workspace)
  files: WorkspaceFile[];


  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  @Column({ type: 'datetime', nullable: true })
  lastActivityAt: Date;
}