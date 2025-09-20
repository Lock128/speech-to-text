# CORS Error Fix

## Problem
The Flutter web app was getting a CORS error when trying to call the API Gateway:
```
Access to XMLHttpRequest at 'https://1uds19zmja.execute-api.eu-central-1.amazonaws.com/prod//presigned-url' from origin 'http://localhost:49453' has been blocked by CORS policy: No 'Access-Control-Allow-Origin' header is present on the requested resource.
```

## Root Causes
1. **Double slash in URL** - The API URL ended with `/` and `/presigned-url` was appended, creating `//presigned-url`
2. **Incomplete CORS headers** - Lambda functions and API Gateway needed more comprehensive CORS configuration
3. **Mismatched API URL** - Flutter app was using a default URL instead of the deployed API Gateway URL

## Fixes Applied

### 1. Fixed Double Slash Issue
**File**: `speech_to_email_app/start.sh`
- **Before**: `https://1uds19zmja.execute-api.eu-central-1.amazonaws.com/prod/`
- **After**: `https://1uds19zmja.execute-api.eu-central-1.amazonaws.com/prod` (removed trailing slash)

### 2. Updated Flutter App Configuration
**File**: `speech_to_email_app/lib/config/app_config.dart`
- Updated `apiBaseUrl` to use the correct deployed API Gateway URL
- Removed trailing slash to prevent double slash issues

### 3. Enhanced API Gateway CORS Configuration
**File**: `speech-to-email-backend/lib/speech-to-email-stack.ts`
- Added more comprehensive CORS headers:
  ```typescript
  allowHeaders: [
    'Content-Type', 
    'X-Amz-Date', 
    'Authorization', 
    'X-Api-Key',
    'X-Amz-Security-Token',
    'X-Amz-User-Agent'
  ]
  ```
- Explicitly defined allowed methods
- Set `allowCredentials: false`

### 4. Updated Lambda Function CORS Headers
**Files**: 
- `speech-to-email-backend/lambda/presigned-url-handler/index.ts`
- `speech-to-email-backend/lambda/status-handler/index.ts`

Enhanced CORS headers in Lambda responses:
```typescript
const corsHeaders = {
  'Content-Type': 'application/json',
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'Content-Type, X-Amz-Date, Authorization, X-Api-Key, X-Amz-Security-Token, X-Amz-User-Agent',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Credentials': 'false',
};
```

## How to Test the Fix

### 1. Deploy Updated Backend
```bash
cd speech-to-email-backend
npm run build
npx cdk deploy
```

### 2. Run Flutter App with Correct API URL
```bash
cd speech_to_email_app
chmod +x start.sh
./start.sh
```

### 3. Test API Call
The Flutter app should now successfully call the API without CORS errors.

## What Changed
- ✅ **No more double slash** - URL is now correctly formed
- ✅ **Comprehensive CORS headers** - Both API Gateway and Lambda functions return proper CORS headers
- ✅ **Correct API URL** - Flutter app uses the deployed API Gateway URL
- ✅ **Consistent configuration** - All components use the same CORS policy

## Security Notes
- **Current setting**: `Access-Control-Allow-Origin: '*'` allows all origins
- **Production recommendation**: Restrict to specific domains:
  ```typescript
  'Access-Control-Allow-Origin': 'https://yourdomain.com'
  ```

## Troubleshooting
If you still get CORS errors:

1. **Check browser developer tools** - Look for preflight OPTIONS requests
2. **Verify API Gateway deployment** - Ensure changes are deployed
3. **Clear browser cache** - CORS policies can be cached
4. **Check Lambda logs** - Verify functions are returning correct headers

## Testing Commands
```bash
# Test API directly with curl
curl -X POST https://1uds19zmja.execute-api.eu-central-1.amazonaws.com/prod/presigned-url \
  -H "Content-Type: application/json" \
  -d '{"fileName":"test.mp3","fileSize":1024,"contentType":"audio/mpeg"}'

# Test preflight request
curl -X OPTIONS https://1uds19zmja.execute-api.eu-central-1.amazonaws.com/prod/presigned-url \
  -H "Origin: http://localhost:3000" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: Content-Type"
```