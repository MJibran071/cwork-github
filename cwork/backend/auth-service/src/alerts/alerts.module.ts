import { Module } from '@nestjs/common';
import { AlertsService } from './alerts.service';
import { ConfigModule } from '@nestjs/config';
import { HttpModule } from '@nestjs/axios';
import { LoggingModule } from '../logging/logging.module';
import { UsersModule } from '../users/users.module';

@Module({
  imports: [ConfigModule, HttpModule, LoggingModule, UsersModule],
  providers: [AlertsService],
  exports: [AlertsService],
})
export class AlertsModule {}
