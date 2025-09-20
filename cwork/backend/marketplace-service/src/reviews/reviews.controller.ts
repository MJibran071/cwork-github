import { Controller, Get, Post, Body, Patch, Param, Delete, Query, UseGuards, Req } from '@nestjs/common';
import { ReviewsService } from './reviews.service';
import { CreateReviewDto } from './dto/create-review.dto';
import { UpdateReviewDto } from './dto/update-review.dto';
import { Review, ReviewType, ReviewStatus } from './review.entity';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('reviews')
@UseGuards(JwtAuthGuard)
export class ReviewsController {
  constructor(private readonly reviewsService: ReviewsService) {}

  @Post()
  async create(@Body() createReviewDto: CreateReviewDto, @Req() req) {
    const reviewerId = req.user.id;
    return this.reviewsService.create(createReviewDto, reviewerId);
  }

  @Get()
  async findAll(
    @Query('page') page: number = 1,
    @Query('limit') limit: number = 10,
    @Query('reviewedUserId') reviewedUserId?: string,
    @Query('type') type?: ReviewType,
    @Query('status') status?: ReviewStatus,
    @Query('minRating') minRating?: number,
    @Query('maxRating') maxRating?: number,
    @Query('projectId') projectId?: string,
  ) {
    return this.reviewsService.findAll(
      page,
      limit,
      reviewedUserId,
      type,
      status,
      minRating,
      maxRating,
      projectId,
    );
  }

  @Get(':id')
  async findOne(@Param('id') id: string) {
    return this.reviewsService.findOne(id);
  }

  @Patch(':id')
  async update(@Param('id') id: string, @Body() updateReviewDto: UpdateReviewDto) {
    return this.reviewsService.update(id, updateReviewDto);
  }

  @Delete(':id')
  async remove(@Param('id') id: string) {
    return this.reviewsService.remove(id);
  }

  @Get('user/:userId')
  async findByReviewedUserId(@Param('userId') userId: string) {
    return this.reviewsService.findByReviewedUserId(userId);
  }

  @Get('reviewer/:userId')
  async findByReviewerId(@Param('userId') userId: string) {
    return this.reviewsService.findByReviewerId(userId);
  }

  @Get('stats/:userId')
  async getStats(@Param('userId') userId: string) {
    return this.reviewsService.getStats(userId);
  }

  @Post(':id/helpful')
  async markHelpful(@Param('id') id: string) {
    return this.reviewsService.markHelpful(id);
  }

  @Post(':id/report')
  async reportReview(@Param('id') id: string, @Body('reason') reason: string) {
    return this.reviewsService.reportReview(id, reason);
  }

  @Post(':id/moderate')
  async moderateReview(
    @Param('id') id: string,
    @Body('status') status: ReviewStatus,
    @Body('reason') reason?: string,
  ) {
    return this.reviewsService.moderateReview(id, status, reason);
  }

  @Get('recent/reviews')
  async getRecentReviews(@Query('limit') limit: number = 10) {
    return this.reviewsService.getRecentReviews(limit);
  }

  @Get('search/reviews')
  async searchReviews(@Query('q') query: string) {
    return this.reviewsService.searchReviews(query);
  }
}