import { PartialType } from '@nestjs/mapped-types';
import { CreateTrustScoreDto } from './create-trust-score.dto';

export class UpdateTrustScoreDto extends PartialType(CreateTrustScoreDto) {}