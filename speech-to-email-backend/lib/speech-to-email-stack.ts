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
import * as sns from 'aws-cdk-lib/aws-sns';
import * as subscriptions from 'aws-cdk-lib/aws-sns-subscriptions';
import * as sqs from 'aws-cdk-lib/aws-sqs';
import * as cloudwatch from 'aws-cdk-lib/aws-cloudwatch';
import * as cloudwatchActions from 'aws-cdk-lib/aws-cloudwatch-actions';
import * as waf from 'aws-cdk-lib/aws-wafv2';
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
        SQSPolicy: new iam.PolicyDocument({
          statements: [
            new iam.PolicyStatement({
              effect: iam.Effect.ALLOW,
              actions: ['sqs:SendMessage'],
              resources: [deadLetterQueue.queueArn],
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
      retryAttempts: 2,
      deadLetterQueue: deadLetterQueue,
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
      retryAttempts: 2,
      deadLetterQueue: deadLetterQueue,
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
      retryAttempts: 2,
      deadLetterQueue: deadLetterQueue,
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

    // WAF Web ACL for API Gateway protection
    const webAcl = new waf.CfnWebACL(this, 'ApiGatewayWebACL', {
      scope: 'REGIONAL',
      defaultAction: { allow: {} },
      rules: [
        {
          name: 'RateLimitRule',
          priority: 1,
          statement: {
            rateBasedStatement: {
              limit: 1000, // 1000 requests per 5 minutes
              aggregateKeyType: 'IP',
            },
          },
          action: { block: {} },
          visibilityConfig: {
            sampledRequestsEnabled: true,
            cloudWatchMetricsEnabled: true,
            metricName: 'RateLimitRule',
          },
        },
        {
          name: 'AWSManagedRulesCommonRuleSet',
          priority: 2,
          overrideAction: { none: {} },
          statement: {
            managedRuleGroupStatement: {
              vendorName: 'AWS',
              name: 'AWSManagedRulesCommonRuleSet',
            },
          },
          visibilityConfig: {
            sampledRequestsEnabled: true,
            cloudWatchMetricsEnabled: true,
            metricName: 'CommonRuleSetMetric',
          },
        },
        {
          name: 'AWSManagedRulesKnownBadInputsRuleSet',
          priority: 3,
          overrideAction: { none: {} },
          statement: {
            managedRuleGroupStatement: {
              vendorName: 'AWS',
              name: 'AWSManagedRulesKnownBadInputsRuleSet',
            },
          },
          visibilityConfig: {
            sampledRequestsEnabled: true,
            cloudWatchMetricsEnabled: true,
            metricName: 'KnownBadInputsRuleSetMetric',
          },
        },
      ],
      visibilityConfig: {
        sampledRequestsEnabled: true,
        cloudWatchMetricsEnabled: true,
        metricName: 'SpeechToEmailWebACL',
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
      deployOptions: {
        stageName: 'prod',
        loggingLevel: apigateway.MethodLoggingLevel.INFO,
        dataTraceEnabled: true,
        metricsEnabled: true,
      },
    });

    // Associate WAF with API Gateway
    new waf.CfnWebACLAssociation(this, 'ApiGatewayWebACLAssociation', {
      resourceArn: `arn:aws:apigateway:${this.region}::/restapis/${api.restApiId}/stages/prod`,
      webAclArn: webAcl.attrArn,
    });

    // Status Handler Lambda
    const statusHandler = new lambda.Function(this, 'StatusHandler', {
      functionName: 'speech-to-email-status-handler',
      runtime: lambda.Runtime.NODEJS_18_X,
      handler: 'index.handler',
      code: lambda.Code.fromAsset('lambda/status-handler'),
      role: lambdaExecutionRole,
      timeout: cdk.Duration.seconds(30),
      environment: {
        DYNAMODB_TABLE_NAME: speechProcessingTable.tableName,
      },
    });

    // API Gateway integration for presigned URL
    const presignedUrlIntegration = new apigateway.LambdaIntegration(presignedUrlHandler);
    const presignedUrlResource = api.root.addResource('presigned-url');
    presignedUrlResource.addMethod('POST', presignedUrlIntegration);

    // API Gateway integration for status checking
    const statusIntegration = new apigateway.LambdaIntegration(statusHandler);
    const statusResource = api.root.addResource('status');
    const statusRecordResource = statusResource.addResource('{recordId}');
    statusRecordResource.addMethod('GET', statusIntegration);

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

    // SES configuration
    const configurationSet = new ses.CfnConfigurationSet(this, 'SESConfigurationSet', {
      name: 'speech-to-email-config-set',
    });

    // SES Configuration Set Event Destination for bounce/complaint handling
    new ses.CfnConfigurationSetEventDestination(this, 'SESEventDestination', {
      configurationSetName: configurationSet.name!,
      eventDestination: {
        name: 'cloudwatch-event-destination',
        enabled: true,
        matchingEventTypes: ['bounce', 'complaint', 'reject'],
        cloudWatchDestination: {
          dimensionConfigurations: [
            {
              dimensionName: 'MessageTag',
              dimensionValueSource: 'messageTag',
              defaultDimensionValue: 'speech-to-email',
            },
          ],
        },
      },
    });

    // Create CloudWatch log group for SES events
    new logs.LogGroup(this, 'SESLogGroup', {
      logGroupName: '/aws/ses/speech-to-email',
      retention: logs.RetentionDays.ONE_MONTH,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
    });

    // SNS topic for SES bounce and complaint notifications
    const sesNotificationTopic = new sns.Topic(this, 'SESNotificationTopic', {
      topicName: 'speech-to-email-ses-notifications',
      displayName: 'SES Bounce and Complaint Notifications',
    });

    // Lambda function to handle SES notifications
    const sesNotificationHandler = new lambda.Function(this, 'SESNotificationHandler', {
      functionName: 'speech-to-email-ses-notification-handler',
      runtime: lambda.Runtime.NODEJS_18_X,
      handler: 'index.handler',
      code: lambda.Code.fromAsset('lambda/ses-notification-handler'),
      role: lambdaExecutionRole,
      timeout: cdk.Duration.seconds(30),
      environment: {
        DYNAMODB_TABLE_NAME: speechProcessingTable.tableName,
      },
    });

    // Subscribe Lambda to SNS topic
    sesNotificationTopic.addSubscription(
      new subscriptions.LambdaSubscription(sesNotificationHandler)
    );

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

    new cdk.CfnOutput(this, 'SESNotificationTopicArn', {
      value: sesNotificationTopic.topicArn,
      description: 'SNS Topic ARN for SES notifications',
    });

    new cdk.CfnOutput(this, 'StatusHandlerArn', {
      value: statusHandler.functionArn,
      description: 'ARN of the Status Handler Lambda function',
    });

    // CloudWatch Alarms for monitoring
    const functions = [uploadHandler, transcriptionHandler, emailHandler, statusHandler];
    
    functions.forEach((func, index) => {
      // Error rate alarm
      new cloudwatch.Alarm(this, `${func.functionName}ErrorAlarm`, {
        alarmName: `${func.functionName}-error-rate`,
        metric: func.metricErrors({
          period: cdk.Duration.minutes(5),
        }),
        threshold: 5,
        evaluationPeriods: 2,
        treatMissingData: cloudwatch.TreatMissingData.NOT_BREACHING,
      });

      // Duration alarm
      new cloudwatch.Alarm(this, `${func.functionName}DurationAlarm`, {
        alarmName: `${func.functionName}-duration`,
        metric: func.metricDuration({
          period: cdk.Duration.minutes(5),
        }),
        threshold: func.timeout?.toMilliseconds() || 30000 * 0.8, // 80% of timeout
        evaluationPeriods: 3,
        treatMissingData: cloudwatch.TreatMissingData.NOT_BREACHING,
      });

      // Throttle alarm
      new cloudwatch.Alarm(this, `${func.functionName}ThrottleAlarm`, {
        alarmName: `${func.functionName}-throttles`,
        metric: func.metricThrottles({
          period: cdk.Duration.minutes(5),
        }),
        threshold: 1,
        evaluationPeriods: 1,
        treatMissingData: cloudwatch.TreatMissingData.NOT_BREACHING,
      });
    });

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

    // CloudWatch Dashboard
    const dashboard = new cloudwatch.Dashboard(this, 'SpeechToEmailDashboard', {
      dashboardName: 'SpeechToEmailMonitoring',
    });

    // Lambda metrics widgets
    const lambdaMetricsWidget = new cloudwatch.GraphWidget({
      title: 'Lambda Function Metrics',
      left: [
        uploadHandler.metricInvocations({ label: 'Upload Handler Invocations' }),
        transcriptionHandler.metricInvocations({ label: 'Transcription Handler Invocations' }),
        emailHandler.metricInvocations({ label: 'Email Handler Invocations' }),
        statusHandler.metricInvocations({ label: 'Status Handler Invocations' }),
      ],
      right: [
        uploadHandler.metricErrors({ label: 'Upload Handler Errors' }),
        transcriptionHandler.metricErrors({ label: 'Transcription Handler Errors' }),
        emailHandler.metricErrors({ label: 'Email Handler Errors' }),
        statusHandler.metricErrors({ label: 'Status Handler Errors' }),
      ],
    });

    // Lambda duration widget
    const lambdaDurationWidget = new cloudwatch.GraphWidget({
      title: 'Lambda Function Duration',
      left: [
        uploadHandler.metricDuration({ label: 'Upload Handler Duration' }),
        transcriptionHandler.metricDuration({ label: 'Transcription Handler Duration' }),
        emailHandler.metricDuration({ label: 'Email Handler Duration' }),
        statusHandler.metricDuration({ label: 'Status Handler Duration' }),
      ],
    });

    // API Gateway metrics widget
    const apiMetricsWidget = new cloudwatch.GraphWidget({
      title: 'API Gateway Metrics',
      left: [
        api.metricCount({ label: 'API Requests' }),
        new cloudwatch.Metric({
          namespace: 'AWS/ApiGateway',
          metricName: '4XXError',
          dimensionsMap: { ApiName: api.restApiName },
          label: '4XX Errors',
        }),
        new cloudwatch.Metric({
          namespace: 'AWS/ApiGateway',
          metricName: '5XXError',
          dimensionsMap: { ApiName: api.restApiName },
          label: '5XX Errors',
        }),
      ],
      right: [
        api.metricLatency({ label: 'API Latency' }),
      ],
    });

    // DynamoDB metrics widget
    const dynamoMetricsWidget = new cloudwatch.GraphWidget({
      title: 'DynamoDB Metrics',
      left: [
        speechProcessingTable.metricConsumedReadCapacityUnits({ label: 'Read Capacity' }),
        speechProcessingTable.metricConsumedWriteCapacityUnits({ label: 'Write Capacity' }),
      ],
      right: [
        speechProcessingTable.metricUserErrors({ label: 'User Errors' }),
        speechProcessingTable.metricSystemErrors({ label: 'System Errors' }),
      ],
    });

    // S3 metrics widget
    const s3MetricsWidget = new cloudwatch.GraphWidget({
      title: 'S3 Storage Metrics',
      left: [
        new cloudwatch.Metric({
          namespace: 'AWS/S3',
          metricName: 'BucketSizeBytes',
          dimensionsMap: { 
            BucketName: audioStorageBucket.bucketName,
            StorageType: 'StandardStorage' 
          },
          label: 'Audio Bucket Size',
        }),
        new cloudwatch.Metric({
          namespace: 'AWS/S3',
          metricName: 'NumberOfObjects',
          dimensionsMap: { 
            BucketName: audioStorageBucket.bucketName,
            StorageType: 'AllStorageTypes' 
          },
          label: 'Audio Objects Count',
        }),
      ],
    });

    // Custom business metrics
    const businessMetricsWidget = new cloudwatch.GraphWidget({
      title: 'Business Metrics',
      left: [
        new cloudwatch.Metric({
          namespace: 'SpeechToEmail',
          metricName: 'RecordingsProcessed',
          label: 'Recordings Processed',
        }),
        new cloudwatch.Metric({
          namespace: 'SpeechToEmail',
          metricName: 'EmailsSent',
          label: 'Emails Sent',
        }),
      ],
      right: [
        new cloudwatch.Metric({
          namespace: 'SpeechToEmail',
          metricName: 'ProcessingFailures',
          label: 'Processing Failures',
        }),
      ],
    });

    // Add widgets to dashboard
    dashboard.addWidgets(
      lambdaMetricsWidget,
      lambdaDurationWidget,
      apiMetricsWidget,
      dynamoMetricsWidget,
      s3MetricsWidget,
      businessMetricsWidget
    );

    // Custom log groups for structured logging
    const applicationLogGroup = new logs.LogGroup(this, 'ApplicationLogGroup', {
      logGroupName: '/aws/speech-to-email/application',
      retention: logs.RetentionDays.ONE_MONTH,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
    });

    const securityLogGroup = new logs.LogGroup(this, 'SecurityLogGroup', {
      logGroupName: '/aws/speech-to-email/security',
      retention: logs.RetentionDays.THREE_MONTHS,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
    });

    // CloudWatch Insights queries
    const insightsQueries = [
      {
        queryName: 'ErrorAnalysis',
        logGroup: applicationLogGroup.logGroupName,
        queryString: `
          fields @timestamp, @message, @requestId
          | filter @message like /ERROR/
          | stats count() by bin(5m)
          | sort @timestamp desc
        `,
      },
      {
        queryName: 'PerformanceAnalysis',
        logGroup: applicationLogGroup.logGroupName,
        queryString: `
          fields @timestamp, @duration, @requestId
          | filter @type = "REPORT"
          | stats avg(@duration), max(@duration), min(@duration) by bin(5m)
          | sort @timestamp desc
        `,
      },
      {
        queryName: 'SecurityEvents',
        logGroup: securityLogGroup.logGroupName,
        queryString: `
          fields @timestamp, @message, sourceIP, userAgent
          | filter @message like /SECURITY/
          | stats count() by sourceIP
          | sort count desc
        `,
      },
    ];

    // SNS topic for alerts
    const alertTopic = new sns.Topic(this, 'AlertTopic', {
      topicName: 'speech-to-email-alerts',
      displayName: 'Speech to Email Alerts',
    });

    // High-priority alarms
    const criticalAlarms = [
      new cloudwatch.Alarm(this, 'HighErrorRateAlarm', {
        alarmName: 'SpeechToEmail-HighErrorRate',
        metric: new cloudwatch.MathExpression({
          expression: '(errors / invocations) * 100',
          usingMetrics: {
            errors: uploadHandler.metricErrors().with({
              statistic: 'Sum',
              period: cdk.Duration.minutes(5),
            }),
            invocations: uploadHandler.metricInvocations().with({
              statistic: 'Sum',
              period: cdk.Duration.minutes(5),
            }),
          },
        }),
        threshold: 5, // 5% error rate
        evaluationPeriods: 2,
        treatMissingData: cloudwatch.TreatMissingData.NOT_BREACHING,
      }),
      
      new cloudwatch.Alarm(this, 'DLQMessagesAlarm', {
        alarmName: 'SpeechToEmail-DLQMessages',
        metric: deadLetterQueue.metricApproximateNumberOfMessagesVisible(),
        threshold: 1,
        evaluationPeriods: 1,
        treatMissingData: cloudwatch.TreatMissingData.NOT_BREACHING,
      }),

      new cloudwatch.Alarm(this, 'APIGateway5XXAlarm', {
        alarmName: 'SpeechToEmail-API5XXErrors',
        metric: new cloudwatch.Metric({
          namespace: 'AWS/ApiGateway',
          metricName: '5XXError',
          dimensionsMap: { ApiName: api.restApiName },
          period: cdk.Duration.minutes(5),
        }),
        threshold: 10,
        evaluationPeriods: 2,
        treatMissingData: cloudwatch.TreatMissingData.NOT_BREACHING,
      }),
    ];

    // Add alarms to SNS topic
    criticalAlarms.forEach(alarm => {
      alarm.addAlarmAction(new cloudwatchActions.SnsAction(alertTopic));
    });

    new cdk.CfnOutput(this, 'DashboardUrl', {
      value: `https://${this.region}.console.aws.amazon.com/cloudwatch/home?region=${this.region}#dashboards:name=${dashboard.dashboardName}`,
      description: 'CloudWatch Dashboard URL',
    });

    new cdk.CfnOutput(this, 'AlertTopicArn', {
      value: alertTopic.topicArn,
      description: 'SNS Topic ARN for alerts',
    });

    new cdk.CfnOutput(this, 'EncryptionKeyId', {
      value: encryptionKey.keyId,
      description: 'KMS Key ID for encryption',
    });
  }
}