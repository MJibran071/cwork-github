import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { HttpService } from '@nestjs/axios';
import { firstValueFrom } from 'rxjs';
import { LoggingService } from '../logging/logging.service';
import { UsersService } from '../users/users.service';

export interface AlertData {
  type: 'security' | 'performance' | 'error' | 'audit';
  severity: 'low' | 'medium' | 'high' | 'critical';
  message: string;
  context?: string;
  metadata?: Record<string, any>;
  timestamp?: Date;
}

@Injectable()
export class AlertsService {
  private readonly logger = new Logger(AlertsService.name);
  private readonly isProduction: boolean;
  private readonly slackWebhookUrl: string | null;
  private readonly emailAlertsEnabled: boolean;

  constructor(
    private configService: ConfigService,
    private httpService: HttpService,
    private loggingService: LoggingService,
    private usersService: UsersService,
  ) {
    this.isProduction = this.configService.get('NODE_ENV') === 'production';
    this.slackWebhookUrl = this.configService.get('SLACK_WEBHOOK_URL') || null;
    this.emailAlertsEnabled = this.configService.get('EMAIL_ALERTS_ENABLED') === 'true';
  }

  async sendAlert(alertData: AlertData): Promise<void> {
    const { type, severity, message, context, metadata, timestamp } = alertData;

    const alert = {
      type,
      severity,
      message,
      context: context || 'application',
      timestamp: timestamp || new Date(),
      metadata: metadata || {},
      environment: this.configService.get('NODE_ENV') || 'development',
      service: 'auth-service',
    };

    // Log the alert for auditing
    this.loggingService.securityEvent(`Alert triggered: ${type} - ${severity}`, alert);

    // Send to different channels based on severity and environment
    if (this.isProduction) {
      await this.sendProductionAlerts(alert);
    } else {
      this.sendDevelopmentAlerts(alert);
    }
  }

  private async sendProductionAlerts(alert: any): Promise<void> {
    const { severity } = alert;

    // Critical alerts always go to Slack and email
    if (severity === 'critical') {
      await this.sendSlackAlert(alert);
      if (this.emailAlertsEnabled) {
        await this.sendEmailAlert(alert);
      }
    }

    // High severity alerts go to Slack
    else if (severity === 'high') {
      await this.sendSlackAlert(alert);
    }

    // Medium and low severity are logged but not alerted externally
    else {
      this.logger.warn(`Production alert (not sent externally): ${JSON.stringify(alert)}`);
    }
  }

  private sendDevelopmentAlerts(alert: any): void {
    // In development, just log the alerts
    const { severity, message, context } = alert;
    const logMessage = `[ALERT] [${severity.toUpperCase()}] [${context}] ${message}`;

    switch (alert.severity) {
      case 'critical':
      case 'high':
        this.logger.error(logMessage);
        break;
      case 'medium':
        this.logger.warn(logMessage);
        break;
      default:
        this.logger.log(logMessage);
    }

    // Log metadata if present
    if (alert.metadata && Object.keys(alert.metadata).length > 0) {
      this.logger.debug(`Alert metadata: ${JSON.stringify(alert.metadata, null, 2)}`);
    }
  }

  private async sendSlackAlert(alert: any): Promise<void> {
    if (!this.slackWebhookUrl) {
      this.logger.warn('Slack webhook URL not configured, skipping Slack alert');
      return;
    }

    try {
      const slackMessage = {
        text: `🚨 *${alert.severity.toUpperCase()} Alert - ${alert.type}*`,
        blocks: [
          {
            type: 'section',
            text: {
              type: 'mrkdwn',
              text: `*${alert.severity.toUpperCase()} Alert - ${alert.type}*`,
            },
          },
          {
            type: 'section',
            text: {
              type: 'mrkdwn',
              text: `*Message:* ${alert.message}\n*Context:* ${alert.context}\n*Environment:* ${
                alert.environment
              }\n*Timestamp:* ${alert.timestamp.toISOString()}`,
            },
          },
          {
            type: 'section',
            text: {
              type: 'mrkdwn',
              text: `*Service:* ${alert.service}`,
            },
          },
        ],
      };

      if (alert.metadata && Object.keys(alert.metadata).length > 0) {
        slackMessage.blocks.push({
          type: 'section',
          text: {
            type: 'mrkdwn',
            text: `*Metadata:*\n\`\`\`${JSON.stringify(alert.metadata, null, 2)}\`\`\``,
          },
        });
      }

      await firstValueFrom(this.httpService.post(this.slackWebhookUrl, slackMessage));

      this.logger.log(`Slack alert sent successfully for ${alert.type} alert`);
    } catch (error) {
      this.logger.error(`Failed to send Slack alert: ${error.message}`, error.stack);
    }
  }

  private async sendEmailAlert(alert: any): Promise<void> {
    // Placeholder for email alert integration
    // In a real implementation, this would integrate with an email service
    this.logger.log(`Email alert would be sent for: ${alert.message}`);
    // Implementation would go here for services like SendGrid, Mailgun, etc.
  }

  // Specific alert methods for common scenarios
  async securityAlert(
    message: string,
    severity: 'low' | 'medium' | 'high' | 'critical',
    metadata?: Record<string, any>,
    context?: string,
  ): Promise<void> {
    await this.sendAlert({
      type: 'security',
      severity,
      message,
      context,
      metadata,
    });
  }

  async failedLoginAttempt(email: string, ipAddress: string, userAgent: string): Promise<void> {
    await this.securityAlert(
      `Failed login attempt for email: ${email}`,
      'medium',
      { email, ipAddress, userAgent },
      'authentication',
    );
  }

  async multipleFailedAttempts(email: string, count: number, ipAddress: string): Promise<void> {
    await this.securityAlert(
      `Multiple failed login attempts (${count}) for email: ${email}`,
      'high',
      { email, attemptCount: count, ipAddress },
      'authentication',
    );
  }

  async suspiciousActivity(
    userId: string,
    activity: string,
    details: Record<string, any>,
  ): Promise<void> {
    await this.securityAlert(
      `Suspicious activity detected for user ${userId}: ${activity}`,
      'high',
      { userId, activity, ...details },
      'security',
    );
  }

  async rateLimitExceeded(ipAddress: string, endpoint: string, count: number): Promise<void> {
    await this.securityAlert(
      `Rate limit exceeded for IP ${ipAddress} on endpoint ${endpoint}`,
      'medium',
      { ipAddress, endpoint, requestCount: count },
      'rate-limiting',
    );
  }

  async systemError(error: Error, context: string, metadata?: Record<string, any>): Promise<void> {
    await this.sendAlert({
      type: 'error',
      severity: 'high',
      message: `System error in ${context}: ${error.message}`,
      context,
      metadata: {
        error: {
          name: error.name,
          message: error.message,
          stack: error.stack,
        },
        ...metadata,
      },
    });
  }

  async performanceIssue(
    metric: string,
    value: number,
    threshold: number,
    context: string,
  ): Promise<void> {
    await this.sendAlert({
      type: 'performance',
      severity: 'medium',
      message: `Performance issue detected: ${metric} = ${value} (threshold: ${threshold})`,
      context,
      metadata: { metric, value, threshold },
    });
  }

  async unusualLocationLogin(
    email: string,
    ipAddress: string,
    location: string,
    previousLocations: string[],
  ): Promise<void> {
    await this.securityAlert(
      `Login from unusual location for email: ${email}`,
      'medium',
      { email, ipAddress, location, previousLocations },
      'geolocation',
    );
  }

  async analyzeLoginLocation(email: string, ipAddress: string): Promise<void> {
    try {
      // Get user to check previous login IPs
      const user = await this.usersService.findUserByEmail(email);
      if (!user) return;

      const currentLocation = await this.getLocationFromIP(ipAddress);
      const previousLocations = await this.getPreviousLocations(user.loginIPs || []);

      // Check if this is an unusual location
      if (this.isUnusualLocation(currentLocation, previousLocations)) {
        await this.unusualLocationLogin(email, ipAddress, currentLocation, previousLocations);
      }
    } catch (error) {
      this.logger.error(`Geolocation analysis failed: ${error.message}`);
    }
  }

  private async getLocationFromIP(ipAddress: string): Promise<string> {
    // Mock implementation - in production, use a geolocation API like IPinfo or MaxMind
    // For now, return a mock location based on IP pattern or use a simple mapping
    if (ipAddress.startsWith('192.168.') || ipAddress === '127.0.0.1') {
      return 'Local Network';
    }

    // Simple mapping for demonstration
    const ipToLocation: Record<string, string> = {
      '1.1.1.1': 'Australia',
      '8.8.8.8': 'United States',
      '2001:4860:4860::8888': 'United States',
    };

    return ipToLocation[ipAddress] || 'Unknown Location';
  }

  private async getPreviousLocations(loginIPs: string[]): Promise<string[]> {
    const locations: string[] = [];
    for (const ip of loginIPs) {
      const location = await this.getLocationFromIP(ip);
      if (location !== 'Unknown Location' && !locations.includes(location)) {
        locations.push(location);
      }
    }
    return locations;
  }

  private isUnusualLocation(currentLocation: string, previousLocations: string[]): boolean {
    if (currentLocation === 'Unknown Location' || currentLocation === 'Local Network') {
      return false;
    }

    // If no previous locations, this is the first login, so not unusual
    if (previousLocations.length === 0) {
      return false;
    }

    // If current location is not in previous locations, it's unusual
    return !previousLocations.includes(currentLocation);
  }
}
