# Team and Player Integration

## Overview
Extended the recording screen to include team selection with coach and player information. Users can edit the coach name and add additional players on demand. This data is passed to the backend and included in Bedrock prompts for better article generation.

## Changes Made

### Frontend (Flutter App)

#### 1. New Models
- **`lib/models/team_models.dart`**: Created `TeamInfo` model to represent team data with coach and players

#### 2. Configuration Files
- **`assets/config/teams.json`**: JSON configuration file containing all teams with their coaches and player rosters
  - Männer I (Coach: Thomas Müller)
  - Männer II (Coach: Michael Schneider)
  - Damen (Coach: Sarah Bauer)
  - mC1 (Coach: Peter Herrmann)
  - mC2 (Coach: Klaus Zimmermann)

#### 3. Services
- **`lib/services/team_config_service.dart`**: Service to load and cache team configurations from JSON

#### 4. Widgets
- **`lib/widgets/team_selector.dart`**: Interactive widget for team selection with:
  - Team dropdown with coach preview
  - Editable coach name field
  - Display of roster players from config
  - "Add Player" button to add additional players
  - Remove button for additional players (green chips)
  - Visual distinction between roster (blue) and additional (green) players

#### 5. Updated Files
- **`lib/providers/recording_provider.dart`**: 
  - Added team selection state
  - Added custom player list management
  - Method to get effective player list (roster + additional)
- **`lib/services/upload_service.dart`**: Added team and player parameters to upload
- **`lib/models/api_models.dart`**: Updated `PresignedUrlRequest` to include team/player data
- **`lib/screens/recording_screen.dart`**: 
  - Integrated team selector widget
  - Connected coach and player change callbacks
- **`pubspec.yaml`**: Added assets configuration for teams.json

## User Features

### Editable Coach Name
- Coach name auto-populates from team selection
- Click the text field to edit the coach name
- Press Enter or click the checkmark to update
- Changes persist across recordings

### Add Additional Players
1. Select a team from the dropdown
2. Click "Add Player" button
3. Enter player name in the dialog
4. Player appears as a green chip (removable)
5. Click X on green chip to remove additional player

### Visual Indicators
- **Blue chips**: Roster players from configuration (not removable)
- **Green chips**: Additional players you added (removable with X button)
- Player count shows total: roster + additional players

### Backend (AWS Lambda)

#### 1. Presigned URL Handler
- **`lambda/presigned-url-handler/index.ts`**: 
  - Added `teamName` and `playerNames` to request interface
  - Store team/player info in S3 object metadata
  - Log team information for debugging

#### 2. Upload Handler
- **`lambda/upload-handler/index.ts`**:
  - Extract team and player names from S3 metadata
  - Store in DynamoDB record for later use

#### 3. Article Enhancement Handler
- **`lambda/article-enhancement-handler/index.ts`**:
  - Retrieve team and player information from DynamoDB
  - Include in Bedrock prompt with placeholders `{teamInfo}` and player roster
  - Enhanced prompt now includes:
    - Team name
    - Coach name
    - Full player roster

## Data Flow

1. **User Selection**: User selects team, optionally edits coach, and adds additional players
2. **Upload**: Team name, coach, and complete player list (roster + additional) sent with audio file
3. **Storage**: Information stored in S3 metadata and DynamoDB
4. **Processing**: Bedrock receives context about team, coach, and all players
5. **Article Generation**: AI uses this information to create accurate articles mentioning all players

## Bedrock Prompt Enhancement

The prompt now includes:
```
{teamInfo}
Das Team ist: [Team Name].
Die Spieler im Kader sind: [Player1, Player2, ...].

{coachInfo}
Der Trainer des HC VfL Heppenheim ist [Coach Name].
```

This ensures the AI has complete context about:
- Which team is playing
- Who the coach is
- Which players are available in the roster

## Configuration

To modify team rosters, edit `speech_to_email_app/assets/config/teams.json`:

```json
{
  "teams": [
    {
      "id": "maennerI",
      "name": "Männer I",
      "coach": "Thomas Müller",
      "players": ["Player1", "Player2", ...]
    }
  ]
}
```

## Testing

1. Run the Flutter app
2. Select a team from the dropdown
3. Edit the coach name if needed
4. Click "Add Player" to add guest players or substitutes
5. Verify all players display (blue for roster, green for additional)
6. Record and upload audio
7. Check backend logs for team/player metadata
8. Verify article includes team context and all players

## Future Enhancements

- Allow dynamic team/player management through settings
- Sync team data from external API
- Add player statistics and positions
- Include team formation preferences
- Save frequently used additional players
- Player search/autocomplete for quick selection
