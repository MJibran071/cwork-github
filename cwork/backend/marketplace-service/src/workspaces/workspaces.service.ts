import { Injectable, NotFoundException, BadRequestException, ForbiddenException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import {
  Workspace,
  WorkspaceMember,
  WorkspaceMessage,
  WorkspaceFile,
  MemberRole,
  MemberStatus,
  MessageType,
  ModerationStatus
} from './index';
import { CreateWorkspaceDto } from './dto/create-workspace.dto';
import { UpdateWorkspaceDto } from './dto/update-workspace.dto';
import { AddMemberDto } from './dto/add-member.dto';
import { SendMessageDto } from './dto/send-message.dto';
import { UploadFileDto } from './dto/upload-file.dto';

@Injectable()
export class WorkspacesService {
  constructor(
    @InjectRepository(Workspace)
    private readonly workspaceRepository: Repository<Workspace>,
    @InjectRepository(WorkspaceMember)
    private readonly memberRepository: Repository<WorkspaceMember>,
    @InjectRepository(WorkspaceMessage)
    private readonly messageRepository: Repository<WorkspaceMessage>,
    @InjectRepository(WorkspaceFile)
    private readonly fileRepository: Repository<WorkspaceFile>,
  ) {}

  async createWorkspace(createWorkspaceDto: CreateWorkspaceDto, creatorId: string): Promise<Workspace> {
    const workspace = this.workspaceRepository.create({
      ...createWorkspaceDto,
      creatorId,
    });

    const savedWorkspace = await this.workspaceRepository.save(workspace);

    // Add creator as admin member
    await this.addMember({
      workspaceId: savedWorkspace.id,
      userId: creatorId,
      role: MemberRole.ADMIN,
    }, creatorId);

    return savedWorkspace;
  }

  async getWorkspaceById(id: string, userId: string): Promise<Workspace> {
    const workspace = await this.workspaceRepository.findOne({
      where: { id },
      relations: ['members', 'messages', 'files'],
    });

    if (!workspace) {
      throw new NotFoundException('Workspace not found');
    }

    // Check if user is a member
    const isMember = workspace.members.some(member => member.userId === userId);
    if (!isMember && !workspace.isPublic) {
      throw new ForbiddenException('Access denied to workspace');
    }

    return workspace;
  }

  async getUserWorkspaces(userId: string): Promise<Workspace[]> {
    const memberships = await this.memberRepository.find({
      where: { userId },
      relations: ['workspace'],
    });

    return memberships.map(membership => membership.workspace);
  }

  async updateWorkspace(id: string, updateWorkspaceDto: UpdateWorkspaceDto, userId: string): Promise<Workspace> {
    const workspace = await this.workspaceRepository.findOne({
      where: { id },
      relations: ['members'],
    });

    if (!workspace) {
      throw new NotFoundException('Workspace not found');
    }

    // Check if user is admin
    const userMembership = workspace.members.find(member => member.userId === userId);
    if (!userMembership || userMembership.role !== MemberRole.ADMIN) {
      throw new ForbiddenException('Only admins can update workspace');
    }

    Object.assign(workspace, updateWorkspaceDto);
    return this.workspaceRepository.save(workspace);
  }

  async deleteWorkspace(id: string, userId: string): Promise<void> {
    const workspace = await this.workspaceRepository.findOne({
      where: { id },
      relations: ['members'],
    });

    if (!workspace) {
      throw new NotFoundException('Workspace not found');
    }

    // Check if user is admin
    const userMembership = workspace.members.find(member => member.userId === userId);
    if (!userMembership || userMembership.role !== MemberRole.ADMIN) {
      throw new ForbiddenException('Only admins can delete workspace');
    }

    await this.workspaceRepository.softDelete(id);
  }

  async addMember(addMemberDto: AddMemberDto, inviterId: string): Promise<WorkspaceMember> {
    const workspace = await this.workspaceRepository.findOne({
      where: { id: addMemberDto.workspaceId },
      relations: ['members'],
    });

    if (!workspace) {
      throw new NotFoundException('Workspace not found');
    }

    // Check if inviter is admin
    const inviterMembership = workspace.members.find(member => member.userId === inviterId);
    if (!inviterMembership || inviterMembership.role !== MemberRole.ADMIN) {
      throw new ForbiddenException('Only admins can add members');
    }

    // Check if user is already a member
    const existingMember = workspace.members.find(member => member.userId === addMemberDto.userId);
    if (existingMember) {
      throw new BadRequestException('User is already a member of this workspace');
    }

    const member = this.memberRepository.create({
      workspaceId: addMemberDto.workspaceId,
      userId: addMemberDto.userId,
      role: addMemberDto.role,
      userName: `User ${addMemberDto.userId.substring(0, 8)}`, // Placeholder name
      status: MemberStatus.INVITED,
      canEdit: addMemberDto.role === MemberRole.ADMIN,
      canDelete: addMemberDto.role === MemberRole.ADMIN,
      canInvite: addMemberDto.role === MemberRole.ADMIN,
      canManageTasks: true,
      canUploadFiles: true,
      joinedAt: new Date(),
      isActive: true
    });
    
    return this.memberRepository.save(member);
  }

  async removeMember(workspaceId: string, memberId: string, removerId: string): Promise<void> {
    const workspace = await this.workspaceRepository.findOne({
      where: { id: workspaceId },
      relations: ['members'],
    });

    if (!workspace) {
      throw new NotFoundException('Workspace not found');
    }

    // Check if remover is admin
    const removerMembership = workspace.members.find(member => member.userId === removerId);
    if (!removerMembership || removerMembership.role !== MemberRole.ADMIN) {
      throw new ForbiddenException('Only admins can remove members');
    }

    // Cannot remove yourself
    if (memberId === removerId) {
      throw new BadRequestException('Cannot remove yourself from workspace');
    }

    await this.memberRepository.delete({ id: memberId, workspaceId });
  }

  async sendMessage(sendMessageDto: SendMessageDto, senderId: string): Promise<WorkspaceMessage> {
    const workspace = await this.workspaceRepository.findOne({
      where: { id: sendMessageDto.workspaceId },
      relations: ['members'],
    });

    if (!workspace) {
      throw new NotFoundException('Workspace not found');
    }

    // Check if sender is a member
    const senderMembership = workspace.members.find(member => member.userId === senderId);
    if (!senderMembership) {
      throw new ForbiddenException('Only members can send messages');
    }

    // Server-side validation for restricted content
    const emailRegex = /^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$/; // Simplified email pattern
    const phoneRegex = /^[+]*[(]{0,1}[0-9]{1,4}[)]{0,1}[-\s\./0-9]*$/; // Catches most international formats

    if (emailRegex.test(sendMessageDto.content) || phoneRegex.test(sendMessageDto.content)) {
      throw new BadRequestException({
        error: 'RestrictedContent',
        message: 'Messages cannot contain email addresses or phone numbers.'
      });
    }

    const message = this.messageRepository.create({
      ...sendMessageDto,
      senderId,
      workspaceId: sendMessageDto.workspaceId,
      moderationStatus: ModerationStatus.APPROVED // Use enum value
    });

    return this.messageRepository.save(message);
  }

  async getWorkspaceMessages(workspaceId: string, userId: string): Promise<WorkspaceMessage[]> {
    const workspace = await this.workspaceRepository.findOne({
      where: { id: workspaceId },
      relations: ['members'],
    });

    if (!workspace) {
      throw new NotFoundException('Workspace not found');
    }

    // Check if user is a member
    const userMembership = workspace.members.find(member => member.userId === userId);
    if (!userMembership) {
      throw new ForbiddenException('Only members can view messages');
    }

    return this.messageRepository.find({
      where: { workspaceId },
      relations: ['sender'],
      order: { createdAt: 'DESC' },
      take: 100, // Limit to last 100 messages
    });
  }

  async uploadFile(uploadFileDto: UploadFileDto, uploaderId: string): Promise<WorkspaceFile> {
    const workspace = await this.workspaceRepository.findOne({
      where: { id: uploadFileDto.workspaceId },
      relations: ['members'],
    });

    if (!workspace) {
      throw new NotFoundException('Workspace not found');
    }

    // Check if uploader is a member
    const uploaderMembership = workspace.members.find(member => member.userId === uploaderId);
    if (!uploaderMembership) {
      throw new ForbiddenException('Only members can upload files');
    }

    const file = this.fileRepository.create({
      ...uploadFileDto,
      uploaderId,
    });

    return this.fileRepository.save(file) as unknown as Promise<WorkspaceFile>;
  }

  async getWorkspaceFiles(workspaceId: string, userId: string): Promise<WorkspaceFile[]> {
    const workspace = await this.workspaceRepository.findOne({
      where: { id: workspaceId },
      relations: ['members'],
    });

    if (!workspace) {
      throw new NotFoundException('Workspace not found');
    }

    // Check if user is a member
    const userMembership = workspace.members.find(member => member.userId === userId);
    if (!userMembership) {
      throw new ForbiddenException('Only members can view files');
    }

    return this.fileRepository.find({
      where: { workspaceId, isDeleted: false },
      relations: ['uploader'],
      order: { createdAt: 'DESC' },
    });
  }

  async deleteFile(fileId: string, userId: string): Promise<void> {
    const file = await this.fileRepository.findOne({
      where: { id: fileId },
      relations: ['workspace', 'workspace.members'],
    });

    if (!file) {
      throw new NotFoundException('File not found');
    }

    // Check if user is admin or the uploader
    const userMembership = file.workspace.members.find(member => member.userId === userId);
    const isAdmin = userMembership && userMembership.role === MemberRole.ADMIN;
    const isUploader = file.uploaderId === userId;

    if (!isAdmin && !isUploader) {
      throw new ForbiddenException('Only admins or uploaders can delete files');
    }

    await this.fileRepository.softDelete(fileId);
  }
}