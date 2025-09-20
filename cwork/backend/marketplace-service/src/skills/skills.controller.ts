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
import { SkillsService } from './skills.service';
import { Skill } from './skill.entity';
import { CreateSkillDto } from './dto/create-skill.dto';
import { UpdateSkillDto } from './dto/update-skill.dto';

@Controller('skills')
export class SkillsController {
  constructor(private readonly skillsService: SkillsService) {}

  @Post()
  @UsePipes(new ValidationPipe({ transform: true }))
  async create(@Body() createSkillDto: CreateSkillDto): Promise<Skill> {
    return this.skillsService.create(createSkillDto);
  }

  @Get()
  async findAll(
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(10), ParseIntPipe) limit: number,
    @Query('search') search?: string,
    @Query('isActive') isActive?: boolean,
    @Query('categoryId') categoryId?: string,
    @Query('demandLevel') demandLevel?: string,
  ): Promise<{ skills: Skill[]; total: number }> {
    return this.skillsService.findAll(page, limit, search, isActive, categoryId, demandLevel);
  }

  @Get(':id')
  async findOne(@Param('id') id: string): Promise<Skill> {
    return this.skillsService.findOne(id);
  }

  @Get('name/:name')
  async findByName(@Param('name') name: string): Promise<Skill> {
    return this.skillsService.findByName(name);
  }

  @Put(':id')
  @UsePipes(new ValidationPipe({ transform: true }))
  async update(
    @Param('id') id: string,
    @Body() updateSkillDto: UpdateSkillDto,
  ): Promise<Skill> {
    return this.skillsService.update(id, updateSkillDto);
  }

  @Delete(':id')
  async remove(@Param('id') id: string): Promise<void> {
    return this.skillsService.remove(id);
  }

  @Get('popular/:limit?')
  async getPopularSkills(@Param('limit') limit?: number): Promise<Skill[]> {
    return this.skillsService.getPopularSkills(limit);
  }

  @Get('stats/all')
  async getSkillsWithStats(): Promise<any[]> {
    return this.skillsService.getSkillsWithStats();
  }

  @Get('search/:query')
  async searchSkills(@Param('query') query: string): Promise<Skill[]> {
    return this.skillsService.searchSkills(query);
  }

  @Get('category/:categoryId')
  async getSkillsByCategory(@Param('categoryId') categoryId: string): Promise<Skill[]> {
    return this.skillsService.getSkillsByCategory(categoryId);
  }

  @Get('trending/:limit?')
  async getTrendingSkills(@Param('limit') limit?: number): Promise<Skill[]> {
    return this.skillsService.getTrendingSkills(limit);
  }
}