# Handball Play Visualization

## Overview
The gameplay feature now includes an animated handball court visualization that shows tactical plays with attacking and defending teams, player movements, and ball passing sequences.

## Features

### Handball Court
- Realistic handball court layout with:
  - Goal area (6m line)
  - Free throw line (9m line)
  - Center line
  - Goal visualization
- Proportional dimensions (20m x 40m half court)

### Teams
- **Attacking Team** (Blue)
  - 6 players in standard positions
  - LW (Linksaußen) - Left Wing
  - LR (Rückraum Links) - Left Back
  - RM (Rückraum Mitte) - Center Back
  - RR (Rückraum Rechts) - Right Back
  - RW (Rechtsaußen) - Right Wing
  - KM (Kreisläufer) - Pivot

- **Defending Team** (Red)
  - 6 defenders in 6-0 formation
  - Positioned along the 9m line

### Animation System
- **Play/Stop Controls** - Start and stop the animation
- **Restart Button** - Reset and replay the sequence
- **Automatic Sequencing** - Actions play in order with delays
- **Smooth Transitions** - Animated player movements and ball passes

### Action Types
1. **Pass** - Ball passes between players with trajectory visualization
2. **Move** - Player movement to new positions
3. **Shoot** - Shot towards goal
4. **Screen** - Blocking movements
5. **Cut** - Cutting movements through defense

## Predefined Plays

### Angriff Links (Attack Left)
- Pass from center to left back
- Left wing cuts inside
- Pass to left wing
- Shot on goal

### Angriff Rechts (Attack Right)
- Pass from center to right back
- Right wing cuts inside
- Pass to right wing
- Shot on goal

### Konter Mitte (Counter Middle)
- Fast break through center
- Center back runs forward
- Breaks through defense
- Shot on goal

### Tempogegenstoß (Fast Break)
- Quick counter attack
- Left wing sprints forward
- Long pass from center
- Run to goal and shoot

### Kreis Anspiel (Pivot Play)
- Pivot moves to position
- Pass to pivot
- Shot from pivot position

## Technical Implementation

### Models (`handball_models.dart`)
- `PlayerPosition` - Enum for all positions
- `Player` - Player data with position and color
- `ActionType` - Types of actions (pass, move, shoot, etc.)
- `PlayAction` - Individual action in sequence
- `HandballPlay` - Complete play with players and actions

### Visualization (`handball_court.dart`)
- `HandballCourt` - Main widget with animation controller
- `HandballCourtPainter` - Custom painter for court and players
- Animated ball trajectories
- Player position interpolation
- Sequential action execution

### Play Service (`handball_play_service.dart`)
- Predefined plays for each Spielzug name
- Default play generator
- Player positioning logic
- Action sequence definitions

## User Experience

1. Select a team from the Mannschaft dropdown
2. Select a Spielzug from the dropdown
3. View the selected play name in the card
4. See the handball court visualization below
5. Click Play to start the animation
6. Watch players move and pass the ball
7. Use Restart to replay the sequence

## Visual Elements

- **Blue circles** - Attacking players with position labels
- **Red circles** - Defending players
- **Orange circle** - Ball (shown with player or in flight)
- **Orange line** - Ball trajectory during passes
- **Court lines** - White lines for areas and zones
- **Red goal** - Target for shots

## Customization

To add new plays:
1. Open `handball_play_service.dart`
2. Create a new method like `_createNewPlay()`
3. Define attacking and defending players with positions
4. Create action sequence with passes, moves, and shots
5. Add to `getDefaultPlay()` switch statement

## Future Enhancements

Potential additions:
- Custom play editor
- More defensive formations (5-1, 3-2-1)
- Player names customization
- Export/import plays
- Slow motion controls
- Step-by-step mode
- Multiple camera angles
