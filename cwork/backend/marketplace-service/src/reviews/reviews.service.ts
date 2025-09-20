import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Between, LessThanOrEqual, MoreThanOrEqual, In, Like } from 'typeorm';
import { Review, ReviewType, ReviewStatus } from './review.entity';
import { CreateReviewDto } from './dto/create-review.dto';
import { UpdateReviewDto } from './dto/update-review.dto';
import { ProjectsService } from '../projects/projects.service';

@Injectable()
export class ReviewsService {
  constructor(
    @InjectRepository(Review)
    private readonly reviewRepository: Repository<Review>,
    private readonly projectsService: ProjectsService,
  ) {}

  async create(createReviewDto: CreateReviewDto, reviewerId: string): Promise<Review> {
    // Verify project exists and is completed
    const project = await this.projectsService.findOne(createReviewDto.projectId);
    if (!project) {
      throw new NotFoundException('Project not found');
    }

    if (project.status !== 'completed') {
      throw new BadRequestException('Can only review completed projects');
    }

    // Check if reviewer has already reviewed this project for the same type
    const existingReview = await this.reviewRepository.findOne({
      where: {
        projectId: createReviewDto.projectId,
        reviewerId: reviewerId,
        type: createReviewDto.type,
        reviewedUserId: createReviewDto.reviewedUserId,
      },
    });

    if (existingReview) {
      throw new BadRequestException('You have already submitted a review for this project');
    }

    // Verify the reviewer is either the client or freelancer of the project
    if (createReviewDto.type === ReviewType.CLIENT_TO_FREELANCER) {
      if (reviewerId !== project.clientId) {
        throw new BadRequestException('Only the client can review the freelancer');
      }
      if (createReviewDto.reviewedUserId !== project.freelancerId) {
        throw new BadRequestException('Can only review the assigned freelancer');
      }
    } else if (createReviewDto.type === ReviewType.FREELANCER_TO_CLIENT) {
      if (reviewerId !== project.freelancerId) {
        throw new BadRequestException('Only the freelancer can review the client');
      }
      if (createReviewDto.reviewedUserId !== project.clientId) {
        throw new BadRequestException('Can only review the project client');
      }
    }

    const review = this.reviewRepository.create({
      ...createReviewDto,
      reviewerId,
      status: ReviewStatus.PUBLISHED,
      publishedAt: new Date(),
    });

    return this.reviewRepository.save(review);
  }

  async findAll(
    page: number = 1,
    limit: number = 10,
    reviewedUserId?: string,
    type?: ReviewType,
    status?: ReviewStatus,
    minRating?: number,
    maxRating?: number,
    projectId?: string,
  ): Promise<{ reviews: Review[]; total: number }> {
    const skip = (page - 1) * limit;
    const where: any = {};

    if (reviewedUserId) where.reviewedUserId = reviewedUserId;
    if (type) where.type = type;
    if (status) where.status = status;
    if (projectId) where.projectId = projectId;
    
    if (minRating !== undefined || maxRating !== undefined) {
      where.rating = Between(minRating || 1, maxRating || 5);
    }

    const [reviews, total] = await this.reviewRepository.findAndCount({
      where,
      relations: ['project'],
      order: { createdAt: 'DESC' },
      skip,
      take: limit,
    });

    return { reviews, total };
  }

  async findOne(id: string): Promise<Review> {
    const review = await this.reviewRepository.findOne({
      where: { id },
      relations: ['project'],
    });

    if (!review) {
      throw new NotFoundException('Review not found');
    }

    return review;
  }

  async update(id: string, updateReviewDto: UpdateReviewDto): Promise<Review> {
    const review = await this.findOne(id);

    // Only allow updates to pending or published reviews
    if (review.status === ReviewStatus.FLAGGED || review.status === ReviewStatus.REMOVED) {
      throw new BadRequestException('Cannot update a flagged or removed review');
    }

    Object.assign(review, updateReviewDto);
    return this.reviewRepository.save(review);
  }

  async remove(id: string): Promise<void> {
    const review = await this.findOne(id);
    await this.reviewRepository.remove(review);
  }

  async findByReviewedUserId(userId: string): Promise<Review[]> {
    return this.reviewRepository.find({
      where: { reviewedUserId: userId, status: ReviewStatus.PUBLISHED },
      relations: ['project'],
      order: { createdAt: 'DESC' },
    });
  }

  async findByReviewerId(userId: string): Promise<Review[]> {
    return this.reviewRepository.find({
      where: { reviewerId: userId, status: ReviewStatus.PUBLISHED },
      relations: ['project'],
      order: { createdAt: 'DESC' },
    });
  }

  async getStats(userId: string): Promise<{
    total: number;
    averageRating: number;
    ratingDistribution: { [key: number]: number };
    criteriaAverages: {
      quality?: number;
      communication?: number;
      professionalism?: number;
      deadline?: number;
      budget?: number;
    };
  }> {
    const reviews = await this.findByReviewedUserId(userId);
    
    const total = reviews.length;
    const averageRating = total > 0 ? reviews.reduce((sum, review) => sum + review.rating, 0) / total : 0;
    
    const ratingDistribution = { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 };
    reviews.forEach(review => {
      ratingDistribution[review.rating]++;
    });

    const criteriaAverages = {
      quality: 0,
      communication: 0,
      professionalism: 0,
      deadline: 0,
      budget: 0,
    };

    let criteriaCount = 0;
    reviews.forEach(review => {
      if (review.criteriaScores) {
        if (review.criteriaScores.quality) {
          criteriaAverages.quality += review.criteriaScores.quality;
          criteriaCount++;
        }
        if (review.criteriaScores.communication) {
          criteriaAverages.communication += review.criteriaScores.communication;
          criteriaCount++;
        }
        if (review.criteriaScores.professionalism) {
          criteriaAverages.professionalism += review.criteriaScores.professionalism;
          criteriaCount++;
        }
        if (review.criteriaScores.deadline) {
          criteriaAverages.deadline += review.criteriaScores.deadline;
          criteriaCount++;
        }
        if (review.criteriaScores.budget) {
          criteriaAverages.budget += review.criteriaScores.budget;
          criteriaCount++;
        }
      }
    });

    if (criteriaCount > 0) {
      criteriaAverages.quality = criteriaAverages.quality / criteriaCount;
      criteriaAverages.communication = criteriaAverages.communication / criteriaCount;
      criteriaAverages.professionalism = criteriaAverages.professionalism / criteriaCount;
      criteriaAverages.deadline = criteriaAverages.deadline / criteriaCount;
      criteriaAverages.budget = criteriaAverages.budget / criteriaCount;
    }

    return { total, averageRating, ratingDistribution, criteriaAverages };
  }

  async markHelpful(id: string): Promise<Review> {
    const review = await this.findOne(id);
    review.helpfulCount++;
    return this.reviewRepository.save(review);
  }

  async reportReview(id: string, reason: string): Promise<Review> {
    const review = await this.findOne(id);
    review.reportCount++;
    review.status = ReviewStatus.FLAGGED;
    review.flaggedAt = new Date();
    review.flagReason = reason;
    return this.reviewRepository.save(review);
  }

  async moderateReview(id: string, status: ReviewStatus, reason?: string): Promise<Review> {
    const review = await this.findOne(id);
    review.status = status;
    
    if (status === ReviewStatus.FLAGGED) {
      review.flaggedAt = new Date();
      review.flagReason = reason;
    } else if (status === ReviewStatus.PUBLISHED) {
      review.publishedAt = new Date();
    }
    
    return this.reviewRepository.save(review);
  }

  async getRecentReviews(limit: number = 10): Promise<Review[]> {
    return this.reviewRepository.find({
      where: { status: ReviewStatus.PUBLISHED },
      relations: ['project'],
      order: { createdAt: 'DESC' },
      take: limit,
    });
  }

  async searchReviews(query: string): Promise<Review[]> {
    return this.reviewRepository.find({
      where: [
        { title: Like(`%${query}%`), status: ReviewStatus.PUBLISHED },
        { content: Like(`%${query}%`), status: ReviewStatus.PUBLISHED },
      ],
      relations: ['project'],
      take: 20,
    });
  }
}