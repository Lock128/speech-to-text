import { APIGatewayProxyEvent, APIGatewayProxyResult, Context } from 'aws-lambda';
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
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
  console.log('Presigned URL request:', JSON.stringify(event, null, 2));

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

    const request: PresignedUrlRequest = JSON.parse(event.body);
    
    // Validate request
    if (!request.fileName || !request.contentType) {
      return {
        statusCode: 400,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Headers': 'Content-Type',
          'Access-Control-Allow-Methods': 'POST, OPTIONS',
        },
        body: JSON.stringify({ error: 'fileName and contentType are required' }),
      };
    }

    // Validate file size (max 50MB)
    const maxFileSize = 50 * 1024 * 1024; // 50MB
    if (request.fileSize && request.fileSize > maxFileSize) {
      return {
        statusCode: 400,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Headers': 'Content-Type',
          'Access-Control-Allow-Methods': 'POST, OPTIONS',
        },
        body: JSON.stringify({ error: 'File size exceeds maximum limit of 50MB' }),
      };
    }

    // Validate content type (audio files only)
    const allowedContentTypes = [
      'audio/mpeg',
      'audio/mp3',
      'audio/wav',
      'audio/m4a',
      'audio/aac',
      'audio/ogg',
      'audio/webm',
    ];

    if (!allowedContentTypes.includes(request.contentType.toLowerCase())) {
      return {
        statusCode: 400,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Headers': 'Content-Type',
          'Access-Control-Allow-Methods': 'POST, OPTIONS',
        },
        body: JSON.stringify({ error: 'Invalid content type. Only audio files are allowed.' }),
      };
    }

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

    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
      },
      body: JSON.stringify(response),
    };

  } catch (error) {
    console.error('Error generating presigned URL:', error);
    
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