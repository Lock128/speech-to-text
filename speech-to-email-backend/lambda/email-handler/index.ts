import { Context } from 'aws-lambda';
import { SESClient, SendEmailCommand } from '@aws-sdk/client-ses';
import { DynamoDBClient, UpdateItemCommand } from '@aws-sdk/client-dynamodb';
import { S3Client, GetObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';

const sesClient = new SESClient({ region: process.env.AWS_REGION });
const dynamoClient = new DynamoDBClient({ region: process.env.AWS_REGION });
const s3Client = new S3Client({ region: process.env.AWS_REGION });

interface EmailPayload {
  enhancedArticleText: string;
  originalTranscription: string;
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

  if (event.enhancedArticleText !== undefined) {
    // Direct payload format
    emailPayload = event as EmailPayload;
  } else {
    // This shouldn't happen, but let's log it
    console.error('Unexpected event format - no enhancedArticleText found');
    console.error('Full event:', JSON.stringify(event, null, 2));
    throw new Error('Invalid event format - missing enhancedArticleText');
  }

  const { enhancedArticleText, originalTranscription, originalFileName, timestamp, recordId, audioFileKey } = emailPayload;

  console.log('Received enhanced article text:', `"${enhancedArticleText}"`);
  console.log('Enhanced article text length:', enhancedArticleText?.length || 0);
  console.log('Audio file key:', audioFileKey);
  const maxRetries = 3;
  let retryCount = 0;

  while (retryCount < maxRetries) {
    try {
      // Debug: Check enhanced article text
      console.log('About to format email with enhanced article:', {
        hasEnhancedArticleText: !!enhancedArticleText,
        enhancedArticleLength: enhancedArticleText?.length || 0,
        enhancedArticlePreview: enhancedArticleText?.substring(0, 50) || 'EMPTY',
        hasOriginalTranscription: !!originalTranscription,
        originalTranscriptionLength: originalTranscription?.length || 0
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
      const subject = `Zeitungsartikel: ${originalFileName} - ${new Date(timestamp).toLocaleString()}`;

      const htmlBody = `
        <html>
          <head>
            <style>
              body { font-family: 'Georgia', 'Times New Roman', serif; line-height: 1.6; color: #333; max-width: 800px; margin: 0 auto; }
              .header { background-color: #f4f4f4; padding: 20px; border-radius: 5px; margin-bottom: 20px; text-align: center; }
              .content { padding: 20px; }
              .article { background-color: #fff; padding: 20px; border: 1px solid #ddd; margin: 20px 0; }
              .original-transcription { background-color: #f9f9f9; padding: 15px; border-left: 4px solid #007bff; margin: 20px 0; font-size: 0.9em; }
              .footer { font-size: 12px; color: #666; margin-top: 30px; padding-top: 20px; border-top: 1px solid #eee; }
              .metadata { background-color: #e9ecef; padding: 10px; border-radius: 3px; margin-bottom: 20px; font-size: 0.9em; }
              .article h1, .article h2, .article h3 { color: #2c3e50; }
              .article p { margin-bottom: 1em; text-align: justify; }
            </style>
          </head>
          <body>
            <div class="header">
              <h2>📰 KI-generierter Blogeintrag</h2>
              <p style="margin: 0; font-style: italic;">Automatisch erstellt aus Sprachaufnahme</p>
            </div>
            
            <div class="content">
              <div class="metadata">
                <strong>Datei:</strong> ${originalFileName}<br>
                <strong>Aufgenommen:</strong> ${new Date(timestamp).toLocaleString()}<br>
                <strong>Blog-ID:</strong> ${recordId}<br>
                <strong>Verarbeitet:</strong> ${new Date().toLocaleString()}
              </div>
              
              <div class="article">
                ${enhancedArticleText || 'Kein Blog verfügbar'}
              </div>
              
              <details>
                <summary style="cursor: pointer; font-weight: bold; margin: 20px 0 10px 0;">📝 Original-Transkription anzeigen</summary>
                <div class="original-transcription">
                  <strong>Original-Transkription:</strong><br>
                  ${originalTranscription ? originalTranscription.replace(/</g, '&lt;').replace(/>/g, '&gt;') : 'Keine Transkription verfügbar'}
                </div>
              </details>
              
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
                <p>Diese E-Mail wurde automatisch von der Speech-to-Email-Anwendung mit KI-Unterstützung generiert.</p>
                <p>Bei Fragen oder Problemen wenden Sie sich bitte an Ihren Systemadministrator.</p>
              </div>
            </div>
          </body>
        </html>
      `;

      const textBody = `
KI-generierter Blogeintrag

Datei: ${originalFileName}
Aufgenommen: ${new Date(timestamp).toLocaleString()}
Blog-ID: ${recordId}
Verarbeitet: ${new Date().toLocaleString()}

ARTIKEL:
${enhancedArticleText || 'Kein Blog verfügbar'}

ORIGINAL-TRANSKRIPTION:
${originalTranscription || 'Keine Transkription verfügbar'}

${audioFileUrl ? `
Audio-Datei:
Hören Sie sich die ursprüngliche Aufnahme an: ${audioFileUrl}
(Hinweis: Dieser Link läuft aus Sicherheitsgründen in 7 Tagen ab.)
` : ''}

---
Diese E-Mail wurde automatisch von der Speech-to-Email-Anwendung mit KI-Unterstützung generiert.
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