# Authentication System

## Overview
The app now includes an organization-based authentication system that restricts access to the Upload/Recording feature.

## Features

### Organization Selection
Users can select from the following organizations:
- **HC VfL Heppenheim** - Access key: `hc_vfl_key_2024`
- **Demo** - Access key: `demo_key_2024`

### Access Control
- The Recording/Upload screen is locked until the user authenticates
- Users must:
  1. Select an organization in Settings
  2. Enter the correct access key for that organization
  3. Successfully authenticate

### Persistent Storage
- Organization selection and authentication status are stored using `shared_preferences`
- Authentication persists across app restarts
- Users remain authenticated until they manually logout

## Implementation Details

### Files Created/Modified

1. **`lib/services/auth_service.dart`**
   - Manages authentication logic
   - Stores/retrieves organization and auth status
   - Validates access keys

2. **`lib/providers/auth_provider.dart`**
   - State management for authentication
   - Exposes authentication state to UI
   - Handles organization selection and authentication

3. **`lib/screens/settings_screen.dart`**
   - Organization dropdown selector
   - Access key input field with visibility toggle
   - Authentication status display
   - Logout functionality

4. **`lib/screens/recording_screen.dart`**
   - Checks authentication status
   - Shows locked screen if not authenticated
   - Provides "Go to Settings" button for unauthenticated users

5. **`lib/main.dart`**
   - Added `AuthProvider` to the provider tree

## Usage

### For Users
1. Open the app and navigate to Settings
2. Select your organization from the dropdown
3. Enter the access key provided by your organization
4. Tap "Authenticate"
5. Navigate to the Upload tab to use the recording feature

### For Developers
To add a new organization:
1. Open `lib/services/auth_service.dart`
2. Add a new entry to the `Organization` enum:
   ```dart
   newOrg('Display Name', 'access_key_here'),
   ```

To change access keys:
1. Update the access key in the `Organization` enum
2. Existing authenticated users will need to re-authenticate

## Security Notes
- Access keys are stored locally on the device
- Keys are validated on each app launch
- This is a basic authentication system suitable for controlling access
- For production use, consider implementing server-side authentication
