import { Injectable } from '@nestjs/common';
import { HttpService } from '@nestjs/axios';
import { ConfigService } from '@nestjs/config';
import { WorkspaceMessage } from '../workspaces/workspace-message.entity';
import { Workspace } from '../workspaces/workspace.entity';
import { Project } from '../projects/project.entity';
import { Proposal } from '../proposals/proposal.entity';

export interface AISuggestion {
  type: 'message' | 'task' | 'reminder' | 'insight';
  content: string;
  confidence: number;
  context: any;
}

export interface AIChatResponse {
  message: string;
  suggestions?: AISuggestion[];
  actions?: string[];
}

@Injectable()
export class AIIntegrationService {
  private readonly apiKey: string;
  private readonly baseUrl: string;

  constructor(
    private readonly configService: ConfigService,
    private readonly httpService: HttpService,
  ) {
    this.apiKey = this.configService.get('OPENAI_API_KEY');
    this.baseUrl = this.configService.get('AI_SERVICE_URL') || 'https://api.openai.com/v1';
  }

  async generateMessageSuggestions(
    workspaceId: string,
    messageHistory: WorkspaceMessage[],
    currentMessage: string,
  ): Promise<AISuggestion[]> {
    try {
      const prompt = this.buildMessageSuggestionPrompt(messageHistory, currentMessage);
      const response = await this.callAIAPI(prompt, 0.7);
      
      return this.parseAISuggestions(response);
    } catch (error) {
      console.error('AI suggestion generation failed:', error);
      return [];
    }
  }

  async analyzeProjectRequirements(project: Project): Promise<AISuggestion[]> {
    try {
      const prompt = this.buildProjectAnalysisPrompt(project);
      const response = await this.callAIAPI(prompt, 0.8);
      
      return this.parseAISuggestions(response);
    } catch (error) {
      console.error('Project analysis failed:', error);
      return [];
    }
  }

  async generateProposalEnhancements(proposal: Proposal): Promise<AISuggestion[]> {
    try {
      const prompt = this.buildProposalEnhancementPrompt(proposal);
      const response = await this.callAIAPI(prompt, 0.8);
      
      return this.parseAISuggestions(response);
    } catch (error) {
      console.error('Proposal enhancement failed:', error);
      return [];
    }
  }

  async detectSentiment(messages: WorkspaceMessage[]): Promise<{ sentiment: string; score: number }> {
    try {
      const prompt = this.buildSentimentAnalysisPrompt(messages);
      const response = await this.callAIAPI(prompt, 0.9);
      
      return this.parseSentimentResponse(response);
    } catch (error) {
      console.error('Sentiment analysis failed:', error);
      return { sentiment: 'neutral', score: 0.5 };
    }
  }

  async generateTaskSuggestions(workspace: Workspace): Promise<AISuggestion[]> {
    try {
      const prompt = this.buildTaskSuggestionPrompt(workspace);
      const response = await this.callAIAPI(prompt, 0.7);
      
      return this.parseAISuggestions(response);
    } catch (error) {
      console.error('Task suggestion generation failed:', error);
      return [];
    }
  }

  private async callAIAPI(prompt: string, temperature: number): Promise<any> {
    // For now, mock the AI response since we don't have actual API keys
    // In production, this would call the actual AI service
    return this.mockAIResponse(prompt);
  }

  private mockAIResponse(prompt: string): any {
    // Simple mock responses based on prompt content
    if (prompt.includes('message suggestion')) {
      return {
        choices: [{
          message: {
            content: JSON.stringify([
              {
                type: 'message',
                content: 'That sounds like a great approach!',
                confidence: 0.85,
                context: { tone: 'positive' }
              },
              {
                type: 'message', 
                content: 'Have you considered alternative solutions?',
                confidence: 0.7,
                context: { tone: 'suggestive' }
              }
            ])
          }
        }]
      };
    }
    
    if (prompt.includes('project analysis')) {
      return {
        choices: [{
          message: {
            content: JSON.stringify([
              {
                type: 'insight',
                content: 'This project requires expertise in React and Node.js based on the description.',
                confidence: 0.9,
                context: { skills: ['React', 'Node.js'] }
              }
            ])
          }
        }]
      };
    }

    return {
      choices: [{
        message: {
          content: JSON.stringify([])
        }
      }]
    };
  }

  private buildMessageSuggestionPrompt(messages: WorkspaceMessage[], currentMessage: string): string {
    const history = messages.slice(-10).map(m => `${m.senderId}: ${m.content}`).join('\n');
    return `As an AI assistant in a freelance workspace, provide 2-3 message suggestions based on this conversation history and current message draft:\n\nConversation History:\n${history}\n\nCurrent Message Draft: ${currentMessage}\n\nSuggestions:`;
  }

  private buildProjectAnalysisPrompt(project: Project): string {
    return `Analyze this freelance project description and provide insights:\n\nProject: ${project.title}\nDescription: ${project.description}\nBudget: ${project.budget}\nSkills: ${project.skills?.join(', ')}\n\nKey insights:`;
  }

  private buildProposalEnhancementPrompt(proposal: Proposal): string {
    return `Review this freelance proposal and suggest improvements:\n\nProposal: ${proposal.coverLetter}\nBudget: ${proposal.proposedAmount}\nTimeline: ${proposal.estimatedDays} days\n\nSuggestions:`;
  }

  private buildSentimentAnalysisPrompt(messages: WorkspaceMessage[]): string {
    const recentMessages = messages.slice(-5).map(m => m.content).join('\n');
    return `Analyze the sentiment of these messages and provide a sentiment score between -1 (negative) and 1 (positive):\n\nMessages:\n${recentMessages}\n\nSentiment Analysis:`;
  }

  private buildTaskSuggestionPrompt(workspace: Workspace): string {
    return `Based on this workspace context, suggest 2-3 tasks that should be completed next:\n\nWorkspace: ${workspace.title}\nDescription: ${workspace.description}\nStatus: ${workspace.status}\n\nTask Suggestions:`;
  }

  private parseAISuggestions(response: any): AISuggestion[] {
    try {
      const content = response.choices[0]?.message?.content;
      if (content) {
        return JSON.parse(content);
      }
    } catch (error) {
      console.error('Failed to parse AI suggestions:', error);
    }
    return [];
  }

  private parseSentimentResponse(response: any): { sentiment: string; score: number } {
    try {
      const content = response.choices[0]?.message?.content;
      if (content) {
        const parsed = JSON.parse(content);
        return { sentiment: parsed.sentiment || 'neutral', score: parsed.score || 0.5 };
      }
    } catch (error) {
      console.error('Failed to parse sentiment response:', error);
    }
    return { sentiment: 'neutral', score: 0.5 };
  }
}