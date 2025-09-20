import { Controller, Get, Post, Body, Patch, Param, Delete, Query, UseGuards, Req } from '@nestjs/common';
import { TrustScoresService } from './trust-scores.service';
import { CreateTrustScoreDto } from './dto/create-trust-score.dto';
import { UpdateTrustScoreDto } from './dto/update-trust-score.dto';
import { TrustScore } from './trust-score.entity';
import { UserTier } from '../users/user-tier.enum';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('trust-scores')
@UseGuards(JwtAuthGuard)
export class TrustScoresController {
  constructor(private readonly trustScoresService: TrustScoresService) {}

  @Post()
  async create(@Body() createTrustScoreDto: CreateTrustScoreDto): Promise<TrustScore> {
    return this.trustScoresService.create(createTrustScoreDto);
  }

  @Get()
  async findAll(): Promise<TrustScore[]> {
    return this.trustScoresService.findAll();
  }

  @Get(':id')
  async findOne(@Param('id') id: string): Promise<TrustScore> {
    return this.trustScoresService.findOne(id);
  }

  @Get('user/:userId')
  async findByUserId(@Param('userId') userId: string): Promise<TrustScore> {
    return this.trustScoresService.findByUserId(userId);
  }

  @Patch(':id')
  async update(@Param('id') id: string, @Body() updateTrustScoreDto: UpdateTrustScoreDto): Promise<TrustScore> {
    return this.trustScoresService.update(id, updateTrustScoreDto);
  }

  @Delete(':id')
  async remove(@Param('id') id: string): Promise<void> {
    return this.trustScoresService.remove(id);
  }

  @Post('calculate/:userId')
  async calculateTrustScore(@Param('userId') userId: string): Promise<TrustScore> {
    return this.trustScoresService.calculateTrustScore(userId);
  }

  @Post('update-from-review/:userId')
  async updateFromReview(
    @Param('userId') userId: string,
    @Body('rating') rating: number,
    @Body('criteriaScores') criteriaScores?: any,
  ): Promise<TrustScore> {
    return this.trustScoresService.updateFromReview(userId, rating, criteriaScores);
  }

  @Post('update-from-project/:userId')
  async updateFromProjectCompletion(
    @Param('userId') userId: string,
    @Body('onTime') onTime: boolean,
    @Body('withinBudget') withinBudget: boolean,
  ): Promise<TrustScore> {
    return this.trustScoresService.updateFromProjectCompletion(userId, onTime, withinBudget);
  }

  @Post('update-from-dispute/:userId')
  async updateFromDispute(
    @Param('userId') userId: string,
    @Body('resolvedSuccessfully') resolvedSuccessfully: boolean,
  ): Promise<TrustScore> {
    return this.trustScoresService.updateFromDispute(userId, resolvedSuccessfully);
  }

  @Get('leaderboard/top')
  async getLeaderboard(@Query('limit') limit: number = 10): Promise<TrustScore[]> {
    return this.trustScoresService.getLeaderboard(limit);
  }

  @Get('stats/overall')
  async getStats(): Promise<{
    totalUsers: number;
    averageScore: number;
    tierDistribution: { [key in UserTier]: number };
  }> {
    return this.trustScoresService.getStats();
  }
}