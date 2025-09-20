import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

enum LogLevel {
  ERROR = 0,
  WARN = 1,
  INFO = 2,
  DEBUG = 3
}

class Logger {
  private logLevel: LogLevel;

  constructor() {
    const level = process.env.LOG_LEVEL?.toLowerCase() || 'info';
    this.logLevel = this.parseLogLevel(level);
  }

  private parseLogLevel(level: string): LogLevel {
    switch (level) {
    case 'error': return LogLevel.ERROR;
    case 'warn': return LogLevel.WARN;
    case 'info': return LogLevel.INFO;
    case 'debug': return LogLevel.DEBUG;
    default: return LogLevel.INFO;
    }
  }

  private formatMessage(level: string, message: string, data?: Record<string, unknown>): string {
    const timestamp = new Date().toISOString();
    const prefix = `[${timestamp}] [${level.toUpperCase()}] [ZSnail-L2]`;
    
    if (data) {
      return `${prefix} ${message} ${JSON.stringify(data, null, 2)}`;
    }
    return `${prefix} ${message}`;
  }

  error(message: string, data?: Record<string, unknown>): void {
    if (this.logLevel >= LogLevel.ERROR) {
      console.error(this.formatMessage('error', message, data));
    }
  }

  warn(message: string, data?: Record<string, unknown>): void {
    if (this.logLevel >= LogLevel.WARN) {
      console.warn(this.formatMessage('warn', message, data));
    }
  }

  info(message: string, data?: Record<string, unknown>): void {
    if (this.logLevel >= LogLevel.INFO) {
      console.log(this.formatMessage('info', message, data));
    }
  }

  debug(message: string, data?: Record<string, unknown>): void {
    if (this.logLevel >= LogLevel.DEBUG) {
      console.log(this.formatMessage('debug', message, data));
    }
  }
}

export const logger = new Logger();