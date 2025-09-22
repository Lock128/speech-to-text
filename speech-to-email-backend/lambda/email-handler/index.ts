import { Context } from 'aws-lambda';
import { SESClient, SendEmailCommand } from '@aws-sdk/client-ses';
import { DynamoDBClient, UpdateItemCommand } from '@aws-sdk/client-dynamodb';
import { S3Client, GetObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';

const sesClient = new SESClient({ region: process.env.AWS_REGION });
const dynamoClient = new DynamoDBClient({ region: process.env.AWS_REGION });
const s3Client = new S3Client({ region: process.env.AWS_REGION });

interface EmailPayload {
  transcriptionText: string;
  originalFileName: string;
  timestamp: string;
  recordId: string;
  audioFileKey: string;
}

export const handler = async (event: any, context: Context) => {
  console.log('Email handler triggered:', JSON.stringify(event, null, 2));
  console.log('Event type:', typeof event);
  console.log('Event keys:', Object.keys(event || {}));

  // Handle both direct invocation and async invocation formats
  let emailPayload: EmailPayload;

  if (event.transcriptionText !== undefined) {
    // Direct payload format
    emailPayload = event as EmailPayload;
  } else {
    // This shouldn't happen, but let's log it
    console.error('Unexpected event format - no transcriptionText found');
    console.error('Full event:', JSON.stringify(event, null, 2));
    throw new Error('Invalid event format - missing transcriptionText');
  }

  const { transcriptionText, originalFileName, timestamp, recordId, audioFileKey } = emailPayload;

  console.log('Received transcription text:', `"${transcriptionText}"`);
  console.log('Transcription text length:', transcriptionText?.length || 0);
  console.log('Audio file key:', audioFileKey);
  const maxRetries = 3;
  let retryCount = 0;

  while (retryCount < maxRetries) {
    try {
      // Debug: Check transcription text
      console.log('About to format email with transcription:', {
        hasTranscriptionText: !!transcriptionText,
        transcriptionLength: transcriptionText?.length || 0,
        transcriptionPreview: transcriptionText?.substring(0, 50) || 'EMPTY'
      });

      // Generate presigned URL for audio file (valid for 7 days)
      let audioFileUrl = '';
      if (audioFileKey) {
        try {
          const getObjectCommand = new GetObjectCommand({
            Bucket: process.env.AUDIO_BUCKET_NAME,
            Key: audioFileKey,
          });
          audioFileUrl = await getSignedUrl(s3Client, getObjectCommand, { expiresIn: 7 * 24 * 3600 }); // 7 days
          console.log('Generated audio file URL for:', audioFileKey);
        } catch (error) {
          console.error('Error generating audio file URL:', error);
        }
      }

      // Format the email content
      const subject = `Speech to Email: ${originalFileName} - ${new Date(timestamp).toLocaleString()}`;

      const htmlBody = `
        <html>
          <head>
            <style>
              body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
              .header { background-color: #f4f4f4; padding: 20px; border-radius: 5px; margin-bottom: 20px; }
              .content { padding: 20px; }
              .transcription { background-color: #f9f9f9; padding: 15px; border-left: 4px solid #007bff; margin: 20px 0; }
              .footer { font-size: 12px; color: #666; margin-top: 30px; padding-top: 20px; border-top: 1px solid #eee; }
              .metadata { background-color: #e9ecef; padding: 10px; border-radius: 3px; margin-bottom: 20px; }
            </style>
          </head>
          <body>
            <div class="header">
              <h2>🎤 Speech to Email Transcription</h2>
            </div>
            
            <div class="content">
              <div class="metadata">
                <strong>File:</strong> ${originalFileName}<br>
                <strong>Recorded:</strong> ${new Date(timestamp).toLocaleString()}<br>
                <strong>Record ID:</strong> ${recordId}<br>
                <strong>Processed:</strong> ${new Date().toLocaleString()}
              </div>
              
              <h3>Transcription:</h3>
              <div class="transcription">
                ${transcriptionText ? transcriptionText.replace(/</g, '&lt;').replace(/>/g, '&gt;') : 'No transcription available'}
              </div>
              
              ${audioFileUrl ? `
              <h3>Audio File:</h3>
              <div style="margin: 20px 0;">
                <a href="${audioFileUrl}" style="display: inline-block; background-color: #007bff; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; font-weight: bold;">
                  🎵 Listen to Original Recording
                </a>
                <p style="font-size: 12px; color: #666; margin-top: 10px;">
                  <em>Note: This link will expire in 7 days for security reasons.</em>
                </p>
              </div>
              ` : ''}
              
              <div class="footer">
                <p>This email was automatically generated by the Speech to Email application.</p>
                <p>If you have any questions or issues, please contact your system administrator.</p>
              </div>
            </div>
          </body>
        </html>
      `;

      const textBody = `
Speech to Email Transcription

File: ${originalFileName}
Recorded: ${new Date(timestamp).toLocaleString()}
Record ID: ${recordId}
Processed: ${new Date().toLocaleString()}

Transcription:
${transcriptionText || 'No transcription available'}

${audioFileUrl ? `
Audio File:
Listen to the original recording: ${audioFileUrl}
(Note: This link will expire in 7 days for security reasons.)
` : ''}

---
This email was automatically generated by the Speech to Email application.
      `;

      // Send email using SES
      const sendEmailCommand = new SendEmailCommand({
        Source: process.env.SENDER_EMAIL,
        Destination: {
          ToAddresses: process.env.RECIPIENT_EMAIL!.split(',').map(email => email.trim()),
        },
        Message: {
          Subject: {
            Data: subject,
            Charset: 'UTF-8',
          },
          Body: {
            Html: {
              Data: htmlBody,
              Charset: 'UTF-8',
            },
            Text: {
              Data: textBody,
              Charset: 'UTF-8',
            },
          },
        },
        ConfigurationSetName: 'speech-to-email-config-set',
      });

      const result = await sesClient.send(sendEmailCommand);
      console.log('Email sent successfully:', result.MessageId);

      // Update DynamoDB record with success status
      const updateCommand = new UpdateItemCommand({
        TableName: process.env.DYNAMODB_TABLE_NAME,
        Key: {
          PK: { S: recordId },
          SK: { S: 'RECORD' },
        },
        UpdateExpression: 'SET #status = :status, emailSentAt = :emailSentAt, updatedAt = :updatedAt, emailMessageId = :messageId',
        ExpressionAttributeNames: {
          '#status': 'status',
        },
        ExpressionAttributeValues: {
          ':status': { S: 'email_sent' },
          ':emailSentAt': { S: new Date().toISOString() },
          ':updatedAt': { S: new Date().toISOString() },
          ':messageId': { S: result.MessageId || 'unknown' },
        },
      });

      await dynamoClient.send(updateCommand);
      console.log(`Updated record status to email_sent for ${recordId}`);

      return {
        statusCode: 200,
        body: JSON.stringify({
          message: 'Email sent successfully',
          messageId: result.MessageId,
          recordId,
        }),
      };

    } catch (error) {
      retryCount++;
      console.error(`Email sending attempt ${retryCount} failed:`, error);

      if (retryCount >= maxRetries) {
        // Update DynamoDB record with failure status
        try {
          const updateCommand = new UpdateItemCommand({
            TableName: process.env.DYNAMODB_TABLE_NAME,
            Key: {
              PK: { S: recordId },
              SK: { S: 'RECORD' },
            },
            UpdateExpression: 'SET #status = :status, errorMessage = :error, updatedAt = :updatedAt, retryCount = :retryCount',
            ExpressionAttributeNames: {
              '#status': 'status',
            },
            ExpressionAttributeValues: {
              ':status': { S: 'failed' },
              ':error': { S: error instanceof Error ? error.message : 'Email sending failed' },
              ':updatedAt': { S: new Date().toISOString() },
              ':retryCount': { N: retryCount.toString() },
            },
          });

          await dynamoClient.send(updateCommand);
          console.log(`Updated record status to failed after ${retryCount} retries for ${recordId}`);
        } catch (updateError) {
          console.error('Error updating failed record:', updateError);
        }

        throw error;
      }

      // Wait before retry (exponential backoff)
      const waitTime = Math.pow(2, retryCount) * 1000; // 2s, 4s, 8s
      console.log(`Waiting ${waitTime}ms before retry ${retryCount + 1}`);
      await new Promise(resolve => setTimeout(resolve, waitTime));
    }
  }

  // This should never be reached due to the throw in the catch block
  return {
    statusCode: 500,
    body: JSON.stringify({ message: 'Unexpected error in email handler' }),
  };
};