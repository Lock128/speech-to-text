import { APIGatewayProxyEvent, APIGatewayProxyResult, Context } from 'aws-lambda';
import { DynamoDBClient, GetItemCommand } from '@aws-sdk/client-dynamodb';

const dynamoClient = new DynamoDBClient({ region: process.env.AWS_REGION });

export const handler = async (
  event: APIGatewayProxyEvent,
  context: Context
): Promise<APIGatewayProxyResult> => {
  console.log('Status handler triggered:', JSON.stringify(event, null, 2));

  // Consistent CORS headers for all responses
  const corsHeaders = {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type, X-Amz-Date, Authorization, X-Api-Key, X-Amz-Security-Token, X-Amz-User-Agent',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Credentials': 'false',
  };

  try {
    const recordId = event.pathParameters?.recordId;
    
    if (!recordId) {
      return {
        statusCode: 400,
        headers: corsHeaders,
        body: JSON.stringify({ error: 'Record ID is required' }),
      };
    }

    // Get record from DynamoDB
    const getCommand = new GetItemCommand({
      TableName: process.env.DYNAMODB_TABLE_NAME,
      Key: {
        PK: { S: recordId },
        SK: { S: 'RECORD' },
      },
    });

    const result = await dynamoClient.send(getCommand);
    
    if (!result.Item) {
      return {
        statusCode: 404,
        headers: corsHeaders,
        body: JSON.stringify({ error: 'Record not found' }),
      };
    }

    // Parse DynamoDB item
    const status = result.Item.status?.S || 'unknown';
    const transcriptionText = result.Item.transcriptionText?.S;
    const enhancedArticleText = result.Item.enhancedArticleText?.S;
    const bedrockProcessedAt = result.Item.bedrockProcessedAt?.S;
    const bedrockTokenUsage = result.Item.bedrockTokenUsage?.S;
    const errorMessage = result.Item.errorMessage?.S;
    const createdAt = result.Item.createdAt?.S;
    const updatedAt = result.Item.updatedAt?.S;
    const emailSentAt = result.Item.emailSentAt?.S;

    // Calculate progress based on status
    let progress = 0;
    let statusDescription = '';
    
    switch (status) {
      case 'uploaded':
        progress = 0.15;
        statusDescription = 'Audio file uploaded, starting transcription...';
        break;
      case 'transcribing':
        progress = 0.4;
        statusDescription = 'Converting speech to text...';
        break;
      case 'transcription_completed':
        progress = 0.6;
        statusDescription = 'Transcription complete, enhancing article...';
        break;
      case 'enhancing_article':
        progress = 0.8;
        statusDescription = 'Creating newspaper article with AI...';
        break;
      case 'article_enhanced':
        progress = 0.9;
        statusDescription = 'Article enhanced, sending email...';
        break;
      case 'email_sent':
        progress = 1.0;
        statusDescription = 'Process complete! Email sent successfully.';
        break;
      case 'failed':
        progress = 0;
        statusDescription = 'Processing failed. Please try again.';
        break;
      default:
        statusDescription = 'Unknown status';
    }

    const response = {
      recordId,
      status,
      statusDescription,
      transcriptionText,
      enhancedArticleText,
      bedrockProcessedAt,
      bedrockTokenUsage: bedrockTokenUsage ? JSON.parse(bedrockTokenUsage) : undefined,
      errorMessage,
      progress,
      createdAt,
      updatedAt,
      emailSentAt,
    };

    return {
      statusCode: 200,
      headers: corsHeaders,
      body: JSON.stringify(response),
    };

  } catch (error) {
    console.error('Error getting status:', error);
    
    return {
      statusCode: 500,
      headers: corsHeaders,
      body: JSON.stringify({ error: 'Internal server error' }),
    };
  }
};