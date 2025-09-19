# Speech to Email - Deployment Guide

## Overview

This document provides comprehensive instructions for deploying the Speech to Email application to production environments.

## Prerequisites

### Required Tools
- AWS CLI v2.x configured with appropriate permissions
- Node.js 18.x or later
- Flutter SDK 3.16.0 or later
- Docker (for local testing)
- Git

### AWS Permissions Required
- IAM: Full access for role and policy management
- S3: Full access for bucket creation and management
- Lambda: Full access for function deployment
- API Gateway: Full access for API creation
- DynamoDB: Full access for table management
- CloudFront: Full access for distribution management
- CloudWatch: Full access for monitoring and logging
- SES: Full access for email configuration
- Transcribe: Full access for speech-to-text services
- WAF: Full access for web application firewall

## Environment Setup

### 1. Clone Repository
```bash
git clone <repository-url>
cd speech-to-email
```

### 2. Configure Environment Variables

Create environment-specific configuration files:

#### Development Environment
```bash
# .env.development
API_BASE_URL=https://dev-api.speech-to-email.com
AWS_REGION=us-east-1
STAGE=dev
LOG_LEVEL=DEBUG
```

#### Production Environment
```bash
# .env.production
API_BASE_URL=https://api.speech-to-email.com
AWS_REGION=us-east-1
STAGE=prod
LOG_LEVEL=WARN
```

### 3. GitHub Secrets Configuration

Configure the following secrets in your GitHub repository:

#### AWS Credentials
- `AWS_ACCESS_KEY_ID`: AWS access key for deployment
- `AWS_SECRET_ACCESS_KEY`: AWS secret key for deployment
- `AWS_REGION`: Target AWS region (e.g., us-east-1)

#### Flutter Deployment
- `S3_WEB_BUCKET_NAME`: S3 bucket name for web hosting
- `CLOUDFRONT_DISTRIBUTION_ID`: CloudFront distribution ID
- `CLOUDFRONT_DOMAIN_NAME`: CloudFront domain name

#### Firebase (for mobile app distribution)
- `FIREBASE_ANDROID_APP_ID`: Firebase Android app ID
- `FIREBASE_SERVICE_ACCOUNT`: Firebase service account JSON

#### API Configuration
- `API_BASE_URL`: Base URL for the API Gateway

## Backend Deployment

### 1. Install Dependencies
```bash
cd speech-to-email-backend
npm install
```

### 2. Build and Test
```bash
npm run build
npm test
```

### 3. CDK Bootstrap (First Time Only)
```bash
npx cdk bootstrap aws://ACCOUNT-NUMBER/REGION
```

### 4. Deploy Infrastructure
```bash
# Development
npx cdk deploy --context environment=dev

# Production
npx cdk deploy --context environment=prod --require-approval never
```

### 5. Verify Deployment
```bash
# Test API endpoints
curl -X POST https://your-api-gateway-url/presigned-url \
  -H "Content-Type: application/json" \
  -d '{"fileName":"test.mp3","fileSize":1024,"contentType":"audio/mpeg"}'
```

## Frontend Deployment

### 1. Install Dependencies
```bash
cd speech_to_email_app
flutter pub get
```

### 2. Build Applications

#### Web Build
```bash
flutter build web --release --dart-define=API_BASE_URL=https://your-api-url.com
```

#### Android Build
```bash
flutter build apk --release --dart-define=API_BASE_URL=https://your-api-url.com
```

#### iOS Build
```bash
flutter build ios --release --dart-define=API_BASE_URL=https://your-api-url.com
```

### 3. Deploy Web App
```bash
# Upload to S3
aws s3 sync build/web s3://your-web-bucket-name --delete

# Invalidate CloudFront cache
aws cloudfront create-invalidation --distribution-id YOUR-DISTRIBUTION-ID --paths "/*"
```

## SES Configuration

### 1. Verify Email Addresses
```bash
# Verify sender email
aws ses verify-email-identity --email-address noreply@yourdomain.com

# Verify recipient email (for sandbox mode)
aws ses verify-email-identity --email-address johannes.koch@gmail.com
```

### 2. Request Production Access
If using SES in production, request to move out of sandbox mode through the AWS Console.

### 3. Configure Domain Authentication (Recommended)
Set up DKIM and SPF records for your domain to improve email deliverability.

## Post-Deployment Configuration

### 1. CloudWatch Alarms
Verify that all CloudWatch alarms are properly configured and notifications are working:

```bash
aws cloudwatch describe-alarms --alarm-names "SpeechToEmail-HighErrorRate" "SpeechToEmail-DLQMessages"
```

### 2. WAF Rules
Verify WAF rules are active and protecting your API:

```bash
aws wafv2 get-web-acl --scope REGIONAL --id YOUR-WEB-ACL-ID
```

### 3. Performance Testing
Run load tests to ensure the system can handle expected traffic:

```bash
# Example using Apache Bench
ab -n 100 -c 10 https://your-api-url.com/presigned-url
```

## Monitoring and Maintenance

### 1. CloudWatch Dashboard
Access the monitoring dashboard at:
```
https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=SpeechToEmailMonitoring
```

### 2. Log Analysis
Use CloudWatch Insights to analyze logs:

```sql
fields @timestamp, @message, @requestId
| filter @message like /ERROR/
| stats count() by bin(5m)
| sort @timestamp desc
```

### 3. Cost Monitoring
Set up AWS Cost Budgets to monitor spending:

```bash
aws budgets create-budget --account-id YOUR-ACCOUNT-ID --budget file://budget.json
```

## Troubleshooting

### Common Issues

#### 1. Lambda Function Timeouts
- Check CloudWatch logs for the specific function
- Increase timeout if necessary
- Optimize code for better performance

#### 2. S3 Upload Failures
- Verify CORS configuration
- Check IAM permissions
- Validate presigned URL generation

#### 3. Transcription Failures
- Verify audio file format compatibility
- Check Transcribe service limits
- Review IAM permissions for Transcribe

#### 4. Email Delivery Issues
- Check SES sending statistics
- Verify email addresses are verified
- Review bounce and complaint rates

### Debug Commands

```bash
# Check Lambda function logs
aws logs describe-log-groups --log-group-name-prefix "/aws/lambda/speech-to-email"

# Check API Gateway logs
aws logs describe-log-groups --log-group-name-prefix "API-Gateway-Execution-Logs"

# Check DynamoDB metrics
aws cloudwatch get-metric-statistics --namespace AWS/DynamoDB --metric-name ConsumedReadCapacityUnits

# Check S3 bucket policy
aws s3api get-bucket-policy --bucket your-audio-bucket-name
```

## Security Checklist

- [ ] All S3 buckets have public access blocked
- [ ] IAM roles follow least-privilege principle
- [ ] API Gateway has rate limiting enabled
- [ ] WAF rules are active and configured
- [ ] All data is encrypted at rest and in transit
- [ ] CloudTrail logging is enabled
- [ ] Security groups are properly configured
- [ ] SSL/TLS certificates are valid and up-to-date

## Performance Optimization

### 1. Lambda Optimization
- Use appropriate memory allocation
- Implement connection pooling
- Enable X-Ray tracing for performance insights

### 2. API Gateway Optimization
- Enable caching where appropriate
- Configure proper throttling limits
- Use CloudFront for global distribution

### 3. S3 Optimization
- Enable Transfer Acceleration
- Use appropriate storage classes
- Implement lifecycle policies

## Backup and Disaster Recovery

### 1. DynamoDB Backups
- Point-in-time recovery is enabled
- Regular backups are automated
- Cross-region replication (if required)

### 2. S3 Versioning
- Versioning is enabled on critical buckets
- Cross-region replication for disaster recovery

### 3. Infrastructure as Code
- All infrastructure is defined in CDK
- Regular commits to version control
- Automated deployment pipelines

## Support and Maintenance

### Regular Maintenance Tasks
1. Review CloudWatch alarms and metrics weekly
2. Update dependencies monthly
3. Review and rotate access keys quarterly
4. Conduct security reviews quarterly
5. Performance optimization reviews bi-annually

### Emergency Procedures
1. Check the monitoring dashboard first
2. Review recent deployments in GitHub Actions
3. Check AWS Service Health Dashboard
4. Use CloudWatch Insights for log analysis
5. Contact AWS Support if needed (with Business/Enterprise support)

## Contact Information

- **Development Team**: [team-email@company.com]
- **AWS Account ID**: [123456789012]
- **Primary Region**: us-east-1
- **Backup Region**: us-west-2

---

For additional support, refer to the AWS documentation or contact the development team.