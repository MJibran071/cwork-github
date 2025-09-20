import { IsString, IsEnum, IsOptional } from 'class-validator';
import { MessageType } from '../index';

export class SendMessageDto {
  @IsString()
  workspaceId: string;

  @IsString()
  content: string;

  @IsEnum(MessageType)
  @IsOptional()
  type?: MessageType;

  @IsString()
  @IsOptional()
  parentMessageId?: string;

  @IsString()
  @IsOptional()
  fileId?: string;
}