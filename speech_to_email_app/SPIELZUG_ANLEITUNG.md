# Anleitung: Spielzüge erstellen

Diese Anleitung erklärt, wie Sie neue Handball-Spielzüge für die App erstellen können.

## Übersicht

Ein Spielzug besteht aus drei Hauptkomponenten:
1. **Angreifende Spieler** - Die Spieler des angreifenden Teams
2. **Verteidigende Spieler** - Die Spieler des verteidigenden Teams
3. **Aktionen** - Die Sequenz von Bewegungen, Pässen und Würfen

## Koordinatensystem

Das Spielfeld verwendet ein normalisiertes Koordinatensystem:
- **X-Achse**: 0.0 (links) bis 1.0 (rechts)
- **Y-Achse**: 0.0 (Tor) bis 1.0 (Mittellinie)

### Wichtige Linien
- **6m-Linie**: Y = 0.15
- **9m-Linie**: Y = 0.225
- **Mittellinie**: Y = 0.5

### Typische Spielerpositionen (Y-Koordinaten)
- Tor: 0.0 - 0.05
- 6m-Linie: 0.15
- 9m-Linie: 0.225
- Rückraum: 0.45 - 0.5

## Spielerpositionen

### Angreifende Positionen
- **LW** (Linksaußen): `PlayerPosition.leftWing`
- **LR** (Rückraum Links): `PlayerPosition.leftBack`
- **RM** (Rückraum Mitte): `PlayerPosition.centerBack`
- **RR** (Rückraum Rechts): `PlayerPosition.rightBack`
- **RW** (Rechtsaußen): `PlayerPosition.rightWing`
- **KM** (Kreisläufer): `PlayerPosition.pivot`

### Verteidigende Positionen
- **defLeftWing**: Verteidiger Links Außen
- **defLeftBack**: Verteidiger Links
- **defCenterLeft**: Verteidiger Mitte Links
- **defCenterRight**: Verteidiger Mitte Rechts
- **defRightBack**: Verteidiger Rechts
- **defRightWing**: Verteidiger Rechts Außen

## Aktionstypen

1. **Pass** (`ActionType.pass`)
   - Ball wird von einem Spieler zum anderen gepasst
   - Benötigt: `playerId` und `targetPlayerId`

2. **Bewegung** (`ActionType.move`)
   - Spieler bewegt sich zu einer neuen Position
   - Benötigt: `playerId` und `targetPosition`

3. **Wurf** (`ActionType.shoot`)
   - Spieler wirft aufs Tor
   - Benötigt: nur `playerId`

4. **Block** (`ActionType.screen`)
   - Spieler stellt einen Block
   - Benötigt: `playerId` und `targetPosition`

5. **Schnitt** (`ActionType.cut`)
   - Spieler macht eine Schnittbewegung
   - Benötigt: `playerId` und `targetPosition`

## Markdown-Format für Spielzüge

Erstellen Sie eine Textdatei mit folgendem Format:

```markdown
# Spielzug: [Name des Spielzugs]

## Beschreibung
[Kurze Beschreibung des Spielzugs]

## Angreifende Spieler

### Spieler 1
- ID: a1
- Name: LW
- Position: leftWing
- X: 0.1
- Y: 0.35

### Spieler 2
- ID: a2
- Name: LR
- Position: leftBack
- X: 0.25
- Y: 0.45

[... weitere Spieler ...]

## Verteidigende Spieler

### Spieler 1
- ID: d1
- Name: D1
- Position: defLeftWing
- X: 0.15
- Y: 0.15

[... weitere Spieler ...]

## Aktionen

### Aktion 1
- Typ: pass
- Von: a3
- Zu: a2
- Beschreibung: Pass von RM zu LR

### Aktion 2
- Typ: move
- Spieler: a1
- Ziel X: 0.15
- Ziel Y: 0.25
- Beschreibung: LW schneidet nach innen

### Aktion 3
- Typ: pass
- Von: a2
- Zu: a1
- Beschreibung: Pass zu LW

### Aktion 4
- Typ: shoot
- Spieler: a1
- Beschreibung: Wurf aufs Tor
```

## Beispiel: Kompletter Spielzug

```markdown
# Spielzug: Angriff Links mit Doppelpass

## Beschreibung
Angriff über die linke Seite mit Doppelpass zwischen LR und LW

## Angreifende Spieler

### Spieler 1
- ID: a1
- Name: LW
- Position: leftWing
- X: 0.1
- Y: 0.35

### Spieler 2
- ID: a2
- Name: LR
- Position: leftBack
- X: 0.25
- Y: 0.45

### Spieler 3
- ID: a3
- Name: RM
- Position: centerBack
- X: 0.5
- Y: 0.5

### Spieler 4
- ID: a6
- Name: KM
- Position: pivot
- X: 0.5
- Y: 0.2

## Verteidigende Spieler

### Spieler 1
- ID: d1
- Name: D1
- Position: defLeftWing
- X: 0.15
- Y: 0.15

### Spieler 2
- ID: d2
- Name: D2
- Position: defLeftBack
- X: 0.3
- Y: 0.16

### Spieler 3
- ID: d3
- Name: D3
- Position: defCenterLeft
- X: 0.45
- Y: 0.165

## Aktionen

### Aktion 1
- Typ: pass
- Von: a3
- Zu: a2
- Beschreibung: Pass von RM zu LR

### Aktion 2
- Typ: move
- Spieler: a1
- Ziel X: 0.2
- Ziel Y: 0.3
- Beschreibung: LW läuft nach innen

### Aktion 3
- Typ: pass
- Von: a2
- Zu: a1
- Beschreibung: Pass zu LW

### Aktion 4
- Typ: move
- Spieler: a2
- Ziel X: 0.15
- Ziel Y: 0.25
- Beschreibung: LR schneidet nach vorne

### Aktion 5
- Typ: pass
- Von: a1
- Zu: a2
- Beschreibung: Rückpass zu LR

### Aktion 6
- Typ: shoot
- Spieler: a2
- Beschreibung: Wurf aufs Tor
```

## Code-Vorlage für handball_play_service.dart

Nachdem Sie Ihren Spielzug im Markdown-Format erstellt haben, können Sie ihn mit dieser Vorlage in Code umwandeln:

```dart
static HandballPlay _createMeinSpielzug() {
  final attackingPlayers = [
    const Player(
      id: 'a1',
      name: 'LW',
      position: PlayerPosition.leftWing,
      initialPosition: Offset(0.1, 0.35),
      color: Colors.blue,
    ),
    // Weitere Spieler hinzufügen...
  ];

  final defendingPlayers = [
    const Player(
      id: 'd1',
      name: 'D1',
      position: PlayerPosition.defLeftWing,
      initialPosition: Offset(0.15, 0.15),
      color: Colors.red,
    ),
    // Weitere Verteidiger hinzufügen...
  ];

  final actions = [
    const PlayAction(
      id: 'act1',
      type: ActionType.pass,
      playerId: 'a3',
      targetPlayerId: 'a2',
      sequenceNumber: 1,
      description: 'Pass von RM zu LR',
    ),
    // Weitere Aktionen hinzufügen...
  ];

  return HandballPlay(
    id: 'play_mein_spielzug',
    name: 'Mein Spielzug',
    attackingPlayers: attackingPlayers,
    defendingPlayers: defendingPlayers,
    actions: actions,
    description: 'Beschreibung des Spielzugs',
  );
}
```

## Integration in die App

1. Öffnen Sie `lib/services/handball_play_service.dart`

2. Fügen Sie Ihren neuen Spielzug zur `getDefaultPlay` Methode hinzu:

```dart
static HandballPlay getDefaultPlay(String playName) {
  switch (playName) {
    case 'Angriff Links':
      return _createAngriffLinks();
    case 'Mein Neuer Spielzug':  // NEU
      return _createMeinSpielzug();  // NEU
    default:
      return _createDefaultPlay(playName);
  }
}
```

3. Fügen Sie die neue Methode `_createMeinSpielzug()` am Ende der Datei hinzu

4. Fügen Sie den Spielzug-Namen zu Ihrer Spielzug-Liste in der Datenbank/Konfiguration hinzu

## Tipps und Best Practices

### Positionierung
- **Außenspieler (LW/RW)**: X = 0.1 oder 0.9, Y = 0.35
- **Rückraumspieler**: X = 0.25-0.75, Y = 0.45-0.5
- **Kreisläufer**: X = 0.4-0.6, Y = 0.18-0.22
- **Verteidiger (6-0)**: Y = 0.15-0.165

### Bewegungen
- Kleine Schritte: 0.05-0.1 Einheiten
- Große Sprints: 0.2-0.3 Einheiten
- Schnittbewegungen: Diagonal, ca. 0.1-0.15 Einheiten

### Timing
- Standard-Verzögerung: 500ms zwischen Aktionen
- Schnelle Pässe: 300-400ms
- Langsame Bewegungen: 700-1000ms

### Spieler-IDs
- Angreifer: 'a1', 'a2', 'a3', etc.
- Verteidiger: 'd1', 'd2', 'd3', etc.
- IDs müssen eindeutig sein

## Häufige Fehler

1. **Überlappende Spieler**: Achten Sie darauf, dass Spieler nicht auf exakt derselben Position stehen
2. **Ungültige Koordinaten**: X und Y müssen zwischen 0.0 und 1.0 liegen
3. **Falsche Spieler-IDs**: Stellen Sie sicher, dass alle IDs in Aktionen existieren
4. **Fehlende sequenceNumber**: Aktionen müssen aufsteigend nummeriert sein

## Testen

Nach dem Hinzufügen eines neuen Spielzugs:
1. Starten Sie die App neu
2. Wählen Sie Ihr Team
3. Wählen Sie den neuen Spielzug aus dem Dropdown
4. Testen Sie die Animation mit verschiedenen Geschwindigkeiten
5. Probieren Sie verschiedene Abwehrformationen aus

## Weitere Hilfe

Bei Fragen oder Problemen:
- Schauen Sie sich die bestehenden Spielzüge als Referenz an
- Testen Sie mit einfachen Spielzügen (wenige Spieler, wenige Aktionen)
- Erhöhen Sie schrittweise die Komplexität
