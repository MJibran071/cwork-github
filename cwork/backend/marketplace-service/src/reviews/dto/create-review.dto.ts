import { IsString, IsNumber, IsEnum, IsOptional, IsBoolean, IsObject, Min, Max } from 'class-validator';
import { ReviewType } from '../review.entity';

export class CreateReviewDto {
  @IsString()
  projectId: string;

  @IsString()
  reviewedUserId: string;

  @IsEnum(ReviewType)
  type: ReviewType;

  @IsNumber()
  @Min(1)
  @Max(5)
  rating: number;

  @IsString()
  title: string;

  @IsString()
  content: string;

  @IsOptional()
  @IsObject()
  criteriaScores?: {
    quality?: number;
    communication?: number;
    professionalism?: number;
    deadline?: number;
    budget?: number;
  };

  @IsOptional()
  @IsBoolean()
  isVerified?: boolean;

  @IsOptional()
  @IsObject()
  metadata?: {
    projectCompletion?: boolean;
    paymentVerified?: boolean;
    responseTime?: number;
    revisionCount?: number;
  };
}