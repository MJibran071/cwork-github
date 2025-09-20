import { IsString, IsOptional, IsBoolean, IsEnum } from 'class-validator';
import { WorkspaceType } from '../index';

export class UpdateWorkspaceDto {
  @IsString()
  @IsOptional()
  name?: string;

  @IsString()
  @IsOptional()
  description?: string;

  @IsEnum(WorkspaceType)
  @IsOptional()
  type?: WorkspaceType;

  @IsBoolean()
  @IsOptional()
  isPublic?: boolean;
}