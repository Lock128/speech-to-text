import { S3Event, Context } from 'aws-lambda';
import { DynamoDBClient, PutItemCommand, UpdateItemCommand, GetItemCommand } from '@aws-sdk/client-dynamodb';
import { TranscribeClient, StartTranscriptionJobCommand } from '@aws-sdk/client-transcribe';

const dynamoClient = new DynamoDBClient({ region: process.env.AWS_REGION });
const transcribeClient = new TranscribeClient({ region: process.env.AWS_REGION });

interface ProcessingRecord {
  PK: string;
  SK: string;
  audioFileKey: string;
  status: string;
  createdAt: string;
  updatedAt: string;
  transcribeJobName?: string;
  retryCount: number;
}

export const handler = async (event: S3Event, context: Context) => {
  console.log('Upload handler triggered:', JSON.stringify(event, null, 2));

  try {
    for (const record of event.Records) {
      const bucketName = record.s3.bucket.name;
      const objectKey = decodeURIComponent(record.s3.object.key.replace(/\+/g, ' '));
      
      console.log(`Processing upload: ${objectKey} from bucket: ${bucketName}`);

      // Extract record ID from the object key (assuming format: audio-files/yyyy/mm/dd/recordId.ext)
      const keyParts = objectKey.split('/');
      const fileName = keyParts[keyParts.length - 1];
      const recordId = fileName.split('.')[0];

      if (!recordId) {
        console.error('Could not extract record ID from object key:', objectKey);
        continue;
      }

      const now = new Date().toISOString();
      
      // Check if record already exists to prevent duplicate processing
      const getCommand = new GetItemCommand({
        TableName: process.env.DYNAMODB_TABLE_NAME,
        Key: {
          PK: { S: recordId },
          SK: { S: 'RECORD' },
        },
      });

      const existingRecord = await dynamoClient.send(getCommand);
      if (existingRecord.Item) {
        console.log(`Record ${recordId} already exists, skipping duplicate processing`);
        continue;
      }

      // Create DynamoDB record
      const dynamoRecord: ProcessingRecord = {
        PK: recordId,
        SK: 'RECORD',
        audioFileKey: objectKey,
        status: 'uploaded',
        createdAt: now,
        updatedAt: now,
        retryCount: 0,
      };

      // Store record in DynamoDB with conditional write to prevent duplicates
      const putCommand = new PutItemCommand({
        TableName: process.env.DYNAMODB_TABLE_NAME,
        Item: {
          PK: { S: dynamoRecord.PK },
          SK: { S: dynamoRecord.SK },
          audioFileKey: { S: dynamoRecord.audioFileKey },
          status: { S: dynamoRecord.status },
          createdAt: { S: dynamoRecord.createdAt },
          updatedAt: { S: dynamoRecord.updatedAt },
          retryCount: { N: dynamoRecord.retryCount.toString() },
        },
        ConditionExpression: 'attribute_not_exists(PK)', // Only create if doesn't exist
      });

      try {
        await dynamoClient.send(putCommand);
        console.log(`Created DynamoDB record for ${recordId}`);
      } catch (error: any) {
        if (error.name === 'ConditionalCheckFailedException') {
          console.log(`Record ${recordId} already exists, skipping duplicate processing`);
          continue;
        }
        throw error;
      }

      // Start transcription job
      const transcribeJobName = `speech-to-email-${recordId}-${Date.now()}`;
      const s3Uri = `s3://${bucketName}/${objectKey}`;

      const transcribeCommand = new StartTranscriptionJobCommand({
        TranscriptionJobName: transcribeJobName,
        Media: {
          MediaFileUri: s3Uri,
        },
        MediaFormat: getMediaFormat(objectKey),
        LanguageCode: 'en-US',
        OutputBucketName: bucketName,
        OutputKey: `transcriptions/${recordId}.json`,
        Settings: {
          MaxSpeakerLabels: 2,
          ShowSpeakerLabels: true,
        },
      });

      await transcribeClient.send(transcribeCommand);
      console.log(`Started transcription job: ${transcribeJobName}`);

      // Update DynamoDB record with transcription job name
      const updateCommand = new UpdateItemCommand({
        TableName: process.env.DYNAMODB_TABLE_NAME,
        Key: {
          PK: { S: recordId },
          SK: { S: 'RECORD' },
        },
        UpdateExpression: 'SET #status = :status, transcribeJobName = :jobName, updatedAt = :updatedAt',
        ExpressionAttributeNames: {
          '#status': 'status',
        },
        ExpressionAttributeValues: {
          ':status': { S: 'transcribing' },
          ':jobName': { S: transcribeJobName },
          ':updatedAt': { S: now },
        },
      });

      await dynamoClient.send(updateCommand);
      console.log(`Updated record status to transcribing for ${recordId}`);
    }

    return {
      statusCode: 200,
      body: JSON.stringify({ message: 'Upload processed successfully' }),
    };

  } catch (error) {
    console.error('Error processing upload:', error);
    
    // Update failed records in DynamoDB if possible
    for (const record of event.Records) {
      try {
        const objectKey = decodeURIComponent(record.s3.object.key.replace(/\+/g, ' '));
        const keyParts = objectKey.split('/');
        const fileName = keyParts[keyParts.length - 1];
        const recordId = fileName.split('.')[0];

        if (recordId) {
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
    }

    throw error;
  }
};

function getMediaFormat(objectKey: string): 'mp3' | 'wav' | 'm4a' | 'flac' | 'ogg' | 'amr' | 'webm' {
  const extension = objectKey.split('.').pop()?.toLowerCase();
  
  switch (extension) {
    case 'mp3':
      return 'mp3';
    case 'wav':
      return 'wav';
    case 'm4a':
      return 'm4a';
    case 'flac':
      return 'flac';
    case 'ogg':
      return 'ogg';
    case 'amr':
      return 'amr';
    case 'webm':
      return 'webm';
    default:
      return 'mp3'; // Default fallback
  }
}