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
    const errorMessage = result.Item.errorMessage?.S;
    const createdAt = result.Item.createdAt?.S;
    const updatedAt = result.Item.updatedAt?.S;
    const emailSentAt = result.Item.emailSentAt?.S;

    // Calculate progress based on status
    let progress = 0;
    switch (status) {
      case 'uploaded':
        progress = 0.2;
        break;
      case 'transcribing':
        progress = 0.5;
        break;
      case 'transcription_completed':
        progress = 0.8;
        break;
      case 'email_sent':
        progress = 1.0;
        break;
      case 'failed':
        progress = 0;
        break;
    }

    const response = {
      recordId,
      status,
      transcriptionText,
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