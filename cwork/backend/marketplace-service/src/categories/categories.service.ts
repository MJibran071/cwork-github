import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Like, In } from 'typeorm';
import { Category } from './category.entity';
import { CreateCategoryDto } from './dto/create-category.dto';
import { UpdateCategoryDto } from './dto/update-category.dto';

@Injectable()
export class CategoriesService {
  constructor(
    @InjectRepository(Category)
    private readonly categoryRepository: Repository<Category>,
  ) {}

  async create(createCategoryDto: CreateCategoryDto): Promise<Category> {
    // Check if category with same name already exists
    const existingCategory = await this.categoryRepository.findOne({
      where: { name: createCategoryDto.name },
    });

    if (existingCategory) {
      throw new BadRequestException('Category with this name already exists');
    }

    const category = this.categoryRepository.create(createCategoryDto);
    return this.categoryRepository.save(category);
  }

  async findAll(
    page: number = 1,
    limit: number = 10,
    search?: string,
    isActive?: boolean,
    parentId?: string,
  ): Promise<{ categories: Category[]; total: number }> {
    const skip = (page - 1) * limit;
    const where: any = {};

    if (search) {
      where.name = Like(`%${search}%`);
    }

    if (isActive !== undefined) {
      where.isActive = isActive;
    }

    if (parentId) {
      where.parentId = parentId;
    }

    const [categories, total] = await this.categoryRepository.findAndCount({
      where,
      order: { sortOrder: 'ASC', name: 'ASC' },
      skip,
      take: limit,
    });

    return { categories, total };
  }

  async findOne(id: string): Promise<Category> {
    const category = await this.categoryRepository.findOne({
      where: { id },
    });

    if (!category) {
      throw new NotFoundException('Category not found');
    }

    return category;
  }

  async findByName(name: string): Promise<Category> {
    const category = await this.categoryRepository.findOne({
      where: { name },
    });

    if (!category) {
      throw new NotFoundException('Category not found');
    }

    return category;
  }

  async update(id: string, updateCategoryDto: UpdateCategoryDto): Promise<Category> {
    const category = await this.findOne(id);

    // Check if name change would conflict with existing category
    if (updateCategoryDto.name && updateCategoryDto.name !== category.name) {
      const existingCategory = await this.categoryRepository.findOne({
        where: { name: updateCategoryDto.name },
      });

      if (existingCategory) {
        throw new BadRequestException('Category with this name already exists');
      }
    }

    Object.assign(category, updateCategoryDto);
    return this.categoryRepository.save(category);
  }

  async remove(id: string): Promise<void> {
    const category = await this.findOne(id);
    
    // Check if category has projects
    if (category.projectCount > 0) {
      throw new BadRequestException('Cannot delete category with associated projects');
    }

    await this.categoryRepository.remove(category);
  }

  async incrementProjectCount(id: string): Promise<void> {
    await this.categoryRepository.increment({ id }, 'projectCount', 1);
  }

  async decrementProjectCount(id: string): Promise<void> {
    await this.categoryRepository.decrement({ id }, 'projectCount', 1);
  }

  async getPopularCategories(limit: number = 10): Promise<Category[]> {
    return this.categoryRepository.find({
      where: { isActive: true },
      order: { projectCount: 'DESC' },
      take: limit,
    });
  }

  async getCategoriesWithStats(): Promise<any[]> {
    return this.categoryRepository
      .createQueryBuilder('category')
      .select([
        'category.id',
        'category.name',
        'category.description',
        'category.icon',
        'category.projectCount',
        'category.isActive',
        'category.metadata',
      ])
      .where('category.isActive = :isActive', { isActive: true })
      .orderBy('category.projectCount', 'DESC')
      .getMany();
  }

  async bulkUpdate(ids: string[], updateData: Partial<Category>): Promise<void> {
    await this.categoryRepository.update(ids, updateData);
  }

  async searchCategories(query: string): Promise<Category[]> {
    return this.categoryRepository.find({
      where: [
        { name: Like(`%${query}%`) },
        { description: Like(`%${query}%`) },
      ],
      take: 10,
    });
  }
}