import { SNSEvent, Context } from 'aws-lambda';
import { DynamoDBClient, UpdateItemCommand } from '@aws-sdk/client-dynamodb';

const dynamoClient = new DynamoDBClient({ region: process.env.AWS_REGION });

interface SESBounceNotification {
  notificationType: 'Bounce' | 'Complaint';
  bounce?: {
    bounceType: string;
    bounceSubType: string;
    bouncedRecipients: Array<{
      emailAddress: string;
      status: string;
      action: string;
      diagnosticCode: string;
    }>;
  };
  complaint?: {
    complainedRecipients: Array<{
      emailAddress: string;
    }>;
    complaintFeedbackType: string;
  };
  mail: {
    messageId: string;
    timestamp: string;
    source: string;
    destination: string[];
  };
}

export const handler = async (event: SNSEvent, context: Context) => {
  console.log('SES notification handler triggered:', JSON.stringify(event, null, 2));

  try {
    for (const record of event.Records) {
      const message = JSON.parse(record.Sns.Message) as SESBounceNotification;
      
      console.log('Processing SES notification:', message.notificationType);

      if (message.notificationType === 'Bounce') {
        await handleBounce(message);
      } else if (message.notificationType === 'Complaint') {
        await handleComplaint(message);
      }
    }

    return {
      statusCode: 200,
      body: JSON.stringify({ message: 'SES notifications processed successfully' }),
    };

  } catch (error) {
    console.error('Error processing SES notifications:', error);
    throw error;
  }
};

async function handleBounce(notification: SESBounceNotification) {
  const { bounce, mail } = notification;
  
  if (!bounce) return;

  console.log(`Processing bounce for message ${mail.messageId}:`, bounce.bounceType);

  // Log bounce details
  console.log('Bounce details:', {
    bounceType: bounce.bounceType,
    bounceSubType: bounce.bounceSubType,
    recipients: bounce.bouncedRecipients.map(r => r.emailAddress),
  });

  // For permanent bounces, we might want to update our records
  if (bounce.bounceType === 'Permanent') {
    console.warn('Permanent bounce detected for recipients:', 
      bounce.bouncedRecipients.map(r => r.emailAddress));
    
    // Here you could implement logic to:
    // 1. Mark email addresses as invalid
    // 2. Update user records
    // 3. Send alerts to administrators
  }
}

async function handleComplaint(notification: SESBounceNotification) {
  const { complaint, mail } = notification;
  
  if (!complaint) return;

  console.log(`Processing complaint for message ${mail.messageId}`);

  // Log complaint details
  console.log('Complaint details:', {
    complaintFeedbackType: complaint.complaintFeedbackType,
    recipients: complaint.complainedRecipients.map(r => r.emailAddress),
  });

  // For complaints, we should take immediate action
  console.warn('Complaint received from recipients:', 
    complaint.complainedRecipients.map(r => r.emailAddress));
  
  // Here you could implement logic to:
  // 1. Suppress future emails to complainants
  // 2. Alert administrators
  // 3. Review email content and sending practices
}