import { EventBridgeEvent, Context } from 'aws-lambda';
import { DynamoDBClient, UpdateItemCommand, GetItemCommand } from '@aws-sdk/client-dynamodb';
import { TranscribeClient, GetTranscriptionJobCommand } from '@aws-sdk/client-transcribe';
import { S3Client, GetObjectCommand } from '@aws-sdk/client-s3';
import { LambdaClient, InvokeCommand } from '@aws-sdk/client-lambda';

const dynamoClient = new DynamoDBClient({ region: process.env.AWS_REGION });
const transcribeClient = new TranscribeClient({ region: process.env.AWS_REGION });
const s3Client = new S3Client({ region: process.env.AWS_REGION });
const lambdaClient = new LambdaClient({ region: process.env.AWS_REGION });

interface TranscribeEventDetail {
  TranscriptionJobName: string;
  TranscriptionJobStatus: 'COMPLETED' | 'FAILED';
}

interface EmailPayload {
  transcriptionText: string;
  originalFileName: string;
  timestamp: string;
  recordId: string;
  audioFileKey: string;
}

export const handler = async (
  event: EventBridgeEvent<'Transcribe Job State Change', TranscribeEventDetail>,
  context: Context
) => {
  console.log('Transcription handler triggered:', JSON.stringify(event, null, 2));

  try {
    const { TranscriptionJobName, TranscriptionJobStatus } = event.detail;

    // Extract record ID from job name (format: speech-to-email-{recordId}-{timestamp})
    const jobNameParts = TranscriptionJobName.split('-');
    if (jobNameParts.length < 4) {
      console.error('Invalid transcription job name format:', TranscriptionJobName);
      return { statusCode: 400, body: 'Invalid job name format' };
    }

    const recordId = jobNameParts.slice(3, -1).join('-'); // Handle record IDs with hyphens
    console.log(`Processing transcription result for record: ${recordId}`);

    const now = new Date().toISOString();

    if (TranscriptionJobStatus === 'FAILED') {
      // Update DynamoDB record with failure status
      const updateCommand = new UpdateItemCommand({
        TableName: process.env.DYNAMODB_TABLE_NAME,
        Key: {
          PK: { S: recordId },
          SK: { S: 'RECORD' },
        },
        UpdateExpression: 'SET #status = :status, errorMessage = :error, updatedAt = :updatedAt',
        ExpressionAttributeNames: {
          '#status': 'status',
        },
        ExpressionAttributeValues: {
          ':status': { S: 'failed' },
          ':error': { S: 'Transcription job failed' },
          ':updatedAt': { S: now },
        },
      });

      await dynamoClient.send(updateCommand);
      console.log(`Updated record status to failed for ${recordId}`);
      return { statusCode: 200, body: 'Transcription failure processed' };
    }

    // Get transcription job details
    const getJobCommand = new GetTranscriptionJobCommand({
      TranscriptionJobName,
    });

    const jobResult = await transcribeClient.send(getJobCommand);
    const transcriptFileUri = jobResult.TranscriptionJob?.Transcript?.TranscriptFileUri;

    if (!transcriptFileUri) {
      throw new Error('No transcript file URI found in job result');
    }

    // Parse S3 URI to get bucket and key (handle both s3:// and https:// formats)
    let bucketName: string;
    let objectKey: string;

    const s3UriMatch = transcriptFileUri.match(/s3:\/\/([^\/]+)\/(.+)/);
    const httpsUriMatch = transcriptFileUri.match(/https:\/\/s3\.([^.]+)\.amazonaws\.com\/([^\/]+)\/(.+)/);

    if (s3UriMatch) {
      [, bucketName, objectKey] = s3UriMatch;
    } else if (httpsUriMatch) {
      [, , bucketName, objectKey] = httpsUriMatch;
    } else {
      throw new Error('Invalid S3 URI format: ' + transcriptFileUri);
    }

    // Download and parse transcription result
    const getObjectCommand = new GetObjectCommand({
      Bucket: bucketName,
      Key: objectKey,
    });

    const s3Response = await s3Client.send(getObjectCommand);
    const transcriptionData = await s3Response.Body?.transformToString();

    if (!transcriptionData) {
      throw new Error('Failed to read transcription data from S3');
    }

    const transcriptionResult = JSON.parse(transcriptionData);
    console.log('Full transcription result:', JSON.stringify(transcriptionResult, null, 2));

    const transcriptionText = transcriptionResult.results?.transcripts?.[0]?.transcript || 'No transcription available';

    console.log(`Extracted transcription text: "${transcriptionText}"`);
    console.log(`Transcription text length: ${transcriptionText.length}`);

    // Get original record details
    const getItemCommand = new GetItemCommand({
      TableName: process.env.DYNAMODB_TABLE_NAME,
      Key: {
        PK: { S: recordId },
        SK: { S: 'RECORD' },
      },
    });

    const recordResult = await dynamoClient.send(getItemCommand);
    const originalFileName = recordResult.Item?.audioFileKey?.S?.split('/').pop() || 'unknown';
    const createdAt = recordResult.Item?.createdAt?.S || now;

    // Update DynamoDB record with transcription result
    const updateCommand = new UpdateItemCommand({
      TableName: process.env.DYNAMODB_TABLE_NAME,
      Key: {
        PK: { S: recordId },
        SK: { S: 'RECORD' },
      },
      UpdateExpression: 'SET #status = :status, transcriptionText = :text, updatedAt = :updatedAt',
      ExpressionAttributeNames: {
        '#status': 'status',
      },
      ExpressionAttributeValues: {
        ':status': { S: 'transcription_completed' },
        ':text': { S: transcriptionText },
        ':updatedAt': { S: now },
      },
    });

    await dynamoClient.send(updateCommand);
    console.log(`Updated record with transcription text for ${recordId}`);

    // Prepare article enhancement payload
    const articleEnhancementPayload = {
      transcriptionText,
      originalFileName,
      timestamp: createdAt,
      recordId,
      audioFileKey: recordResult.Item?.audioFileKey?.S || '',
    };

    console.log('Article enhancement payload being sent:', JSON.stringify(articleEnhancementPayload, null, 2));

    // Invoke article enhancement handler
    const invokeCommand = new InvokeCommand({
      FunctionName: process.env.ARTICLE_ENHANCEMENT_HANDLER_FUNCTION_NAME,
      InvocationType: 'RequestResponse', // Synchronous invocation
      Payload: JSON.stringify(articleEnhancementPayload),
    });

    const invokeResult = await lambdaClient.send(invokeCommand);
    console.log(`Invoked article enhancement handler for ${recordId}`, {
      statusCode: invokeResult.StatusCode,
      payload: invokeResult.Payload ? Buffer.from(invokeResult.Payload).toString() : 'No payload'
    });

    return {
      statusCode: 200,
      body: JSON.stringify({ message: 'Transcription processed successfully', recordId }),
    };

  } catch (error) {
    console.error('Error processing transcription:', error);

    // Try to update the record status to failed if we can extract the record ID
    try {
      const jobName = event.detail.TranscriptionJobName;
      const jobNameParts = jobName.split('-');
      if (jobNameParts.length >= 4) {
        const recordId = jobNameParts.slice(3, -1).join('-');

        const updateCommand = new UpdateItemCommand({
          TableName: process.env.DYNAMODB_TABLE_NAME,
          Key: {
            PK: { S: recordId },
            SK: { S: 'RECORD' },
          },
          UpdateExpression: 'SET #status = :status, errorMessage = :error, updatedAt = :updatedAt',
          ExpressionAttributeNames: {
            '#status': 'status',
          },
          ExpressionAttributeValues: {
            ':status': { S: 'failed' },
            ':error': { S: error instanceof Error ? error.message : 'Unknown error' },
            ':updatedAt': { S: new Date().toISOString() },
          },
        });

        await dynamoClient.send(updateCommand);
      }
    } catch (updateError) {
      console.error('Error updating failed record:', updateError);
    }

    throw error;
  }
};