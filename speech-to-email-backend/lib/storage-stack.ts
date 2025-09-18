import * as cdk from 'aws-cdk-lib';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as dynamodb from 'aws-cdk-lib/aws-dynamodb';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as logs from 'aws-cdk-lib/aws-logs';
import { Construct } from 'constructs';

export class StorageStack extends cdk.Stack {
  public readonly audioStorageBucket: s3.Bucket;
  public readonly webHostingBucket: s3.Bucket;
  public readonly speechProcessingTable: dynamodb.Table;
  public readonly uploadRole: iam.Role;

  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // S3 bucket for audio file storage
    this.audioStorageBucket = new s3.Bucket(this, 'AudioStorageBucket', {
      bucketName: `speech-to-email-audio-${this.account}-${this.region}`,
      encryption: s3.BucketEncryption.S3_MANAGED,
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
      lifecycleRules: [
        {
          id: 'DeleteAudioFilesAfter7Days',
          enabled: true,
          expiration: cdk.Duration.days(7),
        },
      ],
      cors: [
        {
          allowedMethods: [s3.HttpMethods.PUT, s3.HttpMethods.POST],
          allowedOrigins: ['*'], // Will be restricted in production
          allowedHeaders: ['*'],
          maxAge: 3000,
        },
      ],
      removalPolicy: cdk.RemovalPolicy.DESTROY, // For development
    });

    // S3 bucket for Flutter web app hosting
    this.webHostingBucket = new s3.Bucket(this, 'WebHostingBucket', {
      bucketName: `speech-to-email-web-${this.account}-${this.region}`,
      websiteIndexDocument: 'index.html',
      websiteErrorDocument: 'index.html',
      publicReadAccess: true,
      blockPublicAccess: new s3.BlockPublicAccess({
        blockPublicAcls: false,
        blockPublicPolicy: false,
        ignorePublicAcls: false,
        restrictPublicBuckets: false,
      }),
      removalPolicy: cdk.RemovalPolicy.DESTROY, // For development
    });

    // DynamoDB table for speech processing records
    this.speechProcessingTable = new dynamodb.Table(this, 'SpeechProcessingTable', {
      tableName: 'SpeechProcessingRecords',
      partitionKey: {
        name: 'PK',
        type: dynamodb.AttributeType.STRING,
      },
      sortKey: {
        name: 'SK',
        type: dynamodb.AttributeType.STRING,
      },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      encryption: dynamodb.TableEncryption.AWS_MANAGED,
      pointInTimeRecoverySpecification: {
        pointInTimeRecoveryEnabled: true,
      },
      removalPolicy: cdk.RemovalPolicy.DESTROY, // For development
    });

    // Add GSI for status queries
    this.speechProcessingTable.addGlobalSecondaryIndex({
      indexName: 'StatusIndex',
      partitionKey: {
        name: 'status',
        type: dynamodb.AttributeType.STRING,
      },
      sortKey: {
        name: 'createdAt',
        type: dynamodb.AttributeType.STRING,
      },
    });

    // IAM role for presigned URL generation
    this.uploadRole = new iam.Role(this, 'UploadRole', {
      assumedBy: new iam.ServicePrincipal('lambda.amazonaws.com'),
      managedPolicies: [
        iam.ManagedPolicy.fromAwsManagedPolicyName('service-role/AWSLambdaBasicExecutionRole'),
      ],
      inlinePolicies: {
        S3UploadPolicy: new iam.PolicyDocument({
          statements: [
            new iam.PolicyStatement({
              effect: iam.Effect.ALLOW,
              actions: ['s3:PutObject', 's3:PutObjectAcl'],
              resources: [`${this.audioStorageBucket.bucketArn}/*`],
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
              ],
              resources: [
                this.speechProcessingTable.tableArn,
                `${this.speechProcessingTable.tableArn}/index/*`,
              ],
            }),
          ],
        }),
      },
    });

    // CloudWatch log groups
    new logs.LogGroup(this, 'UploadHandlerLogGroup', {
      logGroupName: '/aws/lambda/speech-to-email-upload-handler',
      retention: logs.RetentionDays.ONE_WEEK,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
    });

    new logs.LogGroup(this, 'TranscriptionHandlerLogGroup', {
      logGroupName: '/aws/lambda/speech-to-email-transcription-handler',
      retention: logs.RetentionDays.ONE_WEEK,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
    });

    new logs.LogGroup(this, 'EmailHandlerLogGroup', {
      logGroupName: '/aws/lambda/speech-to-email-email-handler',
      retention: logs.RetentionDays.ONE_WEEK,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
    });

    // Output important values
    new cdk.CfnOutput(this, 'AudioBucketName', {
      value: this.audioStorageBucket.bucketName,
      description: 'Name of the S3 bucket for audio storage',
    });

    new cdk.CfnOutput(this, 'WebBucketName', {
      value: this.webHostingBucket.bucketName,
      description: 'Name of the S3 bucket for web hosting',
    });

    new cdk.CfnOutput(this, 'DynamoDBTableName', {
      value: this.speechProcessingTable.tableName,
      description: 'Name of the DynamoDB table for processing records',
    });
  }
}