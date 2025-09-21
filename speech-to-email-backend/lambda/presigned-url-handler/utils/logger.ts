export enum LogLevel {
  DEBUG = 'DEBUG',
  INFO = 'INFO',
  WARN = 'WARN',
  ERROR = 'ERROR',
  SECURITY = 'SECURITY',
}

export interface LogContext {
  requestId?: string;
  userId?: string;
  recordId?: string;
  functionName?: string;
  stage?: string;
  [key: string]: any;
}

export class Logger {
  private context: LogContext;

  constructor(context: LogContext = {}) {
    this.context = {
      functionName: process.env.AWS_LAMBDA_FUNCTION_NAME,
      stage: process.env.STAGE || 'dev',
      ...context,
    };
  }

  private log(level: LogLevel, message: string, data?: any, error?: Error) {
    const logEntry = {
      timestamp: new Date().toISOString(),
      level,
      message,
      context: this.context,
      data,
      ...(error && {
        error: {
          name: error.name,
          message: error.message,
          stack: error.stack,
        },
      }),
    };

    console.log(JSON.stringify(logEntry));
  }

  debug(message: string, data?: any) {
    if (process.env.LOG_LEVEL === 'DEBUG') {
      this.log(LogLevel.DEBUG, message, data);
    }
  }

  info(message: string, data?: any) {
    this.log(LogLevel.INFO, message, data);
  }

  warn(message: string, data?: any) {
    this.log(LogLevel.WARN, message, data);
  }

  error(message: string, error?: Error, data?: any) {
    this.log(LogLevel.ERROR, message, data, error);
  }

  security(message: string, data?: any) {
    this.log(LogLevel.SECURITY, message, data);
  }

  // Business metrics logging
  metric(metricName: string, value: number, unit: string = 'Count', data?: any) {
    this.log(LogLevel.INFO, `METRIC: ${metricName}`, {
      metricName,
      value,
      unit,
      ...data,
    });
  }

  // Performance logging
  performance(operation: string, duration: number, data?: any) {
    this.log(LogLevel.INFO, `PERFORMANCE: ${operation}`, {
      operation,
      duration,
      ...data,
    });
  }

  // Audit logging
  audit(action: string, resource: string, data?: any) {
    this.log(LogLevel.INFO, `AUDIT: ${action} on ${resource}`, {
      action,
      resource,
      ...data,
    });
  }

  // Create child logger with additional context
  child(additionalContext: LogContext): Logger {
    return new Logger({
      ...this.context,
      ...additionalContext,
    });
  }
}

// Utility function to create logger with request context
export function createLogger(requestId?: string, additionalContext?: LogContext): Logger {
  return new Logger({
    requestId,
    ...additionalContext,
  });
}

// Performance measurement decorator
export function measurePerformance(operation: string) {
  return function (target: any, propertyName: string, descriptor: PropertyDescriptor) {
    const method = descriptor.value;

    descriptor.value = async function (...args: any[]) {
      const logger = new Logger();
      const startTime = Date.now();
      
      try {
        const result = await method.apply(this, args);
        const duration = Date.now() - startTime;
        logger.performance(operation, duration);
        return result;
      } catch (error) {
        const duration = Date.now() - startTime;
        logger.performance(operation, duration, { error: true });
        throw error;
      }
    };
  };
}