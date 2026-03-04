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

  // Create independent Spielzüge
  const spielzuege = [
    { id: 'leer_1', name: 'Leer 1', description: 'Leer 1 Spielzug' },
    { id: 'leer_2', name: 'Leer 2', description: 'Leer 2 Spielzug' },
    { id: '10_1', name: '10-1', description: '10-1 Spielzug' },
    { id: '10_2', name: '10-2', description: '10-2 Spielzug' },
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
