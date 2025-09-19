import { APIGatewayProxyEvent, APIGatewayProxyResult, Context } from 'aws-lambda';
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { InputValidator } from '../utils/validation';
import { createLogger } from '../utils/logger';
const { v4: uuidv4 } = require('uuid');

const s3Client = new S3Client({ region: process.env.AWS_REGION });

interface PresignedUrlRequest {
  fileName: string;
  fileSize: number;
  contentType: string;
}

interface PresignedUrlResponse {
  uploadUrl: string;
  recordId: string;
  expiresIn: number;
}

export const handler = async (
  event: APIGatewayProxyEvent,
  context: Context
): Promise<APIGatewayProxyResult> => {
  const logger = createLogger(context.awsRequestId, {
    functionName: context.functionName,
    sourceIP: event.requestContext.identity.sourceIp,
    userAgent: event.requestContext.identity.userAgent,
  });

  logger.info('Presigned URL request received', {
    httpMethod: event.httpMethod,
    path: event.path,
    headers: event.headers,
  });

  try {
    // Parse request body
    if (!event.body) {
      return {
        statusCode: 400,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Headers': 'Content-Type',
          'Access-Control-Allow-Methods': 'POST, OPTIONS',
        },
        body: JSON.stringify({ error: 'Request body is required' }),
      };
    }

    const requestBody = JSON.parse(event.body);
    
    // Validate and sanitize input
    const validation = InputValidator.validatePresignedUrlRequest(requestBody);
    if (!validation.isValid) {
      logger.security('Invalid presigned URL request', {
        errors: validation.errors,
        requestBody: requestBody,
      });
      
      return {
        statusCode: 400,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Headers': 'Content-Type',
          'Access-Control-Allow-Methods': 'POST, OPTIONS',
        },
        body: JSON.stringify({ 
          error: 'Validation failed',
          details: validation.errors 
        }),
      };
    }

    const request: PresignedUrlRequest = {
      fileName: InputValidator.sanitizeString(requestBody.fileName),
      fileSize: requestBody.fileSize,
      contentType: requestBody.contentType.toLowerCase(),
    };

    // Additional security headers
    const securityHeaders = {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*', // In production, restrict to specific domains
      'Access-Control-Allow-Headers': 'Content-Type',
      'Access-Control-Allow-Methods': 'POST, OPTIONS',
      'X-Content-Type-Options': 'nosniff',
      'X-Frame-Options': 'DENY',
      'X-XSS-Protection': '1; mode=block',
      'Strict-Transport-Security': 'max-age=31536000; includeSubDomains',
    };

    // Generate unique record ID and file key
    const recordId = uuidv4();
    const now = new Date();
    const year = now.getFullYear();
    const month = String(now.getMonth() + 1).padStart(2, '0');
    const day = String(now.getDate()).padStart(2, '0');
    
    // Extract file extension from content type or filename
    let extension = 'mp3'; // default
    if (request.contentType.includes('wav')) extension = 'wav';
    else if (request.contentType.includes('m4a')) extension = 'm4a';
    else if (request.contentType.includes('aac')) extension = 'aac';
    else if (request.contentType.includes('ogg')) extension = 'ogg';
    else if (request.contentType.includes('webm')) extension = 'webm';

    const fileKey = `audio-files/${year}/${month}/${day}/${recordId}.${extension}`;

    // Create presigned URL
    const command = new PutObjectCommand({
      Bucket: process.env.AUDIO_BUCKET_NAME,
      Key: fileKey,
      ContentType: request.contentType,
      Metadata: {
        recordId: recordId,
        originalFileName: request.fileName,
        uploadTimestamp: now.toISOString(),
      },
    });

    const expiresIn = 3600; // 1 hour
    const uploadUrl = await getSignedUrl(s3Client, command, { expiresIn });

    const response: PresignedUrlResponse = {
      uploadUrl,
      recordId,
      expiresIn,
    };

    logger.info('Presigned URL generated successfully', {
      recordId,
      fileName: request.fileName,
      fileSize: request.fileSize,
      contentType: request.contentType,
    });

    logger.metric('PresignedUrlGenerated', 1);
    logger.audit('PRESIGNED_URL_GENERATED', recordId, {
      fileName: request.fileName,
      fileSize: request.fileSize,
    });

    return {
      statusCode: 200,
      headers: securityHeaders,
      body: JSON.stringify(response),
    };

  } catch (error) {
    logger.error('Error generating presigned URL', error as Error);
    
    logger.metric('PresignedUrlError', 1);
    
    return {
      statusCode: 500,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
      },
      body: JSON.stringify({ error: 'Internal server error' }),
    };
  }
};