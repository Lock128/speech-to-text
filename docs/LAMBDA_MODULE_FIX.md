# Lambda Module Import Error Fix

## Problem
The Lambda function was failing with:
```
Runtime.ImportModuleError: Error: Cannot find module 'index'
```

This was causing the API to return 502 Internal Server Error, which prevented CORS headers from being returned, leading to CORS errors in the browser.

## Root Cause
The Lambda function deployment package was missing:
1. **Dependencies** - AWS SDK and other npm packages
2. **Utility modules** - The `utils/` directory with validation, logging, and UUID utilities
3. **Proper module structure** - Lambda couldn't find the required modules

## Solution Applied

### 1. Added package.json to Lambda Functions
**File**: `speech-to-email-backend/lambda/presigned-url-handler/package.json`
```json
{
  "name": "presigned-url-handler",
  "version": "1.0.0",
  "main": "index.js",
  "dependencies": {
    "@aws-sdk/client-s3": "^3.891.0",
    "@aws-sdk/s3-request-presigner": "^3.891.0",
    "uuid": "^13.0.0"
  }
}
```

**File**: `speech-to-email-backend/lambda/status-handler/package.json`
```json
{
  "name": "status-handler",
  "version": "1.0.0",
  "main": "index.js",
  "dependencies": {
    "@aws-sdk/client-dynamodb": "^3.891.0"
  }
}
```

### 2. Installed Dependencies
```bash
cd speech-to-email-backend/lambda/presigned-url-handler
npm install

cd ../status-handler
npm install
```

### 3. Fixed Import Paths
**Before**: `import { InputValidator } from '../utils/validation';`
**After**: `import { InputValidator } from './utils/validation';`

This ensures the utils are imported from the local directory rather than a relative path that might not exist in the deployment package.

### 4. Copied Utils to Lambda Directories
```bash
cp -r ../utils ./
```

This ensures each Lambda function has its own copy of the utility modules.

### 5. Recompiled TypeScript
```bash
npm run build
```

## Verification
The Lambda function now works correctly locally:
- ✅ Imports all required modules
- ✅ Returns proper CORS headers
- ✅ Generates presigned URLs successfully
- ✅ Handles validation and logging

## Deployment
Run the deployment script:
```bash
cd speech-to-email-backend
./deploy-lambda-fix.sh
```

Or manually:
```bash
npm run build
npx cdk deploy
```

## Testing
After deployment, test the API:
```bash
curl -X POST https://1uds19zmja.execute-api.eu-central-1.amazonaws.com/prod/presigned-url \
  -H "Content-Type: application/json" \
  -H "Origin: http://localhost:49630" \
  -d '{"fileName":"test.mp3","fileSize":1024,"contentType":"audio/mpeg"}'
```

Expected response:
- Status: 200 OK
- Headers: Proper CORS headers including `Access-Control-Allow-Origin: *`
- Body: JSON with `uploadUrl`, `recordId`, and `expiresIn`

## What This Fixes
- ✅ **Lambda function execution** - No more module import errors
- ✅ **CORS headers** - Proper headers returned from Lambda
- ✅ **API functionality** - Presigned URL generation works
- ✅ **Flutter app integration** - No more CORS errors in browser

## Architecture Notes
Each Lambda function now has:
- Its own `package.json` with required dependencies
- Local copy of utility modules
- Proper module imports
- All dependencies bundled in deployment package

This ensures the Lambda runtime can find all required modules and execute successfully.