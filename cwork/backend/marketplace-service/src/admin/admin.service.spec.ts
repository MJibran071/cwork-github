import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { AdminService } from './admin.service';
import { Project } from '../projects/project.entity';
import { Proposal } from '../proposals/proposal.entity';
import { Escrow } from '../escrow/escrow.entity';
import { User } from '../users/user.entity';
import { Review } from '../reviews/review.entity';
import { TrustScore } from '../trust-scores/trust-score.entity';
import { ProjectStatus } from '../projects/project.entity';

describe('AdminService', () => {
  let service: AdminService;
  let projectRepository: Repository<Project>;
  let proposalRepository: Repository<Proposal>;
  let escrowRepository: Repository<Escrow>;
  let userRepository: Repository<User>;
  let reviewRepository: Repository<Review>;
  let trustScoreRepository: Repository<TrustScore>;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AdminService,
        {
          provide: getRepositoryToken(Project),
          useValue: {
            count: jest.fn(),
            find: jest.fn(),
            findAndCount: jest.fn(),
          },
        },
        {
          provide: getRepositoryToken(Proposal),
          useValue: {
            count: jest.fn(),
            find: jest.fn(),
          },
        },
        {
          provide: getRepositoryToken(Escrow),
          useValue: {
            count: jest.fn(),
            find: jest.fn(),
          },
        },
        {
          provide: getRepositoryToken(User),
          useValue: {
            count: jest.fn(),
            find: jest.fn(),
          },
        },
        {
          provide: getRepositoryToken(Review),
          useValue: {
            find: jest.fn(),
          },
        },
        {
          provide: getRepositoryToken(TrustScore),
          useValue: {
            find: jest.fn(),
          },
        },
      ],
    }).compile();

    service = module.get<AdminService>(AdminService);
    projectRepository = module.get<Repository<Project>>(getRepositoryToken(Project));
    proposalRepository = module.get<Repository<Proposal>>(getRepositoryToken(Proposal));
    escrowRepository = module.get<Repository<Escrow>>(getRepositoryToken(Escrow));
    userRepository = module.get<Repository<User>>(getRepositoryToken(User));
    reviewRepository = module.get<Repository<Review>>(getRepositoryToken(Review));
    trustScoreRepository = module.get<Repository<TrustScore>>(getRepositoryToken(TrustScore));
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('getDashboardStats', () => {
    it('should return dashboard statistics', async () => {
      const mockProjectsCount = 10;
      const mockProposalsCount = 20;
      const mockEscrowsCount = 5;
      const mockUsersCount = 15;
      const mockEscrows = [
        { feeAmount: 100, isDisputed: false },
        { feeAmount: 200, isDisputed: true },
      ];
      const mockActiveProjects = 3;
      const mockCompletedProjects = 2;
      const mockTrustScores = [{ score: 80 }, { score: 90 }];

      jest.spyOn(projectRepository, 'count').mockResolvedValueOnce(mockProjectsCount);
      jest.spyOn(proposalRepository, 'count').mockResolvedValueOnce(mockProposalsCount);
      jest.spyOn(escrowRepository, 'count').mockResolvedValueOnce(mockEscrowsCount);
      jest.spyOn(userRepository, 'count').mockResolvedValueOnce(mockUsersCount);
      jest.spyOn(escrowRepository, 'find').mockResolvedValueOnce(mockEscrows as any);
      jest.spyOn(projectRepository, 'count').mockResolvedValueOnce(mockActiveProjects);
      jest.spyOn(projectRepository, 'count').mockResolvedValueOnce(mockCompletedProjects);
      jest.spyOn(trustScoreRepository, 'find').mockResolvedValueOnce(mockTrustScores as any);

      const result = await service.getDashboardStats();

      expect(result).toEqual({
        totalProjects: mockProjectsCount,
        totalProposals: mockProposalsCount,
        totalEscrows: mockEscrowsCount,
        totalUsers: mockUsersCount,
        totalRevenue: 300, // 100 + 200
        activeProjects: mockActiveProjects,
        completedProjects: mockCompletedProjects,
        disputedEscrows: 1, // one with isDisputed: true
        averageTrustScore: 85, // (80 + 90) / 2
      });
    });
  });

  describe('getRevenueStats', () => {
    it('should return revenue statistics with date range', async () => {
      const mockEscrows = [
        { feeAmount: 100, totalAmount: 1000, createdAt: new Date('2024-01-01') },
        { feeAmount: 200, totalAmount: 2000, createdAt: new Date('2024-01-02') },
      ];

      jest.spyOn(escrowRepository, 'find').mockResolvedValueOnce(mockEscrows as any);

      const startDate = new Date('2024-01-01');
      const endDate = new Date('2024-01-02');
      const result = await service.getRevenueStats(startDate, endDate);

      expect(result.totalRevenue).toBe(300);
      expect(result.platformFees).toBe(300);
      expect(result.escrowAmounts).toBe(3000);
      expect(result.dailyRevenue).toBeDefined();
      expect(result.monthlyRevenue).toBeDefined();
    });
  });

  describe('getUserStats', () => {
    it('should return user statistics', async () => {
      const mockUsers = [
        { isActive: true, role: 'client', createdAt: new Date() },
        { isActive: false, role: 'freelancer', createdAt: new Date(Date.now() - 8 * 24 * 60 * 60 * 1000) }, // 8 days ago
        { isActive: true, role: 'admin', createdAt: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000) }, // 3 days ago
      ];

      jest.spyOn(userRepository, 'find').mockResolvedValueOnce(mockUsers as any);

      const result = await service.getUserStats();

      expect(result.totalUsers).toBe(3);
      expect(result.activeUsers).toBe(2);
      expect(result.newUsersThisWeek).toBe(2); // two created within last 7 days
      expect(result.userGrowthRate).toBeCloseTo(66.67, 1);
      expect(result.userDistribution).toEqual({
        clients: 1,
        freelancers: 1,
        admins: 1,
      });
    });
  });

  describe('getProjectStats', () => {
    it('should return project statistics', async () => {
      const mockProjects = [
        { status: ProjectStatus.PUBLISHED, type: 'fixed_price', budget: 1000 },
        { status: ProjectStatus.COMPLETED, type: 'hourly', budget: 2000 },
        { status: ProjectStatus.CANCELLED, type: 'milestone', budget: 3000 },
        { status: ProjectStatus.DISPUTED, type: 'fixed_price', budget: 4000 },
      ];

      jest.spyOn(projectRepository, 'find').mockResolvedValueOnce(mockProjects as any);

      const result = await service.getProjectStats();

      expect(result.totalProjects).toBe(4);
      expect(result.publishedProjects).toBe(1);
      expect(result.completedProjects).toBe(1);
      expect(result.cancelledProjects).toBe(1);
      expect(result.disputedProjects).toBe(1);
      expect(result.averageBudget).toBe(2500); // (1000+2000+3000+4000)/4
      expect(result.projectDistributionByType).toEqual({
        fixed_price: 2,
        hourly: 1,
        milestone: 1,
      });
    });
  });
});