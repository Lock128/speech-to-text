# Backend Integration Guide

## Overview

The app now supports loading Spielzüge (plays) from either:
1. **Local Storage** (default) - Data stored on device
2. **Backend API** (optional) - Data from AWS DynamoDB

## How It Works

### Architecture

```
UI (gameplay_screen.dart)
    ↓
GameplayProvider
    ↓
GameplayService ←→ HandballApiService → AWS API Gateway → Lambda → DynamoDB
    ↓
Local Storage (SharedPreferences)
```

### Data Flow

1. **User selects a team** → GameplayProvider calls GameplayService
2. **GameplayService checks** → Should use backend or local?
3. **If backend enabled**:
   - Calls HandballApiService
   - Fetches data from AWS API
   - Falls back to local if API fails
4. **If backend disabled**:
   - Reads from SharedPreferences
   - Uses hardcoded defaults if nothing saved

## Configuration

### 1. Enable Backend API

Go to **Settings** → Toggle **"Use Backend API"**

When enabled:
- ✅ Spielzüge loaded from AWS DynamoDB
- ✅ Changes synced to backend
- ✅ Automatic fallback to local storage if API fails

When disabled:
- ✅ Spielzüge stored locally on device
- ✅ Works offline
- ✅ No API calls

### 2. Configure API Credentials

Edit `lib/services/handball_api_service.dart`:

```dart
static const String _baseUrl = 'https://YOUR_API_URL/prod/handball';
static const String _apiKey = 'YOUR_API_KEY';
```

Replace:
- `YOUR_API_URL` with your API Gateway URL
- `YOUR_API_KEY` with your API key from AWS Console

## Features

### Automatic Fallback

If the backend API fails, the app automatically falls back to local storage:

```dart
try {
  // Try backend
  final data = await _apiService.getSpielzuege(teamId: teamId);
  return data;
} catch (e) {
  print('Backend failed, using local storage');
  // Fall back to local
  return localData;
}
```

### CRUD Operations

All operations work with both backend and local storage:

- **Create**: `addSpielzug()` - Creates in backend or local
- **Read**: `getSpielzuegeForTeam()` - Fetches from backend or local
- **Update**: `updateSpielzug()` - Updates in backend or local
- **Delete**: `removeSpielzug()` - Deletes from backend or local

## Testing

### Test with Local Storage

1. Go to Settings
2. Ensure "Use Backend API" is **OFF**
3. Add/edit/delete Spielzüge
4. Data is stored locally

### Test with Backend API

1. Deploy backend (see `HANDBALL_API_SETUP.md`)
2. Configure API URL and key
3. Go to Settings
4. Toggle "Use Backend API" **ON**
5. Add/edit/delete Spielzüge
6. Data is synced to AWS

### Test Fallback

1. Enable backend API
2. Turn off internet/WiFi
3. App should automatically use local storage
4. No errors or crashes

## Development

### Adding New Fields

To add new fields to Spielzüge:

1. **Update DynamoDB schema** (backend)
2. **Update `SpielzugData` model** in `handball_api_service.dart`
3. **Update `Spielzug` model** in `gameplay_models.dart`
4. **Update API calls** in `HandballApiService`
5. **Update GameplayService** to handle new fields

### Adding New Endpoints

1. **Add Lambda handler** in `handball-data-handler/index.ts`
2. **Add API Gateway route** in `speech-to-email-stack.ts`
3. **Add method** in `HandballApiService`
4. **Call from GameplayService**

## Troubleshooting

### "Failed to load spielzuege"

**Possible causes**:
1. Backend API not configured
2. Invalid API key
3. Network connection issues
4. Backend not deployed

**Solution**: Check Settings → Backend API toggle. If enabled, verify API URL and key.

### Data not syncing

**Check**:
1. Is "Use Backend API" enabled in Settings?
2. Is the API key correct?
3. Is the backend deployed?
4. Check console logs for errors

### App crashes when toggling backend

**Solution**: Make sure `http` package is added to `pubspec.yaml`:

```yaml
dependencies:
  http: ^1.1.0
```

## Security Notes

⚠️ **API Key in Code**
- The API key is embedded in the app
- Can be extracted by tech-savvy users
- Acceptable for Phase 1 (internal team app)
- For production, upgrade to AWS Cognito

✅ **Best Practices**:
- Use backend API for team-wide data
- Use local storage for personal preferences
- Backend has rate limiting (10 req/sec)
- All API calls use HTTPS

## Next Steps

### Phase 2: User Authentication

Upgrade to AWS Cognito for:
- User accounts (sign up/sign in)
- Role-based access (admin vs viewer)
- Secure user-specific data
- No embedded API keys

### Phase 3: Real-time Sync

Add real-time updates:
- WebSocket connections
- Push notifications
- Automatic sync when data changes
- Conflict resolution

## Support

For issues or questions:
1. Check console logs for errors
2. Verify backend deployment
3. Test with local storage first
4. Check API Gateway logs in AWS Console
