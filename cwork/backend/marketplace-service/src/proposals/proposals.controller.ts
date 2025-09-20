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
import { ProposalsService } from './proposals.service';
import { Proposal, ProposalStatus } from './proposal.entity';
import { CreateProposalDto } from './dto/create-proposal.dto';
import { UpdateProposalDto } from './dto/update-proposal.dto';

@Controller('proposals')
export class ProposalsController {
  constructor(private readonly proposalsService: ProposalsService) {}

  @Post()
  @UsePipes(new ValidationPipe({ transform: true }))
  async create(
    @Body() createProposalDto: CreateProposalDto,
    @Query('freelancerId') freelancerId: string, // In real implementation, this would come from auth
  ): Promise<Proposal> {
    return this.proposalsService.create(createProposalDto, freelancerId);
  }

  @Get()
  async findAll(
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(10), ParseIntPipe) limit: number,
    @Query('projectId') projectId?: string,
    @Query('freelancerId') freelancerId?: string,
    @Query('status') status?: ProposalStatus,
    @Query('type') type?: string,
    @Query('minAmount') minAmount?: number,
    @Query('maxAmount') maxAmount?: number,
  ): Promise<{ proposals: Proposal[]; total: number }> {
    return this.proposalsService.findAll(
      page,
      limit,
      projectId,
      freelancerId,
      status,
      type as any,
      minAmount,
      maxAmount,
    );
  }

  @Get(':id')
  async findOne(@Param('id') id: string): Promise<Proposal> {
    return this.proposalsService.findOne(id);
  }

  @Put(':id')
  @UsePipes(new ValidationPipe({ transform: true }))
  async update(
    @Param('id') id: string,
    @Body() updateProposalDto: UpdateProposalDto,
  ): Promise<Proposal> {
    return this.proposalsService.update(id, updateProposalDto);
  }

  @Delete(':id')
  async remove(@Param('id') id: string): Promise<void> {
    return this.proposalsService.remove(id);
  }

  @Put(':id/accept')
  async accept(@Param('id') id: string): Promise<Proposal> {
    return this.proposalsService.accept(id);
  }

  @Put(':id/reject')
  async reject(@Param('id') id: string): Promise<Proposal> {
    return this.proposalsService.reject(id);
  }

  @Put(':id/withdraw')
  async withdraw(
    @Param('id') id: string,
    @Query('freelancerId') freelancerId: string,
  ): Promise<Proposal> {
    return this.proposalsService.withdraw(id, freelancerId);
  }

  @Get('project/:projectId')
  async findByProjectId(@Param('projectId') projectId: string): Promise<Proposal[]> {
    return this.proposalsService.findByProjectId(projectId);
  }

  @Get('freelancer/:freelancerId')
  async findByFreelancerId(@Param('freelancerId') freelancerId: string): Promise<Proposal[]> {
    return this.proposalsService.findByFreelancerId(freelancerId);
  }

  @Get('stats/:freelancerId')
  async getStats(@Param('freelancerId') freelancerId: string): Promise<{
    total: number;
    pending: number;
    accepted: number;
    rejected: number;
    withdrawn: number;
    successRate: number;
  }> {
    return this.proposalsService.getStats(freelancerId);
  }
}