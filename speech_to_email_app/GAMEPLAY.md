# Gameplay Feature

## Overview
The Gameplay tab allows users to select teams and their associated Spielzüge (plays/tactics). The data is organization-specific, meaning each organization has its own set of plays.

## Features

### Organization-Specific Data
- **HC VfL Heppenheim** - Has handball-specific plays in German
- **Demo** - Has generic demo plays for testing

### Team Selection (Mannschaft)
Users can select from 5 teams:
- Männer I
- Männer II
- Damen
- mC1
- mC2

### Spielzug Selection
- Dropdown/combobox interface for selecting plays
- Shows "-- Bitte wählen --" as placeholder
- Displays all available plays for the selected team
- Selected play is shown in a highlighted card below

### Management Features
- Add new Spielzüge via settings icon
- Edit existing Spielzüge
- Delete Spielzüge
- Reset to organization defaults

## Default Spielzüge

### HC VfL Heppenheim

**Männer I:**
- Angriff Links
- Angriff Rechts
- Konter Mitte
- Tempogegenstoß
- Kreis Anspiel

**Männer II:**
- Angriff Links
- Angriff Rechts
- Konter Mitte
- Kreis Anspiel

**Damen:**
- Angriff Links
- Angriff Rechts
- Konter Mitte
- Tempogegenstoß
- Kreis Anspiel

**mC1:**
- Angriff Links
- Angriff Rechts
- Konter Mitte

**mC2:**
- Angriff Links
- Angriff Rechts
- Konter Mitte

### Demo Organization

**Männer I:**
- Demo Play 1
- Demo Play 2
- Demo Play 3

**Männer II:**
- Demo Play A
- Demo Play B

**Damen:**
- Demo Play X
- Demo Play Y
- Demo Play Z

**mC1:**
- Demo Youth Play 1
- Demo Youth Play 2

**mC2:**
- Demo Youth Play A
- Demo Youth Play B

## Data Storage

- Spielzüge are stored per organization using shared_preferences
- Storage key format: `spielzuege_data_{organization_name}`
- Data persists across app restarts
- Each organization maintains separate play lists

## User Flow

1. User must select an organization in Settings first
2. Navigate to Gameplay tab
3. Select a team from the Mannschaft dropdown
4. Select a Spielzug from the dropdown
5. Selected play is displayed in a card below
6. Use settings icon to manage plays (add/edit/delete)

## Technical Details

### Files
- `lib/models/gameplay_models.dart` - Team and Spielzug models
- `lib/services/gameplay_service.dart` - Data persistence and defaults
- `lib/providers/gameplay_provider.dart` - State management
- `lib/screens/gameplay_screen.dart` - UI implementation

### Organization Sync
- Gameplay provider automatically syncs with the selected organization
- When organization changes, team and play selections are reset
- Ensures users always see data for their current organization
