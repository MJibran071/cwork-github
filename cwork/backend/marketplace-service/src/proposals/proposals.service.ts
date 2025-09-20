import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Between, LessThanOrEqual, MoreThanOrEqual, In } from 'typeorm';
import { Proposal, ProposalStatus, ProposalType } from './proposal.entity';
import { CreateProposalDto } from './dto/create-proposal.dto';
import { UpdateProposalDto } from './dto/update-proposal.dto';
import { ProjectsService } from '../projects/projects.service';
import { ProjectStatus } from '../projects/project.entity';
import { EscrowService } from '../escrow/escrow.service';
import { CreateEscrowDto } from '../blockchain/dto/blockchain.dto';

@Injectable()
export class ProposalsService {
  constructor(
    @InjectRepository(Proposal)
    private readonly proposalRepository: Repository<Proposal>,
    private readonly projectsService: ProjectsService,
    private readonly escrowService: EscrowService,
  ) {}

  async create(createProposalDto: CreateProposalDto, freelancerId: string): Promise<Proposal> {
    // Verify project exists and is open for proposals
    const project = await this.projectsService.findOne(createProposalDto.projectId);
    if (!project) {
      throw new NotFoundException('Project not found');
    }

    if (project.status !== 'published') {
      throw new BadRequestException('Project is not open for proposals');
    }

    // Check if freelancer already has a proposal for this project
    const existingProposal = await this.proposalRepository.findOne({
      where: {
        projectId: createProposalDto.projectId,
        freelancerId: freelancerId,
      },
    });

    if (existingProposal) {
      throw new BadRequestException('You have already submitted a proposal for this project');
    }

    const proposal = this.proposalRepository.create({
      ...createProposalDto,
      freelancerId,
      status: ProposalStatus.PENDING,
    });

    return this.proposalRepository.save(proposal);
  }

  async findAll(
    page: number = 1,
    limit: number = 10,
    projectId?: string,
    freelancerId?: string,
    status?: ProposalStatus,
    type?: ProposalType,
    minAmount?: number,
    maxAmount?: number,
  ): Promise<{ proposals: Proposal[]; total: number }> {
    const skip = (page - 1) * limit;
    const where: any = {};

    if (projectId) where.projectId = projectId;
    if (freelancerId) where.freelancerId = freelancerId;
    if (status) where.status = status;
    if (type) where.type = type;
    
    if (minAmount !== undefined || maxAmount !== undefined) {
      where.proposedAmount = Between(minAmount || 0, maxAmount || Number.MAX_SAFE_INTEGER);
    }

    const [proposals, total] = await this.proposalRepository.findAndCount({
      where,
      relations: ['project'],
      order: { createdAt: 'DESC' },
      skip,
      take: limit,
    });

    return { proposals, total };
  }

  async findOne(id: string): Promise<Proposal> {
    const proposal = await this.proposalRepository.findOne({
      where: { id },
      relations: ['project'],
    });

    if (!proposal) {
      throw new NotFoundException('Proposal not found');
    }

    return proposal;
  }

  async update(id: string, updateProposalDto: UpdateProposalDto): Promise<Proposal> {
    const proposal = await this.findOne(id);

    // Prevent updates to accepted or completed proposals
    if (proposal.status === ProposalStatus.ACCEPTED) {
      throw new BadRequestException('Cannot update an accepted proposal');
    }

    Object.assign(proposal, updateProposalDto);
    return this.proposalRepository.save(proposal);
  }

  async remove(id: string): Promise<void> {
    const proposal = await this.findOne(id);
    
    // Only allow deletion of pending proposals
    if (proposal.status !== ProposalStatus.PENDING) {
      throw new BadRequestException('Cannot delete a non-pending proposal');
    }

    await this.proposalRepository.remove(proposal);
  }

  async accept(id: string): Promise<Proposal> {
    const proposal = await this.findOne(id);

    if (proposal.status !== ProposalStatus.PENDING) {
      throw new BadRequestException('Proposal is not in pending status');
    }

    proposal.status = ProposalStatus.ACCEPTED;
    proposal.acceptedAt = new Date();

    // Update project status to in_progress
    await this.projectsService.update(proposal.projectId, {
      status: ProjectStatus.IN_PROGRESS,
      freelancerId: proposal.freelancerId,
    });

    // Create escrow for the project
    const createEscrowDto: CreateEscrowDto = {
      escrowId: `escrow_${proposal.projectId}_${Date.now()}`,
      client: proposal.project.clientId,
      developer: proposal.freelancerId,
    };

    await this.escrowService.createEscrow(createEscrowDto, proposal.projectId);

    return this.proposalRepository.save(proposal);
  }

  async reject(id: string): Promise<Proposal> {
    const proposal = await this.findOne(id);

    if (proposal.status !== ProposalStatus.PENDING) {
      throw new BadRequestException('Proposal is not in pending status');
    }

    proposal.status = ProposalStatus.REJECTED;
    proposal.rejectedAt = new Date();

    return this.proposalRepository.save(proposal);
  }

  async withdraw(id: string, freelancerId: string): Promise<Proposal> {
    const proposal = await this.findOne(id);

    // Verify the freelancer owns this proposal
    if (proposal.freelancerId !== freelancerId) {
      throw new BadRequestException('You can only withdraw your own proposals');
    }

    if (proposal.status !== ProposalStatus.PENDING) {
      throw new BadRequestException('Only pending proposals can be withdrawn');
    }

    proposal.status = ProposalStatus.WITHDRAWN;
    proposal.withdrawnAt = new Date();

    return this.proposalRepository.save(proposal);
  }

  async findByProjectId(projectId: string): Promise<Proposal[]> {
    return this.proposalRepository.find({
      where: { projectId },
      relations: ['project'],
      order: { createdAt: 'DESC' },
    });
  }

  async findByFreelancerId(freelancerId: string): Promise<Proposal[]> {
    return this.proposalRepository.find({
      where: { freelancerId },
      relations: ['project'],
      order: { createdAt: 'DESC' },
    });
  }

  async getStats(freelancerId: string): Promise<{
    total: number;
    pending: number;
    accepted: number;
    rejected: number;
    withdrawn: number;
    successRate: number;
  }> {
    const proposals = await this.findByFreelancerId(freelancerId);
    
    const total = proposals.length;
    const pending = proposals.filter(p => p.status === ProposalStatus.PENDING).length;
    const accepted = proposals.filter(p => p.status === ProposalStatus.ACCEPTED).length;
    const rejected = proposals.filter(p => p.status === ProposalStatus.REJECTED).length;
    const withdrawn = proposals.filter(p => p.status === ProposalStatus.WITHDRAWN).length;
    
    const successRate = total > 0 ? (accepted / total) * 100 : 0;

    return { total, pending, accepted, rejected, withdrawn, successRate };
  }

  async expireOldProposals(): Promise<void> {
    const expiredProposals = await this.proposalRepository.find({
      where: {
        status: ProposalStatus.PENDING,
        expiresAt: LessThanOrEqual(new Date()),
      },
    });

    for (const proposal of expiredProposals) {
      proposal.status = ProposalStatus.EXPIRED;
      await this.proposalRepository.save(proposal);
    }
  }
}