import * as cdk from 'aws-cdk-lib';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as dynamodb from 'aws-cdk-lib/aws-dynamodb';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as logs from 'aws-cdk-lib/aws-logs';
import * as ses from 'aws-cdk-lib/aws-ses';
import * as events from 'aws-cdk-lib/aws-events';
import * as targets from 'aws-cdk-lib/aws-events-targets';
import * as s3n from 'aws-cdk-lib/aws-s3-notifications';
import * as apigateway from 'aws-cdk-lib/aws-apigateway';
import * as cloudfront from 'aws-cdk-lib/aws-cloudfront';
import * as origins from 'aws-cdk-lib/aws-cloudfront-origins';
import { Construct } from 'constructs';

export class SpeechToEmailStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // S3 bucket for audio file storage
    const audioStorageBucket = new s3.Bucket(this, 'AudioStorageBucket', {
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
    const webHostingBucket = new s3.Bucket(this, 'WebHostingBucket', {
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
    const speechProcessingTable = new dynamodb.Table(this, 'SpeechProcessingTable', {
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
    speechProcessingTable.addGlobalSecondaryIndex({
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
              resources: [`${audioStorageBucket.bucketArn}/*`],
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
                speechProcessingTable.tableArn,
                `${speechProcessingTable.tableArn}/index/*`,
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
    const uploadHandler = new lambda.Function(this, 'UploadHandler', {
      functionName: 'speech-to-email-upload-handler',
      runtime: lambda.Runtime.NODEJS_18_X,
      handler: 'index.handler',
      code: lambda.Code.fromAsset('lambda/upload-handler'),
      role: lambdaExecutionRole,
      timeout: cdk.Duration.seconds(30),
      environment: {
        DYNAMODB_TABLE_NAME: speechProcessingTable.tableName,
        AUDIO_BUCKET_NAME: audioStorageBucket.bucketName,
      },
    });

    // Email Handler Lambda
    const emailHandler = new lambda.Function(this, 'EmailHandler', {
      functionName: 'speech-to-email-email-handler',
      runtime: lambda.Runtime.NODEJS_18_X,
      handler: 'index.handler',
      code: lambda.Code.fromAsset('lambda/email-handler'),
      role: lambdaExecutionRole,
      timeout: cdk.Duration.seconds(30),
      environment: {
        DYNAMODB_TABLE_NAME: speechProcessingTable.tableName,
        RECIPIENT_EMAIL: 'johannes.koch@gmail.com',
        SENDER_EMAIL: 'noreply@speech-to-email.com', // This needs to be verified in SES
      },
    });

    // Transcription Handler Lambda
    const transcriptionHandler = new lambda.Function(this, 'TranscriptionHandler', {
      functionName: 'speech-to-email-transcription-handler',
      runtime: lambda.Runtime.NODEJS_18_X,
      handler: 'index.handler',
      code: lambda.Code.fromAsset('lambda/transcription-handler'),
      role: lambdaExecutionRole,
      timeout: cdk.Duration.seconds(60),
      environment: {
        DYNAMODB_TABLE_NAME: speechProcessingTable.tableName,
        AUDIO_BUCKET_NAME: audioStorageBucket.bucketName,
        EMAIL_HANDLER_FUNCTION_NAME: emailHandler.functionName,
      },
    });

    // Grant Lambda permission to invoke email handler
    emailHandler.grantInvoke(transcriptionHandler);

    // Presigned URL Handler Lambda
    const presignedUrlHandler = new lambda.Function(this, 'PresignedUrlHandler', {
      functionName: 'speech-to-email-presigned-url-handler',
      runtime: lambda.Runtime.NODEJS_18_X,
      handler: 'index.handler',
      code: lambda.Code.fromAsset('lambda/presigned-url-handler'),
      role: lambdaExecutionRole,
      timeout: cdk.Duration.seconds(30),
      environment: {
        AUDIO_BUCKET_NAME: audioStorageBucket.bucketName,
      },
    });

    // API Gateway for presigned URL generation
    const api = new apigateway.RestApi(this, 'SpeechToEmailApi', {
      restApiName: 'Speech to Email API',
      description: 'API for Speech to Email application',
      defaultCorsPreflightOptions: {
        allowOrigins: apigateway.Cors.ALL_ORIGINS,
        allowMethods: apigateway.Cors.ALL_METHODS,
        allowHeaders: ['Content-Type', 'X-Amz-Date', 'Authorization', 'X-Api-Key'],
      },
    });

    // API Gateway integration for presigned URL
    const presignedUrlIntegration = new apigateway.LambdaIntegration(presignedUrlHandler);
    const presignedUrlResource = api.root.addResource('presigned-url');
    presignedUrlResource.addMethod('POST', presignedUrlIntegration);

    // CloudFront distribution for Flutter web app
    const distribution = new cloudfront.Distribution(this, 'WebDistribution', {
      defaultBehavior: {
        origin: new origins.S3StaticWebsiteOrigin(webHostingBucket),
        viewerProtocolPolicy: cloudfront.ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
        allowedMethods: cloudfront.AllowedMethods.ALLOW_GET_HEAD,
        cachedMethods: cloudfront.CachedMethods.CACHE_GET_HEAD,
        compress: true,
        cachePolicy: cloudfront.CachePolicy.CACHING_OPTIMIZED,
      },
      additionalBehaviors: {
        '/api/*': {
          origin: new origins.RestApiOrigin(api),
          viewerProtocolPolicy: cloudfront.ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
          allowedMethods: cloudfront.AllowedMethods.ALLOW_ALL,
          cachedMethods: cloudfront.CachedMethods.CACHE_GET_HEAD,
          cachePolicy: cloudfront.CachePolicy.CACHING_DISABLED,
          originRequestPolicy: cloudfront.OriginRequestPolicy.CORS_S3_ORIGIN,
        },
      },
      defaultRootObject: 'index.html',
      errorResponses: [
        {
          httpStatus: 404,
          responseHttpStatus: 200,
          responsePagePath: '/index.html',
          ttl: cdk.Duration.minutes(30),
        },
        {
          httpStatus: 403,
          responseHttpStatus: 200,
          responsePagePath: '/index.html',
          ttl: cdk.Duration.minutes(30),
        },
      ],
      priceClass: cloudfront.PriceClass.PRICE_CLASS_100, // Use only North America and Europe
      comment: 'CloudFront distribution for Speech to Email Flutter app',
    });

    // S3 bucket notification to trigger upload handler
    audioStorageBucket.addEventNotification(
      s3.EventType.OBJECT_CREATED,
      new s3n.LambdaDestination(uploadHandler)
    );

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

    transcribeRule.addTarget(new targets.LambdaFunction(transcriptionHandler));

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

    // SES configuration (basic setup - email verification needed manually)
    new ses.CfnConfigurationSet(this, 'SESConfigurationSet', {
      name: 'speech-to-email-config-set',
    });

    // Output important values
    new cdk.CfnOutput(this, 'AudioBucketName', {
      value: audioStorageBucket.bucketName,
      description: 'Name of the S3 bucket for audio storage',
    });

    new cdk.CfnOutput(this, 'WebBucketName', {
      value: webHostingBucket.bucketName,
      description: 'Name of the S3 bucket for web hosting',
    });

    new cdk.CfnOutput(this, 'DynamoDBTableName', {
      value: speechProcessingTable.tableName,
      description: 'Name of the DynamoDB table for processing records',
    });

    new cdk.CfnOutput(this, 'UploadHandlerArn', {
      value: uploadHandler.functionArn,
      description: 'ARN of the Upload Handler Lambda function',
    });

    new cdk.CfnOutput(this, 'TranscriptionHandlerArn', {
      value: transcriptionHandler.functionArn,
      description: 'ARN of the Transcription Handler Lambda function',
    });

    new cdk.CfnOutput(this, 'EmailHandlerArn', {
      value: emailHandler.functionArn,
      description: 'ARN of the Email Handler Lambda function',
    });

    new cdk.CfnOutput(this, 'PresignedUrlHandlerArn', {
      value: presignedUrlHandler.functionArn,
      description: 'ARN of the Presigned URL Handler Lambda function',
    });

    new cdk.CfnOutput(this, 'ApiGatewayUrl', {
      value: api.url,
      description: 'URL of the API Gateway',
    });

    new cdk.CfnOutput(this, 'CloudFrontDistributionId', {
      value: distribution.distributionId,
      description: 'CloudFront Distribution ID',
    });

    new cdk.CfnOutput(this, 'CloudFrontDomainName', {
      value: distribution.distributionDomainName,
      description: 'CloudFront Distribution Domain Name',
    });

    new cdk.CfnOutput(this, 'WebsiteUrl', {
      value: `https://${distribution.distributionDomainName}`,
      description: 'Website URL',
    });
  }
}