import { IsString, IsOptional, IsBoolean, IsNumber, IsObject, IsEnum } from 'class-validator';

export class UpdateSkillDto {
  @IsOptional()
  @IsString()
  name?: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsString()
  icon?: string;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;

  @IsOptional()
  @IsNumber()
  sortOrder?: number;

  @IsOptional()
  @IsString()
  categoryId?: string;

  @IsOptional()
  @IsObject()
  metadata?: {
    averageRate?: number;
    demandLevel?: 'low' | 'medium' | 'high';
    trending?: boolean;
    relatedSkills?: string[];
  };
}