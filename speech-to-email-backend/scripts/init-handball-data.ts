import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, PutCommand } from '@aws-sdk/lib-dynamodb';

const client = new DynamoDBClient({ region: 'eu-central-1' });
const docClient = DynamoDBDocumentClient.from(client);

const HANDBALL_TABLE_NAME = 'HandballData';

async function initializeData() {
  console.log('Initializing handball data...');

  // Create HC VfL Heppenheim organization
  const hcVflOrg = {
    PK: 'ORG',
    SK: 'ORG#hcVflHeppenheim',
    id: 'hcVflHeppenheim',
    name: 'HC VfL Heppenheim',
    createdAt: new Date().toISOString(),
  };

  await docClient.send(new PutCommand({
    TableName: HANDBALL_TABLE_NAME,
    Item: hcVflOrg,
  }));
  console.log('Created organization: HC VfL Heppenheim');

  // Create teams
  const teams = [
    {
      id: 'maennerI',
      name: 'Männer I',
      coach: 'Ginader, Andreas',
      players: [
        'Kreth, Tim',
        'Hoehling, Konstantin',
        'Brand, Yannick',
        'Zajonz, Lukas',
        'Werle, Rouven',
        'Ludwig, Nils',
        'Antes, Moritz',
        'Vetter, Marcel-Lukas',
        'Kaspar, Sebastian',
        'Cherkasov, Roman',
        'Bartke, Felix',
        'Lautenscheidt, Julian',
        'Müller, Jonas',
        'Demiryol, Aykut',
        'Kamer, Thomas',
        'Kaspar, Philip',
      ],
      organizationId: 'hcVflHeppenheim',
    },
    {
      id: 'maennerII',
      name: 'Männer II',
      coach: 'Schütz, Jonas',
      players: [
        'Haag, Christopher',
        'Guthier, Daniel',
        'Schäffauer, Marc',
        'Brand, Yannick',
        'Bangert, Dominik',
        'Scholz, Johannes',
        'Strauß, Timothy',
        'Schmitt, Philipp',
        'Meier, Simon',
        'Kaspar, Manuel',
        'Jung, Nico',
        'Hailer, Benjamin',
        'Hannken, Niels',
        'Saul, Frederik',
      ],
      organizationId: 'hcVflHeppenheim',
    },
    {
      id: 'damen',
      name: 'Damen',
      coach: 'Skandik, Jozef',
      players: [
        'Fellmann, Monja',
        'Kaiser, Johanna',
        'Marešová, Anne-Christin',
        'Wadowski, Tina',
        'Dickson, Rebecca',
        'Hamel, Mareike',
        'Maier, Michelle',
        'Wobbe, Meike',
        'Dickson, Jennifer',
        'Strauch, Sandra',
        'Merkel, Samantha',
        'Elsesser, Mia',
        'Meyer, Leonie',
      ],
      organizationId: 'hcVflHeppenheim',
    },
    {
      id: 'mC1',
      name: 'mC1',
      coach: 'Eberle, Ralf',
      players: [
        'Mayer, Tom',
        'Beisele, Martin',
        'Jacob, Felix',
        'Lennert, Jan Thore',
        'Blesing, Maximilian',
        'Schum, Philipp Andreas',
        'Wystemp, Jonas',
        'Scholz, Johann',
        'Marienfeld, Ricky-Loong',
        'Benker, Theo',
        'Hollenberg, Ben',
        'Fischer, Finn',
      ],
      organizationId: 'hcVflHeppenheim',
    },
    {
      id: 'mC2',
      name: 'mC2',
      coach: 'Koch, Johannes',
      players: [
        'Knebelspieß, Emil',
        'Kramer, Janik',
        'Müller, Jakob',
        'Mitsch, Julian',
        'Kreis, Christopher',
        'Fink, Bjarne',
        'Rüthers, Peer',
        'Schober, Leif',
        'Koch, Laurens',
        'Linnenkohl, Tim',
      ],
      organizationId: 'hcVflHeppenheim',
    },
  ];

  for (const team of teams) {
    await docClient.send(new PutCommand({
      TableName: HANDBALL_TABLE_NAME,
      Item: {
        PK: 'TEAM',
        SK: `TEAM#${team.id}`,
        GSI1PK: `ORG#${team.organizationId}`,
        GSI1SK: `TEAM#${team.id}`,
        ...team,
        createdAt: new Date().toISOString(),
      },
    }));
    console.log(`Created team: ${team.name}`);
  }

  // Create independent Spielzüge with complete play data
  const spielzuege = [
    {
      id: 'leer_1',
      name: 'Leer 1',
      description: 'Kreuztausch über links mit Durchstoß',
      defensiveFormation: 'sixZero',
      attackingPlayers: [
        { id: 'a1', name: 'LW', position: 'leftWing', x: 0.1, y: 0.35 },
        { id: 'a2', name: 'LR', position: 'leftBack', x: 0.25, y: 0.45 },
        { id: 'a3', name: 'RM', position: 'centerBack', x: 0.5, y: 0.5 },
        { id: 'a4', name: 'RR', position: 'rightBack', x: 0.75, y: 0.45 },
        { id: 'a5', name: 'RW', position: 'rightWing', x: 0.9, y: 0.35 },
        { id: 'a6', name: 'KM', position: 'pivot', x: 0.5, y: 0.2 },
      ],
      defendingPlayers: [
        { id: 'd1', name: 'D1', position: 'defLeftWing', x: 0.15, y: 0.25 },
        { id: 'd2', name: 'D2', position: 'defLeftBack', x: 0.3, y: 0.28 },
        { id: 'd3', name: 'D3', position: 'defCenterLeft', x: 0.45, y: 0.3 },
        { id: 'd4', name: 'D4', position: 'defCenterRight', x: 0.55, y: 0.3 },
        { id: 'd5', name: 'D5', position: 'defRightBack', x: 0.7, y: 0.28 },
        { id: 'd6', name: 'D6', position: 'defRightWing', x: 0.85, y: 0.25 },
      ],
      actions: [
        { id: 'act1', type: 'pass', playerId: 'a2', targetPlayerId: 'a3', sequenceNumber: 1, description: 'Pass von LR zu RM' },
        { id: 'act2', type: 'pass', playerId: 'a3', targetPlayerId: 'a2', sequenceNumber: 2, description: 'Pass zurück von RM zu LR' },
        { id: 'act3', type: 'move', playerId: 'a3', targetX: 0.75, targetY: 0.48, sequenceNumber: 3, description: 'RM läuft nach halb rechts' },
        { id: 'act4', type: 'move', playerId: 'a4', targetX: 0.5, targetY: 0.5, sequenceNumber: 4, description: 'RR läuft zur Mitte (Kreuztausch)' },
        { id: 'act5', type: 'pass', playerId: 'a2', targetPlayerId: 'a4', sequenceNumber: 5, description: 'Pass von LR zum neuen RM' },
        { id: 'act6', type: 'move', playerId: 'a4', targetX: 0.5, targetY: 0.35, sequenceNumber: 6, description: 'Neuer RM durchstößt nach vorne' },
        { id: 'act7', type: 'shoot', playerId: 'a4', sequenceNumber: 7, description: 'Wurf aufs Tor' },
      ],
    },
    {
      id: 'leer_2',
      name: 'Leer 2',
      description: 'Kreuztausch über rechts mit Durchstoß',
      defensiveFormation: 'sixZero',
      attackingPlayers: [
        { id: 'a1', name: 'LW', position: 'leftWing', x: 0.1, y: 0.35 },
        { id: 'a2', name: 'LR', position: 'leftBack', x: 0.25, y: 0.45 },
        { id: 'a3', name: 'RM', position: 'centerBack', x: 0.5, y: 0.5 },
        { id: 'a4', name: 'RR', position: 'rightBack', x: 0.75, y: 0.45 },
        { id: 'a5', name: 'RW', position: 'rightWing', x: 0.9, y: 0.35 },
        { id: 'a6', name: 'KM', position: 'pivot', x: 0.5, y: 0.2 },
      ],
      defendingPlayers: [
        { id: 'd1', name: 'D1', position: 'defLeftWing', x: 0.15, y: 0.25 },
        { id: 'd2', name: 'D2', position: 'defLeftBack', x: 0.3, y: 0.28 },
        { id: 'd3', name: 'D3', position: 'defCenterLeft', x: 0.45, y: 0.3 },
        { id: 'd4', name: 'D4', position: 'defCenterRight', x: 0.55, y: 0.3 },
        { id: 'd5', name: 'D5', position: 'defRightBack', x: 0.7, y: 0.28 },
        { id: 'd6', name: 'D6', position: 'defRightWing', x: 0.85, y: 0.25 },
      ],
      actions: [
        { id: 'act1', type: 'pass', playerId: 'a4', targetPlayerId: 'a3', sequenceNumber: 1, description: 'Pass von RR zu RM' },
        { id: 'act2', type: 'pass', playerId: 'a3', targetPlayerId: 'a4', sequenceNumber: 2, description: 'Pass zurück von RM zu RR' },
        { id: 'act3', type: 'move', playerId: 'a3', targetX: 0.25, targetY: 0.48, sequenceNumber: 3, description: 'RM läuft nach halb links' },
        { id: 'act4', type: 'move', playerId: 'a2', targetX: 0.5, targetY: 0.5, sequenceNumber: 4, description: 'LR läuft zur Mitte (Kreuztausch)' },
        { id: 'act5', type: 'pass', playerId: 'a4', targetPlayerId: 'a2', sequenceNumber: 5, description: 'Pass von RR zum neuen RM' },
        { id: 'act6', type: 'move', playerId: 'a2', targetX: 0.5, targetY: 0.35, sequenceNumber: 6, description: 'Neuer RM durchstößt nach vorne' },
        { id: 'act7', type: 'shoot', playerId: 'a2', sequenceNumber: 7, description: 'Wurf aufs Tor' },
      ],
    },
    {
      id: '10_1',
      name: '10-1',
      description: 'Spielzug über links mit Kreissperre',
      defensiveFormation: 'sixZero',
      attackingPlayers: [
        { id: 'a1', name: 'LW', position: 'leftWing', x: 0.1, y: 0.35 },
        { id: 'a2', name: 'LR', position: 'leftBack', x: 0.25, y: 0.45 },
        { id: 'a3', name: 'RM', position: 'centerBack', x: 0.5, y: 0.5 },
        { id: 'a4', name: 'RR', position: 'rightBack', x: 0.75, y: 0.45 },
        { id: 'a5', name: 'RW', position: 'rightWing', x: 0.9, y: 0.35 },
        { id: 'a6', name: 'KM', position: 'pivot', x: 0.5, y: 0.2 },
      ],
      defendingPlayers: [
        { id: 'd1', name: 'D1', position: 'defLeftWing', x: 0.15, y: 0.25 },
        { id: 'd2', name: 'D2', position: 'defLeftBack', x: 0.3, y: 0.28 },
        { id: 'd3', name: 'D3', position: 'defCenterLeft', x: 0.45, y: 0.3 },
        { id: 'd4', name: 'D4', position: 'defCenterRight', x: 0.55, y: 0.3 },
        { id: 'd5', name: 'D5', position: 'defRightBack', x: 0.7, y: 0.28 },
        { id: 'd6', name: 'D6', position: 'defRightWing', x: 0.85, y: 0.25 },
      ],
      actions: [
        { id: 'act1', type: 'pass', playerId: 'a5', targetPlayerId: 'a4', sequenceNumber: 1, description: 'Pass von RW zu RR' },
        { id: 'act2', type: 'pass', playerId: 'a4', targetPlayerId: 'a3', sequenceNumber: 2, description: 'Pass von RR zu RM' },
        { id: 'act3', type: 'pass', playerId: 'a3', targetPlayerId: 'a2', sequenceNumber: 3, description: 'Pass von RM zu LR' },
        { id: 'act4', type: 'pass', playerId: 'a2', targetPlayerId: 'a1', sequenceNumber: 4, description: 'Pass von LR zu LW' },
        { id: 'act5', type: 'pass', playerId: 'a1', targetPlayerId: 'a2', sequenceNumber: 5, description: 'Pass von LW zurück zu LR' },
        { id: 'act6', type: 'pass', playerId: 'a2', targetPlayerId: 'a3', sequenceNumber: 6, description: 'Pass von LR zu RM' },
        { id: 'act7', type: 'screen', playerId: 'a6', targetX: 0.35, targetY: 0.28, sequenceNumber: 7, description: 'KM stellt Sperre für LR' },
        { id: 'act8', type: 'pass', playerId: 'a3', targetPlayerId: 'a2', sequenceNumber: 8, description: 'Pass von RM zurück zu LR' },
        { id: 'act9', type: 'move', playerId: 'a2', targetX: 0.3, targetY: 0.25, sequenceNumber: 9, description: 'LR nutzt Sperre und stößt durch' },
        { id: 'act10', type: 'shoot', playerId: 'a2', sequenceNumber: 10, description: 'Wurf aufs Tor' },
      ],
    },
    {
      id: '10_2',
      name: '10-2',
      description: 'Spielzug über rechts mit Kreissperre',
      defensiveFormation: 'sixZero',
      attackingPlayers: [
        { id: 'a1', name: 'LW', position: 'leftWing', x: 0.1, y: 0.35 },
        { id: 'a2', name: 'LR', position: 'leftBack', x: 0.25, y: 0.45 },
        { id: 'a3', name: 'RM', position: 'centerBack', x: 0.5, y: 0.5 },
        { id: 'a4', name: 'RR', position: 'rightBack', x: 0.75, y: 0.45 },
        { id: 'a5', name: 'RW', position: 'rightWing', x: 0.9, y: 0.35 },
        { id: 'a6', name: 'KM', position: 'pivot', x: 0.5, y: 0.2 },
      ],
      defendingPlayers: [
        { id: 'd1', name: 'D1', position: 'defLeftWing', x: 0.15, y: 0.25 },
        { id: 'd2', name: 'D2', position: 'defLeftBack', x: 0.3, y: 0.28 },
        { id: 'd3', name: 'D3', position: 'defCenterLeft', x: 0.45, y: 0.3 },
        { id: 'd4', name: 'D4', position: 'defCenterRight', x: 0.55, y: 0.3 },
        { id: 'd5', name: 'D5', position: 'defRightBack', x: 0.7, y: 0.28 },
        { id: 'd6', name: 'D6', position: 'defRightWing', x: 0.85, y: 0.25 },
      ],
      actions: [
        { id: 'act1', type: 'pass', playerId: 'a1', targetPlayerId: 'a2', sequenceNumber: 1, description: 'Pass von LW zu LR' },
        { id: 'act2', type: 'pass', playerId: 'a2', targetPlayerId: 'a3', sequenceNumber: 2, description: 'Pass von LR zu RM' },
        { id: 'act3', type: 'pass', playerId: 'a3', targetPlayerId: 'a4', sequenceNumber: 3, description: 'Pass von RM zu RR' },
        { id: 'act4', type: 'pass', playerId: 'a4', targetPlayerId: 'a5', sequenceNumber: 4, description: 'Pass von RR zu RW' },
        { id: 'act5', type: 'pass', playerId: 'a5', targetPlayerId: 'a4', sequenceNumber: 5, description: 'Pass von RW zurück zu RR' },
        { id: 'act6', type: 'pass', playerId: 'a4', targetPlayerId: 'a3', sequenceNumber: 6, description: 'Pass von RR zu RM' },
        { id: 'act7', type: 'screen', playerId: 'a6', targetX: 0.65, targetY: 0.28, sequenceNumber: 7, description: 'KM stellt Sperre für RR' },
        { id: 'act8', type: 'pass', playerId: 'a3', targetPlayerId: 'a4', sequenceNumber: 8, description: 'Pass von RM zurück zu RR' },
        { id: 'act9', type: 'move', playerId: 'a4', targetX: 0.7, targetY: 0.25, sequenceNumber: 9, description: 'RR nutzt Sperre und stößt durch' },
        { id: 'act10', type: 'shoot', playerId: 'a4', sequenceNumber: 10, description: 'Wurf aufs Tor' },
      ],
    },
  ];
  
  for (const spielzug of spielzuege) {
    await docClient.send(new PutCommand({
      TableName: HANDBALL_TABLE_NAME,
      Item: {
        PK: 'SPIELZUG',
        SK: `SPIELZUG#${spielzug.id}`,
        id: spielzug.id,
        name: spielzug.name,
        description: spielzug.description,
        createdAt: new Date().toISOString(),
      },
    }));
    console.log(`Created Spielzug: ${spielzug.name}`);
  }

  // Create Team-Spielzug relations (assign all spielzüge to all teams initially)
  for (const team of teams) {
    for (const spielzug of spielzuege) {
      await docClient.send(new PutCommand({
        TableName: HANDBALL_TABLE_NAME,
        Item: {
          PK: `TEAM#${team.id}`,
          SK: `SPIELZUG#${spielzug.id}`,
          GSI1PK: `SPIELZUG#${spielzug.id}`,
          GSI1SK: `TEAM#${team.id}`,
          teamId: team.id,
          spielzugId: spielzug.id,
          createdAt: new Date().toISOString(),
        },
      }));
      console.log(`Assigned Spielzug ${spielzug.name} to ${team.name}`);
    }
  }

  console.log('Handball data initialization complete!');
}

initializeData().catch(console.error);
