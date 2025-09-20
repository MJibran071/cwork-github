import { 
  Controller, 
  Get, 
  Post, 
  Put, 
  Delete, 
  Body, 
  Param, 
  Query, 
  UsePipes, 
  ValidationPipe,
  ParseIntPipe,
  DefaultValuePipe 
} from '@nestjs/common';
import { CategoriesService } from './categories.service';
import { Category } from './category.entity';
import { CreateCategoryDto } from './dto/create-category.dto';
import { UpdateCategoryDto } from './dto/update-category.dto';

@Controller('categories')
export class CategoriesController {
  constructor(private readonly categoriesService: CategoriesService) {}

  @Post()
  @UsePipes(new ValidationPipe({ transform: true }))
  async create(@Body() createCategoryDto: CreateCategoryDto): Promise<Category> {
    return this.categoriesService.create(createCategoryDto);
  }

  @Get()
  async findAll(
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(10), ParseIntPipe) limit: number,
    @Query('search') search?: string,
    @Query('isActive') isActive?: boolean,
    @Query('parentId') parentId?: string,
  ): Promise<{ categories: Category[]; total: number }> {
    return this.categoriesService.findAll(page, limit, search, isActive, parentId);
  }

  @Get(':id')
  async findOne(@Param('id') id: string): Promise<Category> {
    return this.categoriesService.findOne(id);
  }

  @Get('name/:name')
  async findByName(@Param('name') name: string): Promise<Category> {
    return this.categoriesService.findByName(name);
  }

  @Put(':id')
  @UsePipes(new ValidationPipe({ transform: true }))
  async update(
    @Param('id') id: string,
    @Body() updateCategoryDto: UpdateCategoryDto,
  ): Promise<Category> {
    return this.categoriesService.update(id, updateCategoryDto);
  }

  @Delete(':id')
  async remove(@Param('id') id: string): Promise<void> {
    return this.categoriesService.remove(id);
  }

  @Get('popular/:limit?')
  async getPopularCategories(@Param('limit') limit?: number): Promise<Category[]> {
    return this.categoriesService.getPopularCategories(limit);
  }

  @Get('stats/all')
  async getCategoriesWithStats(): Promise<any[]> {
    return this.categoriesService.getCategoriesWithStats();
  }

  @Get('search/:query')
  async searchCategories(@Param('query') query: string): Promise<Category[]> {
    return this.categoriesService.searchCategories(query);
  }
}