import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

export interface LogData {
  level: 'info' | 'warn' | 'error' | 'debug';
  message: string;
  context?: string;
  metadata?: Record<string, any>;
  timestamp?: Date;
}

@Injectable()
export class LoggingService {
  private readonly logger = new Logger(LoggingService.name);
  private readonly isProduction: boolean;

  constructor(private configService: ConfigService) {
    this.isProduction = this.configService.get('NODE_ENV') === 'production';
  }

  log(data: LogData) {
    const { level, message, context, metadata, timestamp } = data;
    const logEntry = {
      level,
      message,
      context: context || 'application',
      timestamp: timestamp || new Date(),
      metadata: metadata || {},
      environment: this.configService.get('NODE_ENV') || 'development',
      service: 'auth-service',
    };

    // Structured logging for production, simple for development
    if (this.isProduction) {
      this.logStructured(logEntry);
    } else {
      this.logSimple(logEntry);
    }
  }

  private logStructured(entry: any) {
    // JSON structured logging for production environments
    console.log(JSON.stringify(entry));
  }

  private logSimple(entry: any) {
    // Human-readable logging for development
    const { level, message, context, timestamp } = entry;
    const formattedTime = timestamp.toISOString();
    const logMessage = `[${formattedTime}] [${level.toUpperCase()}] [${context}] ${message}`;

    switch (entry.level) {
      case 'error':
        this.logger.error(logMessage);
        break;
      case 'warn':
        this.logger.warn(logMessage);
        break;
      case 'debug':
        this.logger.debug(logMessage);
        break;
      default:
        this.logger.log(logMessage);
    }

    // Log metadata if present
    if (entry.metadata && Object.keys(entry.metadata).length > 0) {
      this.logger.debug(`Metadata: ${JSON.stringify(entry.metadata, null, 2)}`);
    }
  }

  info(message: string, context?: string, metadata?: Record<string, any>) {
    this.log({
      level: 'info',
      message,
      context,
      metadata,
    });
  }

  warn(message: string, context?: string, metadata?: Record<string, any>) {
    this.log({
      level: 'warn',
      message,
      context,
      metadata,
    });
  }

  error(message: string, context?: string, metadata?: Record<string, any>, error?: Error) {
    const errorMetadata = {
      ...metadata,
      error: error
        ? {
            name: error.name,
            message: error.message,
            stack: error.stack,
          }
        : undefined,
    };

    this.log({
      level: 'error',
      message,
      context,
      metadata: errorMetadata,
    });
  }

  debug(message: string, context?: string, metadata?: Record<string, any>) {
    this.log({
      level: 'debug',
      message,
      context,
      metadata,
    });
  }

  // Security-specific logging methods
  securityEvent(event: string, details: Record<string, any>, context?: string) {
    this.log({
      level: 'info',
      message: `Security event: ${event}`,
      context: context || 'security',
      metadata: {
        eventType: 'security',
        ...details,
      },
    });
  }

  auditLog(action: string, user: string, resource: string, details?: Record<string, any>) {
    this.log({
      level: 'info',
      message: `Audit log: ${action} on ${resource} by ${user}`,
      context: 'audit',
      metadata: {
        action,
        user,
        resource,
        timestamp: new Date(),
        ...details,
      },
    });
  }

  // Enhanced security event logging with detailed context
  securityEventDetailed(
    event: string,
    severity: 'low' | 'medium' | 'high' | 'critical',
    user: string,
    action: string,
    resource: string,
    details?: Record<string, any>,
    context?: string,
  ) {
    this.log({
      level: severity === 'critical' || severity === 'high' ? 'warn' : 'info',
      message: `Security event (${severity}): ${event}`,
      context: context || 'security',
      metadata: {
        eventType: 'security',
        severity,
        user,
        action,
        resource,
        timestamp: new Date(),
        ...details,
      },
    });
  }

  // Real-time activity monitoring log
  realTimeActivity(
    activity: string,
    user: string,
    ipAddress: string,
    details?: Record<string, any>,
    context?: string,
  ) {
    this.log({
      level: 'info',
      message: `Real-time activity: ${activity}`,
      context: context || 'monitoring',
      metadata: {
        activity,
        user,
        ipAddress,
        timestamp: new Date(),
        ...details,
      },
    });
  }
}
