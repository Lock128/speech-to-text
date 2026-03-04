# Anleitung: Handball-Spielzüge erstellen

Diese Anleitung zeigt Ihnen, wie Sie neue Handball-Spielzüge für die App beschreiben können.

## Was ist ein Spielzug?

Ein Spielzug besteht aus:
1. **Angreifende Spieler** - Ihre Mannschaft (blau)
2. **Verteidigende Spieler** - Die gegnerische Mannschaft (rot)
3. **Aktionen** - Was passiert: Pässe, Bewegungen, Würfe

## Das Spielfeld

Das Spielfeld wird in Zahlen von 0 bis 1 beschrieben:

### Von links nach rechts (X-Achse)
- 0.0 = ganz links
- 0.5 = Mitte
- 1.0 = ganz rechts

### Von Tor zur Mittellinie (Y-Achse)
- 0.0 = Torlinie
- 0.15 = 6-Meter-Linie
- 0.225 = 9-Meter-Linie
- 0.5 = Mittellinie

## Spielerpositionen

### Angreifer
- **LW** (Linksaußen) - ganz links
- **LR** (Rückraum Links) - links hinten
- **RM** (Rückraum Mitte) - Mitte hinten
- **RR** (Rückraum Rechts) - rechts hinten
- **RW** (Rechtsaußen) - ganz rechts
- **KM** (Kreisläufer) - vor dem Tor

### Verteidiger
- **D1** bis **D6** - stehen normalerweise auf der 6-Meter-Linie

## Was kann passieren?

1. **Pass** - Ball wird von einem Spieler zum anderen gepasst
2. **Bewegung** - Spieler läuft zu einer neuen Position
3. **Wurf** - Spieler wirft aufs Tor
4. **Block** - Spieler stellt einen Block für Mitspieler
5. **Schnitt** - Spieler macht eine schnelle Bewegung nach vorne

## Beispiel: Einfacher Spielzug

```markdown
# Spielzug: Angriff über Links

## Beschreibung
Der Ball wird von der Mitte nach links gespielt, der Linksaußen schneidet 
nach innen und bekommt den Ball zum Wurf.

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
- Ziel Y: 0.25
- Beschreibung: LW schneidet nach innen

### Aktion 3
- Typ: pass
- Von: a2
- Zu: a1
- Beschreibung: Pass zum LW

### Aktion 4
- Typ: shoot
- Spieler: a1
- Beschreibung: Wurf aufs Tor
```

## Tipps für gute Spielzüge

### Typische Positionen
- **Außenspieler**: X = 0.1 (links) oder 0.9 (rechts), Y = 0.35
- **Rückraumspieler**: X = 0.25 bis 0.75, Y = 0.45
- **Kreisläufer**: X = 0.5, Y = 0.2
- **Verteidiger**: Y = 0.15 (auf der 6-Meter-Linie)

### Bewegungen
- Kleine Schritte: 0.05 bis 0.1
- Große Läufe: 0.2 bis 0.3
- Schnittbewegungen: diagonal, ca. 0.1 bis 0.15

### Wichtig
- Jeder Spieler braucht eine eindeutige ID (a1, a2, d1, d2, etc.)
- X und Y müssen zwischen 0.0 und 1.0 liegen
- Aktionen werden in der Reihenfolge ausgeführt, wie sie aufgelistet sind

## Häufige Fehler vermeiden

1. Spieler nicht auf die gleiche Position setzen
2. Zahlen zwischen 0.0 und 1.0 verwenden
3. Alle Spieler-IDs müssen existieren
4. Aktionen durchnummerieren (1, 2, 3, ...)

## Nächste Schritte

Wenn Sie einen Spielzug erstellt haben, können Sie ihn an den Entwickler 
weitergeben, der ihn in die App einbaut.
