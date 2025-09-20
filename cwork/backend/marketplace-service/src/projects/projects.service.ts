import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Like, Between } from 'typeorm';
import { Project, ProjectStatus, ProjectType } from './project.entity';
import { CreateProjectDto } from './dto/create-project.dto';
import { UpdateProjectDto } from './dto/update-project.dto';

@Injectable()
export class ProjectsService {
  constructor(
    @InjectRepository(Project)
    private projectsRepository: Repository<Project>,
  ) {}

  async create(createProjectDto: CreateProjectDto, clientId: string): Promise<Project> {
    const project = this.projectsRepository.create({
      ...createProjectDto,
      clientId,
      status: ProjectStatus.DRAFT,
    });
    return await this.projectsRepository.save(project);
  }

  async findAll(
    page: number = 1,
    limit: number = 10,
    status?: ProjectStatus,
    type?: ProjectType,
    categoryId?: string,
    search?: string,
    minBudget?: number,
    maxBudget?: number,
  ): Promise<{ projects: Project[]; total: number }> {
    const skip = (page - 1) * limit;
    const where: any = { isDeleted: false };

    if (status) where.status = status;
    if (type) where.type = type;
    if (categoryId) where.categoryId = categoryId;
    
    if (minBudget !== undefined && maxBudget !== undefined) {
      where.budget = Between(minBudget, maxBudget);
    } else if (minBudget !== undefined) {
      where.budget = Between(minBudget, Number.MAX_SAFE_INTEGER);
    } else if (maxBudget !== undefined) {
      where.budget = Between(0, maxBudget);
    }

    if (search) {
      where.title = Like(`%${search}%`);
    }

    const [projects, total] = await this.projectsRepository.findAndCount({
      where,
      relations: ['category'],
      order: { createdAt: 'DESC' },
      skip,
      take: limit,
    });

    return { projects, total };
  }

  async findOne(id: string): Promise<Project> {
    const project = await this.projectsRepository.findOne({
      where: { id, isDeleted: false },
      relations: ['category', 'proposals'],
    });

    if (!project) {
      throw new NotFoundException(`Project with ID ${id} not found`);
    }

    // Increment view count
    project.views += 1;
    await this.projectsRepository.save(project);

    return project;
  }

  async update(id: string, updateProjectDto: UpdateProjectDto): Promise<Project> {
    const project = await this.findOne(id);
    Object.assign(project, updateProjectDto);
    return await this.projectsRepository.save(project);
  }

  async remove(id: string): Promise<void> {
    const project = await this.findOne(id);
    project.isDeleted = true;
    await this.projectsRepository.save(project);
  }

  async publish(id: string): Promise<Project> {
    const project = await this.findOne(id);
    project.status = ProjectStatus.PUBLISHED;
    project.publishedAt = new Date();
    return await this.projectsRepository.save(project);
  }

  async complete(id: string): Promise<Project> {
    const project = await this.findOne(id);
    project.status = ProjectStatus.COMPLETED;
    project.completedAt = new Date();
    return await this.projectsRepository.save(project);
  }

  async findByClientId(clientId: string): Promise<Project[]> {
    return await this.projectsRepository.find({
      where: { clientId, isDeleted: false },
      order: { createdAt: 'DESC' },
    });
  }

  async findByFreelancerId(freelancerId: string): Promise<Project[]> {
    return await this.projectsRepository.find({
      where: { freelancerId, isDeleted: false },
      order: { createdAt: 'DESC' },
    });
  }

  async incrementProposalsCount(id: string): Promise<void> {
    await this.projectsRepository.increment({ id }, 'proposalsCount', 1);
  }
}