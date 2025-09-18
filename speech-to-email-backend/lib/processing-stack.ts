import * as cdk from 'aws-cdk-lib';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as ses from 'aws-cdk-lib/aws-ses';
import * as events from 'aws-cdk-lib/aws-events';
import * as targets from 'aws-cdk-lib/aws-events-targets';
import * as s3n from 'aws-cdk-lib/aws-s3-notifications';
import { Construct } from 'constructs';
import { StorageStack } from './storage-stack';

interface ProcessingStackProps extends cdk.StackProps {
  storageStack: StorageStack;
}

export class ProcessingStack extends cdk.Stack {
  public readonly uploadHandler: lambda.Function;
  public readonly transcriptionHandler: lambda.Function;
  public readonly emailHandler: lambda.Function;

  constructor(scope: Construct, id: string, props: ProcessingStackProps) {
    super(scope, id, props);

    const { storageStack } = props;

    // IAM role for Lambda functions with comprehensive permissions
    const lambdaExecutionRole = new iam.Role(this, 'LambdaExecutionRole', {
      assumedBy: new iam.ServicePrincipal('lambda.amazonaws.com'),
      managedPolicies: [
        iam.ManagedPolicy.fromAwsManagedPolicyName('service-role/AWSLambdaBasicExecutionRole'),
      ],
      inlinePolicies: {
        S3Policy: new iam.PolicyDocument({
          statements: [
            new iam.PolicyStatement({
              effect: iam.Effect.ALLOW,
              actions: ['s3:GetObject', 's3:PutObject', 's3:DeleteObject'],
              resources: [`${storageStack.audioStorageBucket.bucketArn}/*`],
            }),
          ],
        }),
        DynamoDBPolicy: new iam.PolicyDocument({
          statements: [
            new iam.PolicyStatement({
              effect: iam.Effect.ALLOW,
              actions: [
                'dynamodb:PutItem',
                'dynamodb:GetItem',
                'dynamodb:UpdateItem',
                'dynamodb:Query',
                'dynamodb:Scan',
              ],
              resources: [
                storageStack.speechProcessingTable.tableArn,
                `${storageStack.speechProcessingTable.tableArn}/index/*`,
              ],
            }),
          ],
        }),
        TranscribePolicy: new iam.PolicyDocument({
          statements: [
            new iam.PolicyStatement({
              effect: iam.Effect.ALLOW,
              actions: [
                'transcribe:StartTranscriptionJob',
                'transcribe:GetTranscriptionJob',
                'transcribe:ListTranscriptionJobs',
              ],
              resources: ['*'],
            }),
          ],
        }),
        SESPolicy: new iam.PolicyDocument({
          statements: [
            new iam.PolicyStatement({
              effect: iam.Effect.ALLOW,
              actions: ['ses:SendEmail', 'ses:SendRawEmail'],
              resources: ['*'],
            }),
          ],
        }),
      },
    });

    // Upload Handler Lambda
    this.uploadHandler = new lambda.Function(this, 'UploadHandler', {
      functionName: 'speech-to-email-upload-handler',
      runtime: lambda.Runtime.NODEJS_18_X,
      handler: 'index.handler',
      code: lambda.Code.fromAsset('lambda/upload-handler'),
      role: lambdaExecutionRole,
      timeout: cdk.Duration.seconds(30),
      environment: {
        DYNAMODB_TABLE_NAME: storageStack.speechProcessingTable.tableName,
        AUDIO_BUCKET_NAME: storageStack.audioStorageBucket.bucketName,
      },
    });

    // Transcription Handler Lambda
    this.transcriptionHandler = new lambda.Function(this, 'TranscriptionHandler', {
      functionName: 'speech-to-email-transcription-handler',
      runtime: lambda.Runtime.NODEJS_18_X,
      handler: 'index.handler',
      code: lambda.Code.fromAsset('lambda/transcription-handler'),
      role: lambdaExecutionRole,
      timeout: cdk.Duration.seconds(60),
      environment: {
        DYNAMODB_TABLE_NAME: storageStack.speechProcessingTable.tableName,
        AUDIO_BUCKET_NAME: storageStack.audioStorageBucket.bucketName,
        EMAIL_HANDLER_FUNCTION_NAME: '', // Will be set after email handler is created
      },
    });

    // Email Handler Lambda
    this.emailHandler = new lambda.Function(this, 'EmailHandler', {
      functionName: 'speech-to-email-email-handler',
      runtime: lambda.Runtime.NODEJS_18_X,
      handler: 'index.handler',
      code: lambda.Code.fromAsset('lambda/email-handler'),
      role: lambdaExecutionRole,
      timeout: cdk.Duration.seconds(30),
      environment: {
        DYNAMODB_TABLE_NAME: storageStack.speechProcessingTable.tableName,
        RECIPIENT_EMAIL: 'johannes.koch@gmail.com',
        SENDER_EMAIL: 'noreply@speech-to-email.com', // This needs to be verified in SES
      },
    });

    // Update transcription handler environment with email handler function name
    this.transcriptionHandler.addEnvironment(
      'EMAIL_HANDLER_FUNCTION_NAME',
      this.emailHandler.functionName
    );

    // Grant Lambda permission to invoke email handler
    this.emailHandler.grantInvoke(this.transcriptionHandler);

    // S3 bucket notification to trigger upload handler
    // Note: This creates a circular dependency, so we'll set it up after deployment
    // or use a custom resource to configure it

    // EventBridge rule for Transcribe job completion
    const transcribeRule = new events.Rule(this, 'TranscribeCompletionRule', {
      eventPattern: {
        source: ['aws.transcribe'],
        detailType: ['Transcribe Job State Change'],
        detail: {
          TranscriptionJobStatus: ['COMPLETED', 'FAILED'],
        },
      },
    });

    transcribeRule.addTarget(new targets.LambdaFunction(this.transcriptionHandler));

    // SES configuration (basic setup - email verification needed manually)
    new ses.CfnConfigurationSet(this, 'SESConfigurationSet', {
      name: 'speech-to-email-config-set',
    });

    // Output Lambda function ARNs
    new cdk.CfnOutput(this, 'UploadHandlerArn', {
      value: this.uploadHandler.functionArn,
      description: 'ARN of the Upload Handler Lambda function',
    });

    new cdk.CfnOutput(this, 'TranscriptionHandlerArn', {
      value: this.transcriptionHandler.functionArn,
      description: 'ARN of the Transcription Handler Lambda function',
    });

    new cdk.CfnOutput(this, 'EmailHandlerArn', {
      value: this.emailHandler.functionArn,
      description: 'ARN of the Email Handler Lambda function',
    });
  }
}