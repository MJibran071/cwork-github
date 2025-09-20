import { Controller, Post, Body, Param, Get, UseGuards, Req } from '@nestjs/common';
import { AIIntegrationService } from './ai-integration.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Request } from 'express';

@Controller('ai')
@UseGuards(JwtAuthGuard)
export class AIIntegrationController {
  constructor(private readonly aiService: AIIntegrationService) {}

  @Post('workspaces/:workspaceId/message-suggestions')
  async getMessageSuggestions(
    @Param('workspaceId') workspaceId: string,
    @Body() body: { currentMessage: string },
    @Req() req: Request,
  ) {
    const userId = (req.user as any).id;
    // In a real implementation, we would fetch message history from the database
    const messageHistory = []; // Placeholder for actual message history
    return this.aiService.generateMessageSuggestions(workspaceId, messageHistory, body.currentMessage);
  }

  @Post('projects/:projectId/analysis')
  async analyzeProjectRequirements(
    @Param('projectId') projectId: string,
    @Req() req: Request,
  ) {
    const userId = (req.user as any).id;
    // In a real implementation, we would fetch the project from the database
    const project = {} as any; // Placeholder for actual project
    return this.aiService.analyzeProjectRequirements(project);
  }

  @Post('proposals/:proposalId/enhancements')
  async enhanceProposal(
    @Param('proposalId') proposalId: string,
    @Req() req: Request,
  ) {
    const userId = (req.user as any).id;
    // In a real implementation, we would fetch the proposal from the database
    const proposal = {} as any; // Placeholder for actual proposal
    return this.aiService.generateProposalEnhancements(proposal);
  }

  @Post('workspaces/:workspaceId/sentiment')
  async analyzeSentiment(
    @Param('workspaceId') workspaceId: string,
    @Req() req: Request,
  ) {
    const userId = (req.user as any).id;
    // In a real implementation, we would fetch messages from the database
    const messages = []; // Placeholder for actual messages
    return this.aiService.detectSentiment(messages);
  }

  @Post('workspaces/:workspaceId/task-suggestions')
  async getTaskSuggestions(
    @Param('workspaceId') workspaceId: string,
    @Req() req: Request,
  ) {
    const userId = (req.user as any).id;
    // In a real implementation, we would fetch the workspace from the database
    const workspace = {} as any; // Placeholder for actual workspace
    return this.aiService.generateTaskSuggestions(workspace);
  }
}