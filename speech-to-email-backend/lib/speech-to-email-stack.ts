import * as cdk from 'aws-cdk-lib';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as dynamodb from 'aws-cdk-lib/aws-dynamodb';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as nodejs from 'aws-cdk-lib/aws-lambda-nodejs';
import * as iam from 'aws-cdk-lib/aws-iam';

import * as events from 'aws-cdk-lib/aws-events';
import * as targets from 'aws-cdk-lib/aws-events-targets';
import * as s3n from 'aws-cdk-lib/aws-s3-notifications';
import * as apigateway from 'aws-cdk-lib/aws-apigateway';
import * as cloudfront from 'aws-cdk-lib/aws-cloudfront';
import * as origins from 'aws-cdk-lib/aws-cloudfront-origins';
import * as sns from 'aws-cdk-lib/aws-sns';
import * as subscriptions from 'aws-cdk-lib/aws-sns-subscriptions';
import * as sqs from 'aws-cdk-lib/aws-sqs';
import * as cloudwatch from 'aws-cdk-lib/aws-cloudwatch';
import * as ses from 'aws-cdk-lib/aws-ses';

import * as kms from 'aws-cdk-lib/aws-kms';
import { Construct } from 'constructs';

export class SpeechToEmailStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // KMS Key for encryption
    const encryptionKey = new kms.Key(this, 'EncryptionKey', {
      description: 'KMS key for Speech to Email application encryption',
      enableKeyRotation: true,
      removalPolicy: cdk.RemovalPolicy.DESTROY, // For development
    });

    // KMS Key Alias
    new kms.Alias(this, 'EncryptionKeyAlias', {
      aliasName: 'alias/speech-to-email-key',
      targetKey: encryptionKey,
    });

    // S3 bucket for audio file storage
    const audioStorageBucket = new s3.Bucket(this, 'AudioStorageBucket', {
      bucketName: `speech-to-email-audio-${this.account}-${this.region}`,
      encryption: s3.BucketEncryption.KMS,
      encryptionKey: encryptionKey,
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
      versioned: true,
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
      encryption: dynamodb.TableEncryption.CUSTOMER_MANAGED,
      encryptionKey: encryptionKey,
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

    // Dead Letter Queue for failed Lambda executions
    const deadLetterQueue = new sqs.Queue(this, 'DeadLetterQueue', {
      queueName: 'speech-to-email-dlq',
      retentionPeriod: cdk.Duration.days(14),
      encryption: sqs.QueueEncryption.KMS,
      encryptionMasterKey: encryptionKey,
    });

    // Create individual IAM roles for each Lambda function to avoid circular dependencies

    // Upload Handler Role
    const uploadHandlerRole = new iam.Role(this, 'UploadHandlerRole', {
      assumedBy: new iam.ServicePrincipal('lambda.amazonaws.com'),
      managedPolicies: [
        iam.ManagedPolicy.fromAwsManagedPolicyName('service-role/AWSLambdaBasicExecutionRole'),
      ],
    });

    // Presigned URL Handler Role
    const presignedUrlHandlerRole = new iam.Role(this, 'PresignedUrlHandlerRole', {
      assumedBy: new iam.ServicePrincipal('lambda.amazonaws.com'),
      managedPolicies: [
        iam.ManagedPolicy.fromAwsManagedPolicyName('service-role/AWSLambdaBasicExecutionRole'),
      ],
    });

    // Status Handler Role
    const statusHandlerRole = new iam.Role(this, 'StatusHandlerRole', {
      assumedBy: new iam.ServicePrincipal('lambda.amazonaws.com'),
      managedPolicies: [
        iam.ManagedPolicy.fromAwsManagedPolicyName('service-role/AWSLambdaBasicExecutionRole'),
      ],
    });

    // Transcription Handler Role
    const transcriptionHandlerRole = new iam.Role(this, 'TranscriptionHandlerRole', {
      assumedBy: new iam.ServicePrincipal('lambda.amazonaws.com'),
      managedPolicies: [
        iam.ManagedPolicy.fromAwsManagedPolicyName('service-role/AWSLambdaBasicExecutionRole'),
      ],
    });

    // Article Enhancement Handler Role
    const articleEnhancementHandlerRole = new iam.Role(this, 'ArticleEnhancementHandlerRole', {
      assumedBy: new iam.ServicePrincipal('lambda.amazonaws.com'),
      managedPolicies: [
        iam.ManagedPolicy.fromAwsManagedPolicyName('service-role/AWSLambdaBasicExecutionRole'),
      ],
    });

    // Email Handler Role
    const emailHandlerRole = new iam.Role(this, 'EmailHandlerRole', {
      assumedBy: new iam.ServicePrincipal('lambda.amazonaws.com'),
      managedPolicies: [
        iam.ManagedPolicy.fromAwsManagedPolicyName('service-role/AWSLambdaBasicExecutionRole'),
      ],
    });

    // SES Notification Handler Role
    const sesNotificationHandlerRole = new iam.Role(this, 'SESNotificationHandlerRole', {
      assumedBy: new iam.ServicePrincipal('lambda.amazonaws.com'),
      managedPolicies: [
        iam.ManagedPolicy.fromAwsManagedPolicyName('service-role/AWSLambdaBasicExecutionRole'),
      ],
    });

    // Upload Handler Lambda
    const uploadHandler = new nodejs.NodejsFunction(this, 'UploadHandler', {
      functionName: 'speech-to-email-upload-handler',
      runtime: lambda.Runtime.NODEJS_18_X,
      entry: 'lambda/upload-handler/index.ts',
      handler: 'handler',
      role: uploadHandlerRole,
      timeout: cdk.Duration.seconds(30),
      retryAttempts: 2,
      deadLetterQueue: deadLetterQueue,
      environment: {
        DYNAMODB_TABLE_NAME: speechProcessingTable.tableName,
        AUDIO_BUCKET_NAME: audioStorageBucket.bucketName,
      },
      bundling: {
        externalModules: ['aws-sdk'],
        minify: true,
        sourceMap: false,
      },
    });

    // Grant permissions to Upload Handler
    speechProcessingTable.grantReadWriteData(uploadHandler);
    audioStorageBucket.grantReadWrite(uploadHandler);
    uploadHandlerRole.addToPolicy(new iam.PolicyStatement({
      effect: iam.Effect.ALLOW,
      actions: [
        'transcribe:StartTranscriptionJob',
        'transcribe:GetTranscriptionJob',
        'transcribe:ListTranscriptionJobs',
      ],
      resources: ['*'],
    }));

    // Article Enhancement Handler Lambda
    const articleEnhancementHandler = new nodejs.NodejsFunction(this, 'ArticleEnhancementHandler', {
      functionName: 'speech-to-email-article-enhancement-handler',
      runtime: lambda.Runtime.NODEJS_18_X,
      entry: 'lambda/article-enhancement-handler/index.ts',
      handler: 'handler',
      role: articleEnhancementHandlerRole,
      timeout: cdk.Duration.seconds(120), // Longer timeout for Bedrock calls
      retryAttempts: 2,
      deadLetterQueue: deadLetterQueue,
      environment: {
        DYNAMODB_TABLE_NAME: speechProcessingTable.tableName,
      },
      bundling: {
        externalModules: ['aws-sdk'],
        minify: true,
        sourceMap: false,
      },
    });

    // Email Handler Lambda
    const emailHandler = new nodejs.NodejsFunction(this, 'EmailHandler', {
      functionName: 'speech-to-email-email-handler',
      runtime: lambda.Runtime.NODEJS_18_X,
      entry: 'lambda/email-handler/index.ts',
      handler: 'handler',
      role: emailHandlerRole,
      timeout: cdk.Duration.seconds(30),
      retryAttempts: 2,
      deadLetterQueue: deadLetterQueue,
      environment: {
        DYNAMODB_TABLE_NAME: speechProcessingTable.tableName,
        AUDIO_BUCKET_NAME: audioStorageBucket.bucketName,
        RECIPIENT_EMAIL: 'lockhead+hcvflmail@lockhead.info,Marc.schaeffauer@gmx.de,michaellennert@icloud.com',
        SENDER_EMAIL: 'lockhead+noreply@lockhead.info', // This needs to be verified in SES
      },
      bundling: {
        externalModules: ['aws-sdk'],
        minify: true,
        sourceMap: false,
      },
    });

    // Grant permissions to Article Enhancement Handler
    speechProcessingTable.grantReadWriteData(articleEnhancementHandler);
    articleEnhancementHandlerRole.addToPolicy(new iam.PolicyStatement({
      effect: iam.Effect.ALLOW,
      actions: [
        'bedrock:InvokeModel',
        'bedrock:InvokeModelWithResponseStream',
      ],
      resources: [
        `arn:aws:bedrock:${this.region}::foundation-model/*`,
      ],
    }));

    // Grant permissions to Email Handler
    speechProcessingTable.grantReadWriteData(emailHandler);
    audioStorageBucket.grantRead(emailHandler);
    emailHandlerRole.addToPolicy(new iam.PolicyStatement({
      effect: iam.Effect.ALLOW,
      actions: ['ses:SendEmail', 'ses:SendRawEmail'],
      resources: ['*'],
    }));

    // Transcription Handler Lambda
    const transcriptionHandler = new nodejs.NodejsFunction(this, 'TranscriptionHandler', {
      functionName: 'speech-to-email-transcription-handler',
      runtime: lambda.Runtime.NODEJS_18_X,
      entry: 'lambda/transcription-handler/index.ts',
      handler: 'handler',
      role: transcriptionHandlerRole,
      timeout: cdk.Duration.seconds(60),
      retryAttempts: 2,
      deadLetterQueue: deadLetterQueue,
      environment: {
        DYNAMODB_TABLE_NAME: speechProcessingTable.tableName,
        AUDIO_BUCKET_NAME: audioStorageBucket.bucketName,
        ARTICLE_ENHANCEMENT_HANDLER_FUNCTION_NAME: articleEnhancementHandler.functionName,
      },
      bundling: {
        externalModules: ['aws-sdk'],
        minify: true,
        sourceMap: false,
      },
    });

    // Grant permissions to Transcription Handler
    speechProcessingTable.grantReadWriteData(transcriptionHandler);
    audioStorageBucket.grantRead(transcriptionHandler);
    transcriptionHandlerRole.addToPolicy(new iam.PolicyStatement({
      effect: iam.Effect.ALLOW,
      actions: [
        'transcribe:StartTranscriptionJob',
        'transcribe:GetTranscriptionJob',
        'transcribe:ListTranscriptionJobs',
      ],
      resources: ['*'],
    }));

    // Grant Lambda permissions to invoke other handlers
    articleEnhancementHandler.grantInvoke(transcriptionHandler);
    emailHandler.grantInvoke(articleEnhancementHandler);

    // Update article enhancement handler environment with email handler function name
    articleEnhancementHandler.addEnvironment('EMAIL_HANDLER_FUNCTION_NAME', emailHandler.functionName);

    // Presigned URL Handler Lambda
    const presignedUrlHandler = new nodejs.NodejsFunction(this, 'PresignedUrlHandler', {
      functionName: 'speech-to-email-presigned-url-handler',
      runtime: lambda.Runtime.NODEJS_18_X,
      entry: 'lambda/presigned-url-handler/index.ts',
      handler: 'handler',
      role: presignedUrlHandlerRole,
      timeout: cdk.Duration.seconds(30),
      environment: {
        AUDIO_BUCKET_NAME: audioStorageBucket.bucketName,
      },
      bundling: {
        externalModules: ['aws-sdk'],
        minify: true,
        sourceMap: false,
      },
    });

    // Grant permissions to Presigned URL Handler
    audioStorageBucket.grantPut(presignedUrlHandler);

    // WAF configuration temporarily removed to avoid deployment issues
    // TODO: Add WAF protection after initial deployment

    // API Gateway for presigned URL generation
    const api = new apigateway.RestApi(this, 'SpeechToEmailApi', {
      restApiName: 'Speech to Email API',
      description: 'API for Speech to Email application',
      defaultCorsPreflightOptions: {
        allowOrigins: apigateway.Cors.ALL_ORIGINS,
        allowMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
        allowHeaders: [
          'Content-Type',
          'X-Amz-Date',
          'Authorization',
          'X-Api-Key',
          'X-Amz-Security-Token',
          'X-Amz-User-Agent'
        ],
        allowCredentials: false,
      },
      deployOptions: {
        stageName: 'prod',
        loggingLevel: apigateway.MethodLoggingLevel.INFO,
        dataTraceEnabled: true,
        metricsEnabled: true,
      },
    });

    // WAF association temporarily removed to avoid deployment issues

    // Status Handler Lambda
    const statusHandler = new nodejs.NodejsFunction(this, 'StatusHandler', {
      functionName: 'speech-to-email-status-handler',
      runtime: lambda.Runtime.NODEJS_18_X,
      entry: 'lambda/status-handler/index.ts',
      handler: 'handler',
      role: statusHandlerRole,
      timeout: cdk.Duration.seconds(30),
      environment: {
        DYNAMODB_TABLE_NAME: speechProcessingTable.tableName,
      },
      bundling: {
        externalModules: ['aws-sdk'],
        minify: true,
        sourceMap: false,
      },
    });

    // Grant permissions to Status Handler
    speechProcessingTable.grantReadData(statusHandler);

    // API Gateway integration for presigned URL
    const presignedUrlIntegration = new apigateway.LambdaIntegration(presignedUrlHandler);
    const presignedUrlResource = api.root.addResource('presigned-url');
    presignedUrlResource.addMethod('POST', presignedUrlIntegration);

    // API Gateway integration for status checking
    const statusIntegration = new apigateway.LambdaIntegration(statusHandler);
    const statusResource = api.root.addResource('status');
    const statusRecordResource = statusResource.addResource('{recordId}');
    statusRecordResource.addMethod('GET', statusIntegration);

    // CloudFront distribution for Flutter web app (without API Gateway integration to avoid circular dependency)
    const distribution = new cloudfront.Distribution(this, 'WebDistribution', {
      defaultBehavior: {
        origin: new origins.S3StaticWebsiteOrigin(webHostingBucket),
        viewerProtocolPolicy: cloudfront.ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
        allowedMethods: cloudfront.AllowedMethods.ALLOW_GET_HEAD,
        cachedMethods: cloudfront.CachedMethods.CACHE_GET_HEAD,
        compress: true,
        cachePolicy: cloudfront.CachePolicy.CACHING_OPTIMIZED,
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
      new s3n.LambdaDestination(uploadHandler),
      { prefix: 'audio-files/' } // Only trigger for files in the audio-files prefix
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

    // Note: Lambda functions automatically create their own CloudWatch log groups
    // Explicit log group creation removed to avoid circular dependencies

    // SES configuration temporarily simplified to avoid deployment issues
    // TODO: Add SES configuration set and event destinations after initial deployment

    // SNS topic for SES bounce and complaint notifications
    const sesNotificationTopic = new sns.Topic(this, 'SESNotificationTopic', {
      topicName: 'speech-to-email-ses-notifications',
      displayName: 'SES Bounce and Complaint Notifications',
    });

    // Lambda function to handle SES notifications
    const sesNotificationHandler = new nodejs.NodejsFunction(this, 'SESNotificationHandler', {
      functionName: 'speech-to-email-ses-notification-handler',
      runtime: lambda.Runtime.NODEJS_18_X,
      entry: 'lambda/ses-notification-handler/index.ts',
      handler: 'handler',
      role: sesNotificationHandlerRole,
      timeout: cdk.Duration.seconds(30),
      environment: {
        DYNAMODB_TABLE_NAME: speechProcessingTable.tableName,
      },
      bundling: {
        externalModules: ['aws-sdk'],
        minify: true,
        sourceMap: false,
      },
    });

    // Grant permissions to SES Notification Handler
    speechProcessingTable.grantReadWriteData(sesNotificationHandler);

    // Subscribe Lambda to SNS topic
    sesNotificationTopic.addSubscription(
      new subscriptions.LambdaSubscription(sesNotificationHandler)
    );

    // SES Configuration Set for email tracking
    const sesConfigurationSet = new ses.CfnConfigurationSet(this, 'SESConfigurationSet', {
      name: 'speech-to-email-config-set',
    });

    // SES Event Destination for bounce and complaint tracking
    const sesEventDestination = new ses.CfnConfigurationSetEventDestination(this, 'SESEventDestination', {
      configurationSetName: sesConfigurationSet.name!,
      eventDestination: {
        name: 'sns-event-destination',
        enabled: true,
        matchingEventTypes: ['bounce', 'complaint', 'reject'],
        snsDestination: {
          topicArn: sesNotificationTopic.topicArn,
        },
      },
    });

    // Ensure proper dependency order
    sesEventDestination.addDependency(sesConfigurationSet);

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

    new cdk.CfnOutput(this, 'ArticleEnhancementHandlerArn', {
      value: articleEnhancementHandler.functionArn,
      description: 'ARN of the Article Enhancement Handler Lambda function',
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
      description: 'Direct URL of the API Gateway (use this for API calls)',
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
      description: 'Website URL (Flutter app served via CloudFront)',
    });

    // Note: API calls should be made directly to the API Gateway URL, not through CloudFront
    // This avoids circular dependency issues between CloudFront and API Gateway

    new cdk.CfnOutput(this, 'SESNotificationTopicArn', {
      value: sesNotificationTopic.topicArn,
      description: 'SNS Topic ARN for SES notifications',
    });

    new cdk.CfnOutput(this, 'StatusHandlerArn', {
      value: statusHandler.functionArn,
      description: 'ARN of the Status Handler Lambda function',
    });

    // CloudWatch Alarms temporarily removed to avoid circular dependencies
    // TODO: Add monitoring in a separate stack or after initial deployment

    // DLQ alarm
    new cloudwatch.Alarm(this, 'DeadLetterQueueAlarm', {
      alarmName: 'speech-to-email-dlq-messages',
      metric: deadLetterQueue.metricApproximateNumberOfMessagesVisible({
        period: cdk.Duration.minutes(5),
      }),
      threshold: 1,
      evaluationPeriods: 1,
      treatMissingData: cloudwatch.TreatMissingData.NOT_BREACHING,
    });

    new cdk.CfnOutput(this, 'DeadLetterQueueUrl', {
      value: deadLetterQueue.queueUrl,
      description: 'URL of the Dead Letter Queue',
    });

    // CloudWatch Dashboard and monitoring widgets temporarily removed to avoid circular dependencies
    // TODO: Add monitoring in a separate stack or after initial deployment

    // DynamoDB metrics widget - temporarily disabled due to CDK deprecation warnings
    // const dynamoMetricsWidget = new cloudwatch.GraphWidget({
    //   title: 'DynamoDB Metrics',
    //   left: [
    //     new cloudwatch.Metric({
    //       namespace: 'AWS/DynamoDB',
    //       metricName: 'ConsumedReadCapacityUnits',
    //       dimensionsMap: {
    //         TableName: 'SpeechProcessingRecords',
    //       },
    //       label: 'Read Capacity',
    //     }),
    //     new cloudwatch.Metric({
    //       namespace: 'AWS/DynamoDB',
    //       metricName: 'ConsumedWriteCapacityUnits',
    //       dimensionsMap: {
    //         TableName: 'SpeechProcessingRecords',
    //       },
    //       label: 'Write Capacity',
    //     }),
    //   ],
    //   right: [
    //     new cloudwatch.Metric({
    //       namespace: 'AWS/DynamoDB',
    //       metricName: 'UserErrors',
    //       dimensionsMap: {
    //         TableName: 'SpeechProcessingRecords',
    //       },
    //       label: 'User Errors',
    //     }),
    //     new cloudwatch.Metric({
    //       namespace: 'AWS/DynamoDB',
    //       metricName: 'ThrottledRequests',
    //       dimensionsMap: {
    //         TableName: 'SpeechProcessingRecords',
    //       },
    //       label: 'Throttled Requests',
    //     }),
    //   ],
    // });

    // S3 and business metrics widgets temporarily removed to avoid circular dependencies

    // Dashboard widgets temporarily removed to avoid circular dependencies

    // Custom log groups and monitoring components temporarily removed to avoid circular dependencies
    // TODO: Add monitoring in a separate stack or after initial deployment

    // High-priority alarms temporarily removed to avoid circular dependencies
    // TODO: Add monitoring in a separate stack or after initial deployment

    // Dashboard and alert topic outputs temporarily removed

    new cdk.CfnOutput(this, 'EncryptionKeyId', {
      value: encryptionKey.keyId,
      description: 'KMS Key ID for encryption',
    });
  }
}