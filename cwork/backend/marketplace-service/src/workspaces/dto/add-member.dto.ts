import { IsString, IsEnum } from 'class-validator';
import { MemberRole } from '../index';

export class AddMemberDto {
  @IsString()
  workspaceId: string;

  @IsString()
  userId: string;

  @IsEnum(MemberRole)
  role: MemberRole;
}