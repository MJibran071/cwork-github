import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AdminController } from './admin.controller';
import { AdminService } from './admin.service';
import { Project } from '../projects/project.entity';
import { Proposal } from '../proposals/proposal.entity';
import { Escrow } from '../escrow/escrow.entity';
import { User } from '../users/user.entity';
import { Review } from '../reviews/review.entity';
import { TrustScore } from '../trust-scores/trust-score.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([Project, Proposal, Escrow, User, Review, TrustScore]),
  ],
  controllers: [AdminController],
  providers: [AdminService],
  exports: [AdminService],
})
export class AdminModule {}