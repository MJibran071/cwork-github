import { IsString, IsEnum, IsInt, IsOptional, IsBoolean } from 'class-validator';
import { FileType } from '../workspace-file.entity';

export class UploadFileDto {
  @IsString()
  workspaceId: string;

  @IsString()
  fileName: string;

  @IsString()
  fileUrl: string;

  @IsEnum(FileType)
  fileType: FileType;

  @IsInt()
  fileSize: number;

  @IsString()
  @IsOptional()
  mimeType?: string;

  @IsString()
  @IsOptional()
  description?: string;

  @IsBoolean()
  @IsOptional()
  isPublic?: boolean;
}