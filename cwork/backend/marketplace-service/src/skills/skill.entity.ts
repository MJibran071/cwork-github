import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, ManyToMany } from 'typeorm';
import { Project } from '../projects/project.entity';

@Entity('skills')
export class Skill {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true })
  name: string;

  @Column({ type: 'text', nullable: true })
  description: string;

  @Column({ nullable: true })
  icon: string;

  @Column({ default: 0 })
  projectCount: number;

  @Column({ default: 0 })
  freelancerCount: number;

  @Column({ default: true })
  isActive: boolean;

  @Column({ type: 'int', default: 0 })
  sortOrder: number;

  @Column({ nullable: true })
  categoryId: string;

  @Column({ type: 'simple-json', nullable: true })
  metadata: {
    averageRate?: number;
    demandLevel?: 'low' | 'medium' | 'high';
    trending?: boolean;
    relatedSkills?: string[];
  };

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  @ManyToMany(() => Project, project => project.skills)
  projects: Project[];
}