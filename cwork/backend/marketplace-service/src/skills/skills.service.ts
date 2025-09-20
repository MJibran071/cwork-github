import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Like, In } from 'typeorm';
import { Skill } from './skill.entity';
import { CreateSkillDto } from './dto/create-skill.dto';
import { UpdateSkillDto } from './dto/update-skill.dto';

@Injectable()
export class SkillsService {
  constructor(
    @InjectRepository(Skill)
    private readonly skillRepository: Repository<Skill>,
  ) {}

  async create(createSkillDto: CreateSkillDto): Promise<Skill> {
    // Check if skill with same name already exists
    const existingSkill = await this.skillRepository.findOne({
      where: { name: createSkillDto.name },
    });

    if (existingSkill) {
      throw new BadRequestException('Skill with this name already exists');
    }

    const skill = this.skillRepository.create(createSkillDto);
    return this.skillRepository.save(skill);
  }

  async findAll(
    page: number = 1,
    limit: number = 10,
    search?: string,
    isActive?: boolean,
    categoryId?: string,
    demandLevel?: string,
  ): Promise<{ skills: Skill[]; total: number }> {
    const skip = (page - 1) * limit;
    const where: any = {};

    if (search) {
      where.name = Like(`%${search}%`);
    }

    if (isActive !== undefined) {
      where.isActive = isActive;
    }

    if (categoryId) {
      where.categoryId = categoryId;
    }

    if (demandLevel) {
      where.metadata = { demandLevel };
    }

    const [skills, total] = await this.skillRepository.findAndCount({
      where,
      order: { sortOrder: 'ASC', name: 'ASC' },
      skip,
      take: limit,
    });

    return { skills, total };
  }

  async findOne(id: string): Promise<Skill> {
    const skill = await this.skillRepository.findOne({
      where: { id },
    });

    if (!skill) {
      throw new NotFoundException('Skill not found');
    }

    return skill;
  }

  async findByName(name: string): Promise<Skill> {
    const skill = await this.skillRepository.findOne({
      where: { name },
    });

    if (!skill) {
      throw new NotFoundException('Skill not found');
    }

    return skill;
  }

  async update(id: string, updateSkillDto: UpdateSkillDto): Promise<Skill> {
    const skill = await this.findOne(id);

    // Check if name change would conflict with existing skill
    if (updateSkillDto.name && updateSkillDto.name !== skill.name) {
      const existingSkill = await this.skillRepository.findOne({
        where: { name: updateSkillDto.name },
      });

      if (existingSkill) {
        throw new BadRequestException('Skill with this name already exists');
      }
    }

    Object.assign(skill, updateSkillDto);
    return this.skillRepository.save(skill);
  }

  async remove(id: string): Promise<void> {
    const skill = await this.findOne(id);
    
    // Check if skill has projects or freelancers
    if (skill.projectCount > 0 || skill.freelancerCount > 0) {
      throw new BadRequestException('Cannot delete skill with associated projects or freelancers');
    }

    await this.skillRepository.remove(skill);
  }

  async incrementProjectCount(id: string): Promise<void> {
    await this.skillRepository.increment({ id }, 'projectCount', 1);
  }

  async decrementProjectCount(id: string): Promise<void> {
    await this.skillRepository.decrement({ id }, 'projectCount', 1);
  }

  async incrementFreelancerCount(id: string): Promise<void> {
    await this.skillRepository.increment({ id }, 'freelancerCount', 1);
  }

  async decrementFreelancerCount(id: string): Promise<void> {
    await this.skillRepository.decrement({ id }, 'freelancerCount', 1);
  }

  async getPopularSkills(limit: number = 10): Promise<Skill[]> {
    return this.skillRepository.find({
      where: { isActive: true },
      order: { projectCount: 'DESC' },
      take: limit,
    });
  }

  async getSkillsWithStats(): Promise<any[]> {
    return this.skillRepository
      .createQueryBuilder('skill')
      .select([
        'skill.id',
        'skill.name',
        'skill.description',
        'skill.icon',
        'skill.projectCount',
        'skill.freelancerCount',
        'skill.isActive',
        'skill.metadata',
      ])
      .where('skill.isActive = :isActive', { isActive: true })
      .orderBy('skill.projectCount', 'DESC')
      .getMany();
  }

  async bulkUpdate(ids: string[], updateData: Partial<Skill>): Promise<void> {
    await this.skillRepository.update(ids, updateData);
  }

  async searchSkills(query: string): Promise<Skill[]> {
    return this.skillRepository.find({
      where: [
        { name: Like(`%${query}%`) },
        { description: Like(`%${query}%`) },
      ],
      take: 10,
    });
  }

  async getSkillsByCategory(categoryId: string): Promise<Skill[]> {
    return this.skillRepository.find({
      where: { categoryId, isActive: true },
      order: { sortOrder: 'ASC', name: 'ASC' },
    });
  }

  async getTrendingSkills(limit: number = 5): Promise<Skill[]> {
    return this.skillRepository.find({
      where: { 
        isActive: true,
        metadata: { trending: true } 
      },
      order: { projectCount: 'DESC' },
      take: limit,
    });
  }
}