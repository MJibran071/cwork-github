import { IsString, IsOptional, IsBoolean, IsEnum } from 'class-validator';
import { WorkspaceType } from '../workspace-type.enum';

export class CreateWorkspaceDto {
  @IsString()
  name: string;

  @IsString()
  @IsOptional()
  description?: string;

  @IsEnum(WorkspaceType)
  type: WorkspaceType;

  @IsBoolean()
  @IsOptional()
  isPublic?: boolean;

  @IsString()
  @IsOptional()
  projectId?: string;
}