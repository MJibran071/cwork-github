import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ProjectsModule } from './projects/projects.module';
import { ProposalsModule } from './proposals/proposals.module';
import { CategoriesModule } from './categories/categories.module';
import { SkillsModule } from './skills/skills.module';
import { ReviewsModule } from './reviews/reviews.module';
import { TrustScoresModule } from './trust-scores/trust-scores.module';
import { WorkspacesModule } from './workspaces/workspaces.module';
import { AIIntegrationModule } from './ai-integration/ai-integration.module';
import { BlockchainModule } from './blockchain/blockchain.module';
import { AdminModule } from './admin/admin.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
    }),
    TypeOrmModule.forRootAsync({
      useFactory: () => ({
        type: 'sqlite',
        database: ':memory:',
        entities: [__dirname + '/**/*.entity{.ts,.js}'],
        synchronize: true,
        logging: process.env.NODE_ENV === 'development',
      }),
    }),
    ProjectsModule,
    ProposalsModule,
    CategoriesModule,
    SkillsModule,
    ReviewsModule,
    TrustScoresModule,
    WorkspacesModule,
    AIIntegrationModule,
    BlockchainModule,
    AdminModule,
  ],
  controllers: [],
  providers: [],
})
export class AppModule {}