# Architecture Notes

## CloudFront and API Gateway Separation

### Issue
The original design had CloudFront serving both the Flutter web app and proxying API requests to API Gateway. This created a circular dependency in CloudFormation because:

1. CloudFront distribution references API Gateway as an origin
2. API Gateway deployment depends on Lambda functions
3. Lambda functions have CloudWatch alarms and other resources
4. These resources can create implicit dependencies back to CloudFront

### Solution
We separated the concerns:

- **CloudFront**: Serves only the static Flutter web app from S3
- **API Gateway**: Handles API requests directly (not through CloudFront)

### Frontend Configuration
In your Flutter app, configure API calls to use the direct API Gateway URL:

```dart
// Use the ApiGatewayUrl output from CDK deployment
const String apiBaseUrl = 'https://your-api-id.execute-api.region.amazonaws.com/prod';

// Make API calls directly to API Gateway
final response = await http.post(
  Uri.parse('$apiBaseUrl/presigned-url'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode(requestData),
);
```

### Benefits
1. **No circular dependencies**: Clean separation of static content and API
2. **Better performance**: Static content cached by CloudFront, API calls go direct
3. **Easier debugging**: Clear separation between frontend and backend requests
4. **Cost optimization**: No unnecessary CloudFront charges for API requests

### CORS Configuration
The API Gateway is configured with CORS to allow requests from any origin, including your CloudFront domain.

### Security
- API Gateway is protected by WAF rules
- CloudFront serves static content with appropriate caching headers
- Both use HTTPS only