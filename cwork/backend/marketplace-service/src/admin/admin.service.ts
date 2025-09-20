import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Between, MoreThanOrEqual, LessThanOrEqual } from 'typeorm';
import { Project, ProjectStatus } from '../projects/project.entity';
import { Proposal, ProposalStatus } from '../proposals/proposal.entity';
import { Escrow } from '../escrow/escrow.entity';
import { EscrowStatus } from '../blockchain/dto/blockchain.dto';
import { User } from '../users/user.entity';
import { Review } from '../reviews/review.entity';
import { TrustScore } from '../trust-scores/trust-score.entity';

export interface DashboardStats {
  totalProjects: number;
  totalProposals: number;
  totalEscrows: number;
  totalUsers: number;
  totalRevenue: number;
  activeProjects: number;
  completedProjects: number;
  disputedEscrows: number;
  averageTrustScore: number;
}

export interface RevenueStats {
  totalRevenue: number;
  platformFees: number;
  escrowAmounts: number;
  dailyRevenue: Array<{ date: string; revenue: number }>;
  monthlyRevenue: Array<{ month: string; revenue: number }>;
}

export interface UserStats {
  totalUsers: number;
  activeUsers: number;
  newUsersThisWeek: number;
  userGrowthRate: number;
  userDistribution: {
    clients: number;
    freelancers: number;
    admins: number;
  };
}

export interface ProjectStats {
  totalProjects: number;
  publishedProjects: number;
  completedProjects: number;
  cancelledProjects: number;
  disputedProjects: number;
  averageBudget: number;
  projectDistributionByType: {
    fixed_price: number;
    hourly: number;
    milestone: number;
  };
}

@Injectable()
export class AdminService {
  constructor(
    @InjectRepository(Project)
    private readonly projectRepository: Repository<Project>,
    @InjectRepository(Proposal)
    private readonly proposalRepository: Repository<Proposal>,
    @InjectRepository(Escrow)
    private readonly escrowRepository: Repository<Escrow>,
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    @InjectRepository(Review)
    private readonly reviewRepository: Repository<Review>,
    @InjectRepository(TrustScore)
    private readonly trustScoreRepository: Repository<TrustScore>,
  ) {}

  async getDashboardStats(): Promise<DashboardStats> {
    const [
      totalProjects,
      totalProposals,
      totalEscrows,
      totalUsers,
      escrows,
      activeProjects,
      completedProjects,
      trustScores,
    ] = await Promise.all([
      this.projectRepository.count({ where: { isDeleted: false } }),
      this.proposalRepository.count(),
      this.escrowRepository.count(),
      this.userRepository.count(),
      this.escrowRepository.find(),
      this.projectRepository.count({ where: { status: ProjectStatus.IN_PROGRESS } }),
      this.projectRepository.count({ where: { status: ProjectStatus.COMPLETED } }),
      this.trustScoreRepository.find(),
    ]);

    const totalRevenue = escrows.reduce((sum, escrow) => sum + escrow.feeAmount, 0);
    const disputedEscrows = escrows.filter(escrow => escrow.isDisputed).length;
    const averageTrustScore = trustScores.length > 0 
      ? trustScores.reduce((sum, score) => sum + score.score, 0) / trustScores.length 
      : 0;

    return {
      totalProjects,
      totalProposals,
      totalEscrows,
      totalUsers,
      totalRevenue,
      activeProjects,
      completedProjects,
      disputedEscrows,
      averageTrustScore,
    };
  }

  async getRevenueStats(startDate?: Date, endDate?: Date): Promise<RevenueStats> {
    const where: any = {};
    if (startDate && endDate) {
      where.createdAt = Between(startDate, endDate);
    }

    const escrows = await this.escrowRepository.find({ where });

    const totalRevenue = escrows.reduce((sum, escrow) => sum + escrow.feeAmount, 0);
    const platformFees = totalRevenue;
    const escrowAmounts = escrows.reduce((sum, escrow) => sum + escrow.totalAmount, 0);

    // Mock daily and monthly revenue data (in a real implementation, you'd aggregate from database)
    const dailyRevenue = [
      { date: '2024-01-01', revenue: 1500 },
      { date: '2024-01-02', revenue: 2300 },
      { date: '2024-01-03', revenue: 1800 },
    ];

    const monthlyRevenue = [
      { month: 'January 2024', revenue: 45000 },
      { month: 'February 2024', revenue: 52000 },
      { month: 'March 2024', revenue: 48000 },
    ];

    return {
      totalRevenue,
      platformFees,
      escrowAmounts,
      dailyRevenue,
      monthlyRevenue,
    };
  }

  async getUserStats(): Promise<UserStats> {
    const users = await this.userRepository.find();
    const activeUsers = users.filter(user => user.isActive).length;
    const newUsersThisWeek = users.filter(user => 
      user.createdAt && new Date(user.createdAt).getTime() > Date.now() - 7 * 24 * 60 * 60 * 1000
    ).length;

    const userDistribution = {
      clients: users.filter(user => user.role === 'client').length,
      freelancers: users.filter(user => user.role === 'freelancer').length,
      admins: users.filter(user => user.role === 'admin').length,
    };

    const userGrowthRate = newUsersThisWeek / users.length * 100;

    return {
      totalUsers: users.length,
      activeUsers,
      newUsersThisWeek,
      userGrowthRate,
      userDistribution,
    };
  }

  async getProjectStats(): Promise<ProjectStats> {
    const projects = await this.projectRepository.find({ where: { isDeleted: false } });

    const publishedProjects = projects.filter(p => p.status === ProjectStatus.PUBLISHED).length;
    const completedProjects = projects.filter(p => p.status === ProjectStatus.COMPLETED).length;
    const cancelledProjects = projects.filter(p => p.status === ProjectStatus.CANCELLED).length;
    const disputedProjects = projects.filter(p => p.status === ProjectStatus.DISPUTED).length;

    const totalBudget = projects.reduce((sum, project) => sum + (project.budget || 0), 0);
    const averageBudget = projects.length > 0 ? totalBudget / projects.length : 0;

    const projectDistributionByType = {
      fixed_price: projects.filter(p => p.type === 'fixed_price').length,
      hourly: projects.filter(p => p.type === 'hourly').length,
      milestone: projects.filter(p => p.type === 'milestone').length,
    };

    return {
      totalProjects: projects.length,
      publishedProjects,
      completedProjects,
      cancelledProjects,
      disputedProjects,
      averageBudget,
      projectDistributionByType,
    };
  }

  async getRecentActivity(limit: number = 10): Promise<any[]> {
    const [recentProjects, recentProposals, recentEscrows] = await Promise.all([
      this.projectRepository.find({
        order: { createdAt: 'DESC' },
        take: limit,
        relations: ['category'],
      }),
      this.proposalRepository.find({
        order: { createdAt: 'DESC' },
        take: limit,
        relations: ['project'],
      }),
      this.escrowRepository.find({
        order: { createdAt: 'DESC' },
        take: limit,
      }),
    ]);

    return [
      ...recentProjects.map(project => ({
        type: 'project',
        id: project.id,
        title: project.title,
        createdAt: project.createdAt,
        status: project.status,
      })),
      ...recentProposals.map(proposal => ({
        type: 'proposal',
        id: proposal.id,
        projectTitle: proposal.project?.title,
        createdAt: proposal.createdAt,
        status: proposal.status,
      })),
      ...recentEscrows.map(escrow => ({
        type: 'escrow',
        id: escrow.id,
        amount: escrow.totalAmount,
        createdAt: escrow.createdAt,
        status: escrow.status,
      })),
    ].sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime())
     .slice(0, limit);
  }

  async getSystemHealth(): Promise<{
    database: { status: string; responseTime: number };
    blockchain: { status: string; lastBlock: number };
    api: { status: string; uptime: number };
  }> {
    // Mock system health data
    return {
      database: {
        status: 'online',
        responseTime: 45, // ms
      },
      blockchain: {
        status: 'online',
        lastBlock: 19283746,
      },
      api: {
        status: 'online',
        uptime: Math.floor(process.uptime()),
      },
    };
  }
}