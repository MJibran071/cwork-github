import { Controller, Get, Post, Put, Delete, Body, Param, Query, UseGuards, Req } from '@nestjs/common';
import { WorkspacesService } from './workspaces.service';
import { CreateWorkspaceDto } from './dto/create-workspace.dto';
import { UpdateWorkspaceDto } from './dto/update-workspace.dto';
import { AddMemberDto } from './dto/add-member.dto';
import { SendMessageDto } from './dto/send-message.dto';
import { UploadFileDto } from './dto/upload-file.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Request } from 'express';

@Controller('workspaces')
@UseGuards(JwtAuthGuard)
export class WorkspacesController {
  constructor(private readonly workspacesService: WorkspacesService) {}

  @Post()
  async createWorkspace(@Body() createWorkspaceDto: CreateWorkspaceDto, @Req() req: Request) {
    const userId = (req.user as any).id;
    return this.workspacesService.createWorkspace(createWorkspaceDto, userId);
  }

  @Get(':id')
  async getWorkspace(@Param('id') id: string, @Req() req: Request) {
    const userId = (req.user as any).id;
    return this.workspacesService.getWorkspaceById(id, userId);
  }

  @Get()
  async getUserWorkspaces(@Req() req: Request) {
    const userId = (req.user as any).id;
    return this.workspacesService.getUserWorkspaces(userId);
  }

  @Put(':id')
  async updateWorkspace(@Param('id') id: string, @Body() updateWorkspaceDto: UpdateWorkspaceDto, @Req() req: Request) {
    const userId = (req.user as any).id;
    return this.workspacesService.updateWorkspace(id, updateWorkspaceDto, userId);
  }

  @Delete(':id')
  async deleteWorkspace(@Param('id') id: string, @Req() req: Request) {
    const userId = (req.user as any).id;
    return this.workspacesService.deleteWorkspace(id, userId);
  }

  @Post(':id/members')
  async addMember(@Param('id') workspaceId: string, @Body() addMemberDto: AddMemberDto, @Req() req: Request) {
    const inviterId = (req.user as any).id;
    return this.workspacesService.addMember({ ...addMemberDto, workspaceId }, inviterId);
  }

  @Delete(':id/members/:memberId')
  async removeMember(@Param('id') workspaceId: string, @Param('memberId') memberId: string, @Req() req: Request) {
    const removerId = (req.user as any).id;
    return this.workspacesService.removeMember(workspaceId, memberId, removerId);
  }

  @Post(':id/messages')
  async sendMessage(@Param('id') workspaceId: string, @Body() sendMessageDto: SendMessageDto, @Req() req: Request) {
    const senderId = (req.user as any).id;
    return this.workspacesService.sendMessage({ ...sendMessageDto, workspaceId }, senderId);
  }

  @Get(':id/messages')
  async getMessages(@Param('id') workspaceId: string, @Req() req: Request) {
    const userId = (req.user as any).id;
    return this.workspacesService.getWorkspaceMessages(workspaceId, userId);
  }

  @Post(':id/files')
  async uploadFile(@Param('id') workspaceId: string, @Body() uploadFileDto: UploadFileDto, @Req() req: Request) {
    const uploaderId = (req.user as any).id;
    return this.workspacesService.uploadFile({ ...uploadFileDto, workspaceId }, uploaderId);
  }

  @Get(':id/files')
  async getFiles(@Param('id') workspaceId: string, @Req() req: Request) {
    const userId = (req.user as any).id;
    return this.workspacesService.getWorkspaceFiles(workspaceId, userId);
  }

  @Delete('files/:fileId')
  async deleteFile(@Param('fileId') fileId: string, @Req() req: Request) {
    const userId = (req.user as any).id;
    return this.workspacesService.deleteFile(fileId, userId);
  }
}