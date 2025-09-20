import { Module } from '@nestjs/common';
import { HttpModule } from '@nestjs/axios';
import { AIIntegrationService } from './ai-integration.service';
import { AIIntegrationController } from './ai-integration.controller';
import { TypeOrmModule } from '@nestjs/typeorm';
import { WorkspaceMessage } from '../workspaces/workspace-message.entity';
import { Workspace } from '../workspaces/workspace.entity';
import { Project } from '../projects/project.entity';
import { Proposal } from '../proposals/proposal.entity';

@Module({
  imports: [
    HttpModule,
    TypeOrmModule.forFeature([WorkspaceMessage, Workspace, Project, Proposal]),
  ],
  providers: [AIIntegrationService],
  controllers: [AIIntegrationController],
  exports: [AIIntegrationService],
})
export class AIIntegrationModule {}