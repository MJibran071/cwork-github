import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { TrustScore } from './trust-score.entity';
import { CreateTrustScoreDto } from './dto/create-trust-score.dto';
import { UpdateTrustScoreDto } from './dto/update-trust-score.dto';
import { UserTier } from '../users/user-tier.enum';

@Injectable()
export class TrustScoresService {
  constructor(
    @InjectRepository(TrustScore)
    private readonly trustScoreRepository: Repository<TrustScore>,
  ) {}

  async create(createTrustScoreDto: CreateTrustScoreDto): Promise<TrustScore> {
    const trustScore = this.trustScoreRepository.create(createTrustScoreDto);
    return this.trustScoreRepository.save(trustScore);
  }

  async findAll(): Promise<TrustScore[]> {
    return this.trustScoreRepository.find();
  }

  async findOne(id: string): Promise<TrustScore> {
    const trustScore = await this.trustScoreRepository.findOne({ where: { id } });
    if (!trustScore) {
      throw new NotFoundException('Trust score not found');
    }
    return trustScore;
  }

  async findByUserId(userId: string): Promise<TrustScore> {
    const trustScore = await this.trustScoreRepository.findOne({ where: { userId } });
    if (!trustScore) {
      // Create a default trust score if not found
      return this.createDefaultTrustScore(userId);
    }
    return trustScore;
  }

  async update(id: string, updateTrustScoreDto: UpdateTrustScoreDto): Promise<TrustScore> {
    const trustScore = await this.findOne(id);
    Object.assign(trustScore, updateTrustScoreDto);
    return this.trustScoreRepository.save(trustScore);
  }

  async remove(id: string): Promise<void> {
    const trustScore = await this.findOne(id);
    await this.trustScoreRepository.remove(trustScore);
  }

  async calculateTrustScore(userId: string): Promise<TrustScore> {
    let trustScore = await this.findByUserId(userId);
    
    // Calculate overall score based on various factors
    const calculatedScore = this.calculateOverallScore(trustScore);
    trustScore.score = calculatedScore;
    trustScore.tier = this.determineTier(calculatedScore);
    trustScore.lastScoreUpdate = new Date();
    
    return this.trustScoreRepository.save(trustScore);
  }

  private calculateOverallScore(trustScore: TrustScore): number {
    let totalScore = 0;
    let weightSum = 0;

    // Review-based factors (40% weight)
    if (trustScore.totalReviews > 0) {
      const reviewScore = (trustScore.positiveReviews / trustScore.totalReviews) * 100;
      totalScore += reviewScore * 0.4;
      weightSum += 0.4;
    }

    // Project completion factors (30% weight)
    if (trustScore.completedProjects > 0) {
      const onTimeRate = (trustScore.onTimeCompletions / trustScore.completedProjects) * 100;
      const budgetRate = (trustScore.budgetAdherence / trustScore.completedProjects) * 100;
      const projectScore = (onTimeRate + budgetRate) / 2;
      totalScore += projectScore * 0.3;
      weightSum += 0.3;
    }

    // Quality metrics (20% weight)
    const qualityMetrics = [
      trustScore.communicationScore,
      trustScore.qualityScore,
      trustScore.professionalismScore,
      trustScore.responseTimeScore
    ].filter(score => score > 0);

    if (qualityMetrics.length > 0) {
      const avgQualityScore = qualityMetrics.reduce((sum, score) => sum + score, 0) / qualityMetrics.length;
      totalScore += avgQualityScore * 0.2;
      weightSum += 0.2;
    }

    // Additional factors (10% weight)
    let additionalScore = 0;
    if (trustScore.successfulDisputeResolutions > 0) {
      const disputeResolutionRate = (trustScore.successfulDisputeResolutions / Math.max(trustScore.disputeCount, 1)) * 100;
      additionalScore += disputeResolutionRate * 0.05;
    }
    
    additionalScore += Math.min(trustScore.verifiedSkillsCount * 2, 20) * 0.025;
    additionalScore += Math.min(trustScore.certificationsCount * 5, 20) * 0.025;
    additionalScore += Math.min(trustScore.yearsOfExperience * 3, 30) * 0.025;
    additionalScore += Math.min(trustScore.referralCount * 1, 10) * 0.025;

    totalScore += additionalScore;
    weightSum += 0.1;

    // Normalize to 0-100 scale
    return weightSum > 0 ? Math.min(Math.max(totalScore / weightSum, 0), 100) : 0;
  }

  private determineTier(score: number): UserTier {
    if (score >= 90) return UserTier.PLATINUM;
    if (score >= 80) return UserTier.GOLD;
    if (score >= 70) return UserTier.SILVER;
    return UserTier.BRONZE;
  }

  private createDefaultTrustScore(userId: string): TrustScore {
    return this.trustScoreRepository.create({
      userId,
      score: 0,
      tier: UserTier.BRONZE,
      totalReviews: 0,
      positiveReviews: 0,
      negativeReviews: 0,
      completedProjects: 0,
      onTimeCompletions: 0,
      budgetAdherence: 0,
      communicationScore: 0,
      qualityScore: 0,
      professionalismScore: 0,
      responseTimeScore: 0,
      disputeCount: 0,
      successfulDisputeResolutions: 0,
      referralCount: 0,
      verifiedSkillsCount: 0,
      certificationsCount: 0,
      yearsOfExperience: 0,
      isActive: true,
    });
  }

  async updateFromReview(userId: string, rating: number, criteriaScores?: any): Promise<TrustScore> {
    let trustScore = await this.findByUserId(userId);
    
    trustScore.totalReviews += 1;
    if (rating >= 4) {
      trustScore.positiveReviews += 1;
    } else if (rating <= 2) {
      trustScore.negativeReviews += 1;
    }

    // Update criteria scores if provided
    if (criteriaScores) {
      if (criteriaScores.communication) {
        trustScore.communicationScore = this.updateAverageScore(
          trustScore.communicationScore,
          trustScore.totalReviews,
          criteriaScores.communication
        );
      }
      if (criteriaScores.quality) {
        trustScore.qualityScore = this.updateAverageScore(
          trustScore.qualityScore,
          trustScore.totalReviews,
          criteriaScores.quality
        );
      }
      if (criteriaScores.professionalism) {
        trustScore.professionalismScore = this.updateAverageScore(
          trustScore.professionalismScore,
          trustScore.totalReviews,
          criteriaScores.professionalism
        );
      }
      if (criteriaScores.deadline) {
        trustScore.responseTimeScore = this.updateAverageScore(
          trustScore.responseTimeScore,
          trustScore.totalReviews,
          criteriaScores.deadline
        );
      }
    }

    return this.trustScoreRepository.save(trustScore);
  }

  private updateAverageScore(currentAverage: number, totalCount: number, newScore: number): number {
    return ((currentAverage * (totalCount - 1)) + newScore) / totalCount;
  }

  async updateFromProjectCompletion(userId: string, onTime: boolean, withinBudget: boolean): Promise<TrustScore> {
    let trustScore = await this.findByUserId(userId);
    
    trustScore.completedProjects += 1;
    if (onTime) trustScore.onTimeCompletions += 1;
    if (withinBudget) trustScore.budgetAdherence += 1;

    return this.trustScoreRepository.save(trustScore);
  }

  async updateFromDispute(userId: string, resolvedSuccessfully: boolean): Promise<TrustScore> {
    let trustScore = await this.findByUserId(userId);
    
    trustScore.disputeCount += 1;
    if (resolvedSuccessfully) trustScore.successfulDisputeResolutions += 1;

    return this.trustScoreRepository.save(trustScore);
  }

  async getLeaderboard(limit: number = 10): Promise<TrustScore[]> {
    return this.trustScoreRepository.find({
      where: { isActive: true },
      order: { score: 'DESC' },
      take: limit,
    });
  }

  async getStats(): Promise<{
    totalUsers: number;
    averageScore: number;
    tierDistribution: { [key in UserTier]: number };
  }> {
    const allScores = await this.findAll();
    const totalUsers = allScores.length;
    const averageScore = totalUsers > 0 
      ? allScores.reduce((sum, score) => sum + score.score, 0) / totalUsers 
      : 0;
    
    const tierDistribution = {
      [UserTier.BRONZE]: 0,
      [UserTier.SILVER]: 0,
      [UserTier.GOLD]: 0,
      [UserTier.PLATINUM]: 0,
    };

    allScores.forEach(score => {
      tierDistribution[score.tier]++;
    });

    return { totalUsers, averageScore, tierDistribution };
  }
}