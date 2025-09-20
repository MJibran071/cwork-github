import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { AdminService, DashboardStats, RevenueStats, UserStats, ProjectStats } from './admin.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';
import { UserRole } from '../auth/roles.enum';

@Controller('admin')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.ADMIN)
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  @Get('dashboard/stats')
  async getDashboardStats(): Promise<DashboardStats> {
    return this.adminService.getDashboardStats();
  }

  @Get('revenue/stats')
  async getRevenueStats(
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
  ): Promise<RevenueStats> {
    const start = startDate ? new Date(startDate) : undefined;
    const end = endDate ? new Date(endDate) : undefined;
    return this.adminService.getRevenueStats(start, end);
  }

  @Get('user/stats')
  async getUserStats(): Promise<UserStats> {
    return this.adminService.getUserStats();
  }

  @Get('project/stats')
  async getProjectStats(): Promise<ProjectStats> {
    return this.adminService.getProjectStats();
  }

  @Get('recent-activity')
  async getRecentActivity(@Query('limit') limit?: number): Promise<any[]> {
    return this.adminService.getRecentActivity(limit);
  }

  @Get('system/health')
  async getSystemHealth(): Promise<any> {
    return this.adminService.getSystemHealth();
  }
}