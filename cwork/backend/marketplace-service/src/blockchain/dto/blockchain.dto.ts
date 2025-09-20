import { IsString, IsNumber, IsOptional, IsEnum } from 'class-validator';

export enum EscrowStatus {
  NONE = 'None',
  DEPOSITED = 'Deposited',
  RELEASED = 'Released',
  DISPUTED = 'Disputed',
  REFUNDED = 'Refunded'
}

export class CreateEscrowDto {
  @IsString()
  escrowId: string;

  @IsString()
  client: string;

  @IsString()
  developer: string;
}

export class AddMilestoneDto {
  @IsString()
  escrowId: string;

  @IsNumber()
  principalAmount: number;

  @IsString()
  @IsOptional()
  token?: string;
}

export class EscrowActionDto {
  @IsString()
  escrowId: string;

  @IsNumber()
  milestoneIndex: number;

  @IsString()
  @IsOptional()
  txRef?: string;

  @IsString()
  @IsOptional()
  reason?: string;
}

export class BlockchainConfigDto {
  @IsString()
  rpcUrl: string;

  @IsString()
  privateKey: string;

  @IsString()
  contractAddress: string;
}

export class EscrowInfoDto {
  @IsString()
  escrowId: string;

  @IsEnum(EscrowStatus)
  status: EscrowStatus;

  @IsNumber()
  totalAmount: number;

  @IsNumber()
  milestoneCount: number;
}