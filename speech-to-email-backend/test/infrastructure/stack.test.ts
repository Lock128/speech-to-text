import * as cdk from 'aws-cdk-lib';
import { Template } from 'aws-cdk-lib/assertions';
import { SpeechToEmailStack } from '../../lib/speech-to-email-stack';

describe('SpeechToEmailStack', () => {
  let app: cdk.App;
  let stack: SpeechToEmailStack;
  let template: Template;

  beforeEach(() => {
    app = new cdk.App();
    stack = new SpeechToEmailStack(app, 'TestStack');
    template = Template.fromStack(stack);
  });

  describe('S3 Resources', () => {
    it('should create audio storage bucket with encryption', () => {
      template.hasResourceProperties('AWS::S3::Bucket', {
        BucketEncryption: {
          ServerSideEncryptionConfiguration: [
            {
              ServerSideEncryptionByDefault: {
                SSEAlgorithm: 'aws:kms',
              },
            },
          ],
        },
        PublicAccessBlockConfiguration: {
          BlockPublicAcls: true,
          BlockPublicPolicy: true,
          IgnorePublicAcls: true,
          RestrictPublicBuckets: true,
        },
      });
    });

    it('should create web hosting bucket', () => {
      template.hasResourceProperties('AWS::S3::Bucket', {
        WebsiteConfiguration: {
          IndexDocument: 'index.html',
          ErrorDocument: 'index.html',
        },
      });
    });

    it('should have lifecycle policies for audio bucket', () => {
      template.hasResourceProperties('AWS::S3::Bucket', {
        LifecycleConfiguration: {
          Rules: [
            {
              ExpirationInDays: 7,
              Id: 'DeleteAudioFilesAfter7Days',
              Status: 'Enabled',
            },
          ],
        },
      });
    });
  });

  describe('DynamoDB Resources', () => {
    it('should create speech processing table', () => {
      template.hasResourceProperties('AWS::DynamoDB::Table', {
        TableName: 'SpeechProcessingRecords',
        BillingMode: 'PAY_PER_REQUEST',
        AttributeDefinitions: [
          { AttributeName: 'PK', AttributeType: 'S' },
          { AttributeName: 'SK', AttributeType: 'S' },
          { AttributeName: 'status', AttributeType: 'S' },
          { AttributeName: 'createdAt', AttributeType: 'S' },
        ],
        KeySchema: [
          { AttributeName: 'PK', KeyType: 'HASH' },
          { AttributeName: 'SK', KeyType: 'RANGE' },
        ],
      });
    });

    it('should have GSI for status queries', () => {
      template.hasResourceProperties('AWS::DynamoDB::Table', {
        GlobalSecondaryIndexes: [
          {
            IndexName: 'StatusIndex',
            KeySchema: [
              { AttributeName: 'status', KeyType: 'HASH' },
              { AttributeName: 'createdAt', KeyType: 'RANGE' },
            ],
          },
        ],
      });
    });
  });

  describe('Lambda Functions', () => {
    it('should create all required Lambda functions', () => {
      const functionNames = [
        'speech-to-email-upload-handler',
        'speech-to-email-transcription-handler',
        'speech-to-email-email-handler',
        'speech-to-email-status-handler',
        'speech-to-email-presigned-url-handler',
      ];

      functionNames.forEach(functionName => {
        template.hasResourceProperties('AWS::Lambda::Function', {
          FunctionName: functionName,
          Runtime: 'nodejs18.x',
        });
      });
    });

    it('should configure dead letter queues for Lambda functions', () => {
      template.hasResourceProperties('AWS::Lambda::Function', {
        DeadLetterConfig: {
          TargetArn: {
            'Fn::GetAtt': [
              expect.stringMatching(/DeadLetterQueue/),
              'Arn',
            ],
          },
        },
      });
    });

    it('should set appropriate timeouts', () => {
      template.hasResourceProperties('AWS::Lambda::Function', {
        FunctionName: 'speech-to-email-transcription-handler',
        Timeout: 60,
      });
    });
  });

  describe('API Gateway', () => {
    it('should create REST API', () => {
      template.hasResourceProperties('AWS::ApiGateway::RestApi', {
        Name: 'Speech to Email API',
      });
    });

    it('should have CORS configuration', () => {
      template.hasResourceProperties('AWS::ApiGateway::Method', {
        HttpMethod: 'OPTIONS',
      });
    });

    it('should have proper integration with Lambda', () => {
      template.hasResourceProperties('AWS::ApiGateway::Method', {
        HttpMethod: 'POST',
        Integration: {
          Type: 'AWS_PROXY',
        },
      });
    });
  });

  describe('Security Configuration', () => {
    it('should create KMS key for encryption', () => {
      template.hasResourceProperties('AWS::KMS::Key', {
        Description: 'KMS key for Speech to Email application encryption',
        EnableKeyRotation: true,
      });
    });

    it('should create WAF Web ACL', () => {
      template.hasResourceProperties('AWS::WAFv2::WebACL', {
        Scope: 'REGIONAL',
        DefaultAction: { Allow: {} },
      });
    });

    it('should have rate limiting rules', () => {
      template.hasResourceProperties('AWS::WAFv2::WebACL', {
        Rules: expect.arrayContaining([
          expect.objectContaining({
            Name: 'RateLimitRule',
            Statement: {
              RateBasedStatement: {
                Limit: 1000,
                AggregateKeyType: 'IP',
              },
            },
          }),
        ]),
      });
    });
  });

  describe('Monitoring and Alerting', () => {
    it('should create CloudWatch alarms', () => {
      template.hasResourceProperties('AWS::CloudWatch::Alarm', {
        AlarmName: expect.stringMatching(/SpeechToEmail-/),
        ComparisonOperator: 'GreaterThanThreshold',
      });
    });

    it('should create SNS topic for alerts', () => {
      template.hasResourceProperties('AWS::SNS::Topic', {
        TopicName: 'speech-to-email-alerts',
      });
    });

    it('should create dead letter queue', () => {
      template.hasResourceProperties('AWS::SQS::Queue', {
        QueueName: 'speech-to-email-dlq',
        MessageRetentionPeriod: 1209600, // 14 days
      });
    });
  });

  describe('IAM Permissions', () => {
    it('should create Lambda execution role with proper permissions', () => {
      template.hasResourceProperties('AWS::IAM::Role', {
        AssumeRolePolicyDocument: {
          Statement: [
            {
              Action: 'sts:AssumeRole',
              Effect: 'Allow',
              Principal: {
                Service: 'lambda.amazonaws.com',
              },
            },
          ],
        },
      });
    });

    it('should have S3 permissions for Lambda', () => {
      template.hasResourceProperties('AWS::IAM::Policy', {
        PolicyDocument: {
          Statement: expect.arrayContaining([
            expect.objectContaining({
              Action: ['s3:DeleteObject', 's3:GetObject', 's3:PutObject'],
              Effect: 'Allow',
            }),
          ]),
        },
      });
    });

    it('should have DynamoDB permissions', () => {
      template.hasResourceProperties('AWS::IAM::Policy', {
        PolicyDocument: {
          Statement: expect.arrayContaining([
            expect.objectContaining({
              Action: expect.arrayContaining([
                'dynamodb:GetItem',
                'dynamodb:PutItem',
                'dynamodb:UpdateItem',
                'dynamodb:Query',
              ]),
              Effect: 'Allow',
            }),
          ]),
        },
      });
    });

    it('should have Transcribe permissions', () => {
      template.hasResourceProperties('AWS::IAM::Policy', {
        PolicyDocument: {
          Statement: expect.arrayContaining([
            expect.objectContaining({
              Action: expect.arrayContaining([
                'transcribe:StartTranscriptionJob',
                'transcribe:GetTranscriptionJob',
              ]),
              Effect: 'Allow',
            }),
          ]),
        },
      });
    });

    it('should have SES permissions', () => {
      template.hasResourceProperties('AWS::IAM::Policy', {
        PolicyDocument: {
          Statement: expect.arrayContaining([
            expect.objectContaining({
              Action: ['ses:SendEmail', 'ses:SendRawEmail'],
              Effect: 'Allow',
            }),
          ]),
        },
      });
    });
  });

  describe('CloudFront Distribution', () => {
    it('should create CloudFront distribution', () => {
      template.hasResourceProperties('AWS::CloudFront::Distribution', {
        DistributionConfig: {
          DefaultRootObject: 'index.html',
          Enabled: true,
        },
      });
    });

    it('should have proper error pages configuration', () => {
      template.hasResourceProperties('AWS::CloudFront::Distribution', {
        DistributionConfig: {
          CustomErrorResponses: expect.arrayContaining([
            expect.objectContaining({
              ErrorCode: 404,
              ResponseCode: 200,
              ResponsePagePath: '/index.html',
            }),
          ]),
        },
      });
    });
  });

  describe('Resource Tagging', () => {
    it('should have proper resource naming', () => {
      // Check that resources follow naming conventions
      const resources = template.toJSON().Resources;
      const resourceNames = Object.keys(resources);
      
      expect(resourceNames.some(name => name.includes('AudioStorageBucket'))).toBe(true);
      expect(resourceNames.some(name => name.includes('SpeechProcessingTable'))).toBe(true);
    });
  });

  describe('Outputs', () => {
    it('should export important resource identifiers', () => {
      const outputs = template.toJSON().Outputs;
      
      expect(outputs).toHaveProperty('AudioBucketName');
      expect(outputs).toHaveProperty('WebBucketName');
      expect(outputs).toHaveProperty('DynamoDBTableName');
      expect(outputs).toHaveProperty('ApiGatewayUrl');
      expect(outputs).toHaveProperty('CloudFrontDistributionId');
    });
  });
});