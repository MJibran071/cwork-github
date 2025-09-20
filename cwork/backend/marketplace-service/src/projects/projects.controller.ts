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
import { ProjectsService } from './projects.service';
import { Project, ProjectStatus } from './project.entity';
import { CreateProjectDto } from './dto/create-project.dto';
import { UpdateProjectDto } from './dto/update-project.dto';

@Controller('projects')
export class ProjectsController {
  constructor(private readonly projectsService: ProjectsService) {}

  @Post()
  @UsePipes(new ValidationPipe({ transform: true }))
  async create(
    @Body() createProjectDto: CreateProjectDto,
    @Query('clientId') clientId: string, // In real implementation, this would come from auth
  ): Promise<Project> {
    return this.projectsService.create(createProjectDto, clientId);
  }

  @Get()
  async findAll(
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(10), ParseIntPipe) limit: number,
    @Query('status') status?: ProjectStatus,
    @Query('type') type?: string,
    @Query('categoryId') categoryId?: string,
    @Query('search') search?: string,
    @Query('minBudget') minBudget?: number,
    @Query('maxBudget') maxBudget?: number,
  ): Promise<{ projects: Project[]; total: number }> {
    return this.projectsService.findAll(
      page,
      limit,
      status,
      type as any,
      categoryId,
      search,
      minBudget,
      maxBudget,
    );
  }

  @Get(':id')
  async findOne(@Param('id') id: string): Promise<Project> {
    return this.projectsService.findOne(id);
  }

  @Put(':id')
  @UsePipes(new ValidationPipe({ transform: true }))
  async update(
    @Param('id') id: string,
    @Body() updateProjectDto: UpdateProjectDto,
  ): Promise<Project> {
    return this.projectsService.update(id, updateProjectDto);
  }

  @Delete(':id')
  async remove(@Param('id') id: string): Promise<void> {
    return this.projectsService.remove(id);
  }

  @Put(':id/publish')
  async publish(@Param('id') id: string): Promise<Project> {
    return this.projectsService.publish(id);
  }

  @Put(':id/complete')
  async complete(@Param('id') id: string): Promise<Project> {
    return this.projectsService.complete(id);
  }

  @Get('client/:clientId')
  async findByClientId(@Param('clientId') clientId: string): Promise<Project[]> {
    return this.projectsService.findByClientId(clientId);
  }

  @Get('freelancer/:freelancerId')
  async findByFreelancerId(@Param('freelancerId') freelancerId: string): Promise<Project[]> {
    return this.projectsService.findByFreelancerId(freelancerId);
  }
}