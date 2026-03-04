# Handball API Setup Guide

Diese Anleitung erklärt, wie Sie das Backend für die dynamische Verwaltung von Handball-Daten einrichten.

## Übersicht

Das Backend bietet folgende Funktionen:
- **Organisationen**: Verwaltung von Handball-Organisationen (z.B. HC VfL Heppenheim)
- **Teams**: Verwaltung von Teams mit Trainern und Spielern
- **Spielzüge**: Verwaltung von Spielzügen für jedes Team

## Deployment

### 1. Backend deployen

```bash
cd speech-to-email-backend
npm install
npm run build
cdk deploy
```

Nach dem Deployment erhalten Sie die API Gateway URL in den Outputs:
```
ApiGatewayUrl = https://xxxxxxxxxx.execute-api.eu-central-1.amazonaws.com/prod/
```

### 2. Datenbank initialisieren

Installieren Sie die Dependencies für das Init-Skript:

```bash
cd speech-to-email-backend
npm install @aws-sdk/client-dynamodb @aws-sdk/lib-dynamodb
```

Führen Sie das Initialisierungsskript aus:

```bash
npx ts-node scripts/init-handball-data.ts
```

Dies erstellt:
- Die Organisation "HC VfL Heppenheim"
- Alle 5 Teams (Männer I, Männer II, Damen, mC1, mC2) mit Trainern und Spielern
- Die 4 Spielzüge (Leer 1, Leer 2, 10-1, 10-2) für jedes Team

### 3. Get the API Key

After deployment, you need to retrieve the API key:

1. Go to AWS Console
2. Navigate to **API Gateway** > **API Keys**
3. Find the key named **handball-app-key**
4. Click on it and click **Show** to reveal the API key value
5. Copy the API key value (it looks like: `a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6`)

### 4. Frontend konfigurieren

Öffnen Sie `speech_to_email_app/lib/services/handball_api_service.dart` und ersetzen Sie die Platzhalter:

```dart
static const String _baseUrl = 'https://YOUR_API_GATEWAY_URL/prod/handball';
static const String _apiKey = 'YOUR_API_KEY_HERE';
```

Ersetzen Sie:
- `YOUR_API_GATEWAY_URL` mit der URL aus dem CDK Output
- `YOUR_API_KEY_HERE` mit dem API Key aus der AWS Console

**Wichtig**: Der API Key wird in die Flutter-App eingebaut. Das ist für Phase 1 akzeptabel, aber für Production sollten Sie später auf Cognito umsteigen.

## API Security

The API is protected with:

### API Key Authentication
- All handball endpoints require an API key
- Include the key in the `x-api-key` header
- The key is managed in AWS API Gateway

### Rate Limiting
- **Rate Limit**: 10 requests per second
- **Burst Limit**: 20 concurrent requests
- **Monthly Quota**: 10,000 requests per month

### Throttling
- API Gateway level: 50 requests/second, 100 burst

**Security Note**: The API key is embedded in the Flutter app. This provides basic protection but is not suitable for highly sensitive data. For production, consider implementing AWS Cognito for user authentication.

## API Endpunkte

### Organisationen

- `GET /handball/organizations` - Alle Organisationen abrufen
- `POST /handball/organizations` - Neue Organisation erstellen
- `GET /handball/organizations/{id}` - Organisation abrufen
- `DELETE /handball/organizations/{id}` - Organisation löschen

### Teams

- `GET /handball/teams` - Alle Teams abrufen
- `GET /handball/teams?organizationId={id}` - Teams einer Organisation abrufen
- `POST /handball/teams` - Neues Team erstellen
- `GET /handball/teams/{id}` - Team abrufen
- `PUT /handball/teams/{id}` - Team aktualisieren
- `DELETE /handball/teams/{id}` - Team löschen

### Spielzüge

- `GET /handball/spielzuege` - Alle Spielzüge abrufen
- `GET /handball/spielzuege?teamId={id}` - Spielzüge eines Teams abrufen
- `POST /handball/spielzuege` - Neuen Spielzug erstellen
- `GET /handball/spielzuege/{id}` - Spielzug abrufen
- `PUT /handball/spielzuege/{id}` - Spielzug aktualisieren
- `DELETE /handball/spielzuege/{id}` - Spielzug löschen

## Beispiel-Requests

**Note**: All requests require the `x-api-key` header.

### Organisation erstellen

```bash
curl -X POST https://YOUR_API_URL/prod/handball/organizations \
  -H "Content-Type: application/json" \
  -H "x-api-key: YOUR_API_KEY" \
  -d '{"name": "Neue Organisation"}'
```

### Team erstellen

```bash
curl -X POST https://YOUR_API_URL/prod/handball/teams \
  -H "Content-Type: application/json" \
  -H "x-api-key: YOUR_API_KEY" \
  -d '{
    "name": "Männer III",
    "coach": "Max Mustermann",
    "players": ["Spieler 1", "Spieler 2"],
    "organizationId": "hcVflHeppenheim"
  }'
```

### Spielzug erstellen

```bash
curl -X POST https://YOUR_API_URL/prod/handball/spielzuege \
  -H "Content-Type: application/json" \
  -H "x-api-key: YOUR_API_KEY" \
  -d '{
    "name": "Neuer Spielzug",
    "teamId": "maennerI",
    "description": "Beschreibung des Spielzugs",
    "attackingPlayers": [],
    "defendingPlayers": [],
    "actions": []
  }'
```

### Team aktualisieren

```bash
curl -X PUT https://YOUR_API_URL/prod/handball/teams/maennerI \
  -H "Content-Type: application/json" \
  -H "x-api-key: YOUR_API_KEY" \
  -d '{
    "coach": "Neuer Trainer",
    "players": ["Spieler 1", "Spieler 2", "Spieler 3"]
  }'
```

## DynamoDB Datenstruktur

### Organisationen
```
PK: ORG
SK: ORG#{organizationId}
id: string
name: string
```

### Teams
```
PK: TEAM
SK: TEAM#{teamId}
GSI1PK: ORG#{organizationId}
GSI1SK: TEAM#{teamId}
id: string
name: string
coach: string
players: string[]
organizationId: string
```

### Spielzüge
```
PK: SPIELZUG
SK: SPIELZUG#{spielzugId}
GSI1PK: TEAM#{teamId}
GSI1SK: SPIELZUG#{spielzugId}
id: string
name: string
teamId: string
description: string
attackingPlayers: object[]
defendingPlayers: object[]
actions: object[]
```

## Frontend Integration

Das Frontend kann die API über den `HandballApiService` verwenden:

```dart
final apiService = HandballApiService();

// Teams laden
final teams = await apiService.getTeams(organizationId: 'hcVflHeppenheim');

// Spielzüge für ein Team laden
final spielzuege = await apiService.getSpielzuege(teamId: 'maennerI');

// Neues Team erstellen
final newTeam = await apiService.createTeam(
  name: 'Männer III',
  coach: 'Max Mustermann',
  players: ['Spieler 1', 'Spieler 2'],
  organizationId: 'hcVflHeppenheim',
);

// Team aktualisieren
await apiService.updateTeam(
  teamId: 'maennerI',
  coach: 'Neuer Trainer',
);
```

## Nächste Schritte

1. **Frontend anpassen**: Ändern Sie `gameplay_service.dart`, um Daten vom Backend statt aus lokalen Defaults zu laden
2. **Admin-UI erstellen**: Erstellen Sie eine Admin-Oberfläche zum Verwalten von Teams und Spielzügen
3. **Authentifizierung hinzufügen**: Fügen Sie Cognito oder eine andere Auth-Lösung hinzu, um die API zu schützen
4. **Spielzug-Details**: Erweitern Sie die Spielzug-Daten um vollständige Spieler- und Aktionsinformationen

## Troubleshooting

### CORS-Fehler
Wenn Sie CORS-Fehler erhalten, stellen Sie sicher, dass die API Gateway CORS-Konfiguration korrekt ist.

### 403 Forbidden
**Mögliche Ursachen**:
1. **Fehlender API Key**: Stellen Sie sicher, dass der `x-api-key` Header gesetzt ist
2. **Falscher API Key**: Überprüfen Sie, ob der API Key korrekt ist
3. **Rate Limit überschritten**: Warten Sie, bis das Rate Limit zurückgesetzt wird
4. **IAM-Berechtigungen**: Überprüfen Sie, ob die Lambda-Funktion die richtigen IAM-Berechtigungen für DynamoDB hat

### 429 Too Many Requests
Sie haben das Rate Limit überschritten:
- 10 Requests pro Sekunde
- 20 Burst-Requests
- 10.000 Requests pro Monat

Warten Sie kurz und versuchen Sie es erneut.

### Daten nicht gefunden
Stellen Sie sicher, dass das Initialisierungsskript erfolgreich ausgeführt wurde.

### API Key im Flutter-Build
**Sicherheitshinweis**: Der API Key wird in die Flutter-App eingebaut und kann von technisch versierten Nutzern extrahiert werden. Dies ist für Phase 1 akzeptabel, aber für Production sollten Sie:
1. Auf AWS Cognito umsteigen (Phase 2)
2. Backend-Validierung für kritische Operationen implementieren
3. Sensible Daten serverseitig schützen
