import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { TrustScoresService } from './trust-scores.service';
import { TrustScoresController } from './trust-scores.controller';
import { TrustScore } from './trust-score.entity';

@Module({
  imports: [TypeOrmModule.forFeature([TrustScore])],
  controllers: [TrustScoresController],
  providers: [TrustScoresService],
  exports: [TrustScoresService],
})
export class TrustScoresModule {}