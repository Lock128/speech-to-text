// Global test setup
import { jest } from '@jest/globals';

// Mock AWS SDK globally
jest.mock('@aws-sdk/client-s3');
jest.mock('@aws-sdk/client-dynamodb');
jest.mock('@aws-sdk/client-transcribe');
jest.mock('@aws-sdk/client-ses');
jest.mock('@aws-sdk/client-lambda');
jest.mock('@aws-sdk/s3-request-presigner');

// Mock environment variables
process.env.AWS_REGION = 'us-east-1';
process.env.DYNAMODB_TABLE_NAME = 'test-table';
process.env.AUDIO_BUCKET_NAME = 'test-bucket';
process.env.RECIPIENT_EMAIL = 'test@example.com';
process.env.SENDER_EMAIL = 'noreply@example.com';

// Global test timeout
jest.setTimeout(30000);