# Circular Dependency Fix

## Problem
The CDK stack had a complex circular dependency involving:
- Shared IAM role used by multiple Lambda functions
- Explicit CloudWatch log groups
- Complex monitoring setup with alarms and dashboards
- CloudFront distribution referencing API Gateway

## Solution Applied

### 1. Separated IAM Roles
- **Before**: Single `lambdaExecutionRole` shared by all Lambda functions
- **After**: Individual roles for each Lambda function:
  - `uploadHandlerRole`
  - `presignedUrlHandlerRole` 
  - `statusHandlerRole`
  - `transcriptionHandlerRole`
  - `emailHandlerRole`
  - `sesNotificationHandlerRole`

### 2. Removed Explicit Log Groups
- **Before**: Explicit CloudWatch log groups created for each Lambda
- **After**: Lambda functions automatically create their own log groups

### 3. Simplified CloudFront
- **Before**: CloudFront with API Gateway behavior causing circular dependency
- **After**: CloudFront serves only static content, API calls go directly to API Gateway

### 4. Removed Complex Monitoring
- **Before**: Complex CloudWatch alarms, dashboards, and SNS topics
- **After**: Basic deployment without monitoring (to be added later)

## What Was Removed Temporarily
- CloudWatch alarms for Lambda functions
- CloudWatch dashboard
- SNS alert topic
- Custom log groups
- CloudWatch Insights queries
- Complex monitoring widgets

## Next Steps
1. **Deploy the simplified stack** - Should work without circular dependencies
2. **Add monitoring incrementally** - Create a separate monitoring stack
3. **Test functionality** - Ensure all Lambda functions work correctly
4. **Add monitoring back** - In a separate stack to avoid dependencies

## Benefits
- Clean deployment without circular dependencies
- Easier to debug and maintain
- Better separation of concerns
- Can add monitoring incrementally

## Architecture Notes
- Frontend calls API Gateway directly (not through CloudFront)
- Each Lambda has minimal required permissions
- Monitoring can be added as a separate stack later