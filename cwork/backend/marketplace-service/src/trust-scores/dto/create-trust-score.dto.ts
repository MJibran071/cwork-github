import { IsUUID, IsNumber, IsEnum, IsOptional, Min, Max } from 'class-validator';
import { UserTier } from '../../users/user-tier.enum';

export class CreateTrustScoreDto {
  @IsUUID()
  userId: string;

  @IsNumber()
  @Min(0)
  @Max(100)
  @IsOptional()
  score?: number;

  @IsEnum(UserTier)
  @IsOptional()
  tier?: UserTier;

  @IsNumber()
  @Min(0)
  @IsOptional()
  totalReviews?: number;

  @IsNumber()
  @Min(0)
  @IsOptional()
  positiveReviews?: number;

  @IsNumber()
  @Min(0)
  @IsOptional()
  negativeReviews?: number;

  @IsNumber()
  @Min(0)
  @IsOptional()
  completedProjects?: number;

  @IsNumber()
  @Min(0)
  @IsOptional()
  onTimeCompletions?: number;

  @IsNumber()
  @Min(0)
  @IsOptional()
  budgetAdherence?: number;

  @IsNumber()
  @Min(0)
  @Max(100)
  @IsOptional()
  communicationScore?: number;

  @IsNumber()
  @Min(0)
  @Max(100)
  @IsOptional()
  qualityScore?: number;

  @IsNumber()
  @Min(0)
  @Max(100)
  @IsOptional()
  professionalismScore?: number;

  @IsNumber()
  @Min(0)
  @Max(100)
  @IsOptional()
  responseTimeScore?: number;

  @IsNumber()
  @Min(0)
  @IsOptional()
  disputeCount?: number;

  @IsNumber()
  @Min(0)
  @IsOptional()
  successfulDisputeResolutions?: number;

  @IsNumber()
  @Min(0)
  @IsOptional()
  referralCount?: number;

  @IsNumber()
  @Min(0)
  @IsOptional()
  verifiedSkillsCount?: number;

  @IsNumber()
  @Min(0)
  @IsOptional()
  certificationsCount?: number;

  @IsNumber()
  @Min(0)
  @IsOptional()
  yearsOfExperience?: number;
}