import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, GetCommand, PutCommand, QueryCommand, DeleteCommand, BatchWriteCommand } from '@aws-sdk/lib-dynamodb';
import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);

const HANDBALL_TABLE_NAME = process.env.HANDBALL_TABLE_NAME || '';

interface Team {
  id: string;
  name: string;
  coach: string;
  players: string[];
  organizationId: string;
}

interface Spielzug {
  id: string;
  name: string;
  description?: string;
  attackingPlayers?: any[];
  defendingPlayers?: any[];
  actions?: any[];
}

interface Organization {
  id: string;
  name: string;
}

export const handler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  console.log('Event:', JSON.stringify(event, null, 2));

  const headers = {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
    'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS',
  };

  try {
    const path = event.path;
    const method = event.httpMethod;
    const pathParts = path.split('/').filter(p => p);

    // OPTIONS request for CORS
    if (method === 'OPTIONS') {
      return {
        statusCode: 200,
        headers,
        body: '',
      };
    }

    // Route: /handball/organizations
    if (pathParts[1] === 'organizations') {
      if (method === 'GET' && pathParts.length === 2) {
        return await getOrganizations(headers);
      }
      if (method === 'POST' && pathParts.length === 2) {
        return await createOrganization(event, headers);
      }
      if (method === 'GET' && pathParts.length === 3) {
        return await getOrganization(pathParts[2], headers);
      }
      if (method === 'DELETE' && pathParts.length === 3) {
        return await deleteOrganization(pathParts[2], headers);
      }
    }

    // Route: /handball/teams
    if (pathParts[1] === 'teams') {
      if (method === 'GET' && pathParts.length === 2) {
        const organizationId = event.queryStringParameters?.organizationId;
        return await getTeams(organizationId, headers);
      }
      if (method === 'POST' && pathParts.length === 2) {
        return await createTeam(event, headers);
      }
      if (method === 'GET' && pathParts.length === 3) {
        return await getTeam(pathParts[2], headers);
      }
      if (method === 'PUT' && pathParts.length === 3) {
        return await updateTeam(pathParts[2], event, headers);
      }
      if (method === 'DELETE' && pathParts.length === 3) {
        return await deleteTeam(pathParts[2], headers);
      }
    }

    // Route: /handball/spielzuege
    if (pathParts[1] === 'spielzuege') {
      if (method === 'GET' && pathParts.length === 2) {
        const teamId = event.queryStringParameters?.teamId;
        return await getSpielzuege(teamId, headers);
      }
      if (method === 'POST' && pathParts.length === 2) {
        return await createSpielzug(event, headers);
      }
      if (method === 'GET' && pathParts.length === 3) {
        return await getSpielzug(pathParts[2], headers);
      }
      if (method === 'PUT' && pathParts.length === 3) {
        return await updateSpielzug(pathParts[2], event, headers);
      }
      if (method === 'DELETE' && pathParts.length === 3) {
        return await deleteSpielzug(pathParts[2], headers);
      }
    }

    // Route: /handball/teams/{teamId}/spielzuege - Assign/unassign spielzüge to teams
    if (pathParts[1] === 'teams' && pathParts[3] === 'spielzuege') {
      const teamId = pathParts[2];
      if (method === 'POST' && pathParts.length === 4) {
        return await assignSpielzugToTeam(teamId, event, headers);
      }
      if (method === 'DELETE' && pathParts.length === 5) {
        const spielzugId = pathParts[4];
        return await unassignSpielzugFromTeam(teamId, spielzugId, headers);
      }
    }

    return {
      statusCode: 404,
      headers,
      body: JSON.stringify({ error: 'Not found' }),
    };
  } catch (error) {
    console.error('Error:', error);
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({ error: 'Internal server error', message: (error as Error).message }),
    };
  }
};

// Organizations
async function getOrganizations(headers: any): Promise<APIGatewayProxyResult> {
  const result = await docClient.send(new QueryCommand({
    TableName: HANDBALL_TABLE_NAME,
    KeyConditionExpression: 'PK = :pk',
    ExpressionAttributeValues: {
      ':pk': 'ORG',
    },
  }));

  return {
    statusCode: 200,
    headers,
    body: JSON.stringify(result.Items || []),
  };
}

async function getOrganization(id: string, headers: any): Promise<APIGatewayProxyResult> {
  const result = await docClient.send(new GetCommand({
    TableName: HANDBALL_TABLE_NAME,
    Key: {
      PK: 'ORG',
      SK: `ORG#${id}`,
    },
  }));

  if (!result.Item) {
    return {
      statusCode: 404,
      headers,
      body: JSON.stringify({ error: 'Organization not found' }),
    };
  }

  return {
    statusCode: 200,
    headers,
    body: JSON.stringify(result.Item),
  };
}

async function createOrganization(event: APIGatewayProxyEvent, headers: any): Promise<APIGatewayProxyResult> {
  const body = JSON.parse(event.body || '{}');
  const organization: Organization = {
    id: body.id || `org_${Date.now()}`,
    name: body.name,
  };

  await docClient.send(new PutCommand({
    TableName: HANDBALL_TABLE_NAME,
    Item: {
      PK: 'ORG',
      SK: `ORG#${organization.id}`,
      ...organization,
      createdAt: new Date().toISOString(),
    },
  }));

  return {
    statusCode: 201,
    headers,
    body: JSON.stringify(organization),
  };
}

async function deleteOrganization(id: string, headers: any): Promise<APIGatewayProxyResult> {
  await docClient.send(new DeleteCommand({
    TableName: HANDBALL_TABLE_NAME,
    Key: {
      PK: 'ORG',
      SK: `ORG#${id}`,
    },
  }));

  return {
    statusCode: 204,
    headers,
    body: '',
  };
}

// Teams
async function getTeams(organizationId: string | undefined, headers: any): Promise<APIGatewayProxyResult> {
  if (organizationId) {
    const result = await docClient.send(new QueryCommand({
      TableName: HANDBALL_TABLE_NAME,
      IndexName: 'GSI1',
      KeyConditionExpression: 'GSI1PK = :pk',
      ExpressionAttributeValues: {
        ':pk': `ORG#${organizationId}`,
      },
    }));

    return {
      statusCode: 200,
      headers,
      body: JSON.stringify(result.Items || []),
    };
  }

  const result = await docClient.send(new QueryCommand({
    TableName: HANDBALL_TABLE_NAME,
    KeyConditionExpression: 'PK = :pk',
    ExpressionAttributeValues: {
      ':pk': 'TEAM',
    },
  }));

  return {
    statusCode: 200,
    headers,
    body: JSON.stringify(result.Items || []),
  };
}

async function getTeam(id: string, headers: any): Promise<APIGatewayProxyResult> {
  const result = await docClient.send(new GetCommand({
    TableName: HANDBALL_TABLE_NAME,
    Key: {
      PK: 'TEAM',
      SK: `TEAM#${id}`,
    },
  }));

  if (!result.Item) {
    return {
      statusCode: 404,
      headers,
      body: JSON.stringify({ error: 'Team not found' }),
    };
  }

  return {
    statusCode: 200,
    headers,
    body: JSON.stringify(result.Item),
  };
}

async function createTeam(event: APIGatewayProxyEvent, headers: any): Promise<APIGatewayProxyResult> {
  const body = JSON.parse(event.body || '{}');
  const team: Team = {
    id: body.id || `team_${Date.now()}`,
    name: body.name,
    coach: body.coach,
    players: body.players || [],
    organizationId: body.organizationId,
  };

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

  return {
    statusCode: 201,
    headers,
    body: JSON.stringify(team),
  };
}

async function updateTeam(id: string, event: APIGatewayProxyEvent, headers: any): Promise<APIGatewayProxyResult> {
  const body = JSON.parse(event.body || '{}');
  
  const existingTeam = await docClient.send(new GetCommand({
    TableName: HANDBALL_TABLE_NAME,
    Key: {
      PK: 'TEAM',
      SK: `TEAM#${id}`,
    },
  }));

  if (!existingTeam.Item) {
    return {
      statusCode: 404,
      headers,
      body: JSON.stringify({ error: 'Team not found' }),
    };
  }

  const updatedTeam = {
    ...existingTeam.Item,
    name: body.name ?? existingTeam.Item.name,
    coach: body.coach ?? existingTeam.Item.coach,
    players: body.players ?? existingTeam.Item.players,
    updatedAt: new Date().toISOString(),
  };

  await docClient.send(new PutCommand({
    TableName: HANDBALL_TABLE_NAME,
    Item: updatedTeam,
  }));

  return {
    statusCode: 200,
    headers,
    body: JSON.stringify(updatedTeam),
  };
}

async function deleteTeam(id: string, headers: any): Promise<APIGatewayProxyResult> {
  await docClient.send(new DeleteCommand({
    TableName: HANDBALL_TABLE_NAME,
    Key: {
      PK: 'TEAM',
      SK: `TEAM#${id}`,
    },
  }));

  return {
    statusCode: 204,
    headers,
    body: '',
  };
}

// Spielzüge
async function getSpielzuege(teamId: string | undefined, headers: any): Promise<APIGatewayProxyResult> {
  if (teamId) {
    // Get team-spielzug relations
    const relationsResult = await docClient.send(new QueryCommand({
      TableName: HANDBALL_TABLE_NAME,
      KeyConditionExpression: 'PK = :pk AND begins_with(SK, :sk)',
      ExpressionAttributeValues: {
        ':pk': `TEAM#${teamId}`,
        ':sk': 'SPIELZUG#',
      },
    }));

    const relations = relationsResult.Items || [];
    
    if (relations.length === 0) {
      return {
        statusCode: 200,
        headers,
        body: JSON.stringify([]),
      };
    }

    // Fetch actual spielzug details
    const spielzuege = await Promise.all(
      relations.map(async (relation) => {
        const result = await docClient.send(new GetCommand({
          TableName: HANDBALL_TABLE_NAME,
          Key: {
            PK: 'SPIELZUG',
            SK: `SPIELZUG#${relation.spielzugId}`,
          },
        }));
        return result.Item;
      })
    );

    return {
      statusCode: 200,
      headers,
      body: JSON.stringify(spielzuege.filter(s => s !== undefined)),
    };
  }

  // Get all spielzüge
  const result = await docClient.send(new QueryCommand({
    TableName: HANDBALL_TABLE_NAME,
    KeyConditionExpression: 'PK = :pk',
    ExpressionAttributeValues: {
      ':pk': 'SPIELZUG',
    },
  }));

  return {
    statusCode: 200,
    headers,
    body: JSON.stringify(result.Items || []),
  };
}

async function getSpielzug(id: string, headers: any): Promise<APIGatewayProxyResult> {
  const result = await docClient.send(new GetCommand({
    TableName: HANDBALL_TABLE_NAME,
    Key: {
      PK: 'SPIELZUG',
      SK: `SPIELZUG#${id}`,
    },
  }));

  if (!result.Item) {
    return {
      statusCode: 404,
      headers,
      body: JSON.stringify({ error: 'Spielzug not found' }),
    };
  }

  return {
    statusCode: 200,
    headers,
    body: JSON.stringify(result.Item),
  };
}

async function createSpielzug(event: APIGatewayProxyEvent, headers: any): Promise<APIGatewayProxyResult> {
  const body = JSON.parse(event.body || '{}');
  const spielzug: Spielzug = {
    id: body.id || `spielzug_${Date.now()}`,
    name: body.name,
    description: body.description,
    attackingPlayers: body.attackingPlayers || [],
    defendingPlayers: body.defendingPlayers || [],
    actions: body.actions || [],
  };

  // Create independent spielzug
  await docClient.send(new PutCommand({
    TableName: HANDBALL_TABLE_NAME,
    Item: {
      PK: 'SPIELZUG',
      SK: `SPIELZUG#${spielzug.id}`,
      ...spielzug,
      createdAt: new Date().toISOString(),
    },
  }));

  // Optionally assign to teams if teamIds provided
  if (body.teamIds && Array.isArray(body.teamIds)) {
    await Promise.all(
      body.teamIds.map((teamId: string) =>
        docClient.send(new PutCommand({
          TableName: HANDBALL_TABLE_NAME,
          Item: {
            PK: `TEAM#${teamId}`,
            SK: `SPIELZUG#${spielzug.id}`,
            GSI1PK: `SPIELZUG#${spielzug.id}`,
            GSI1SK: `TEAM#${teamId}`,
            teamId,
            spielzugId: spielzug.id,
            createdAt: new Date().toISOString(),
          },
        }))
      )
    );
  }

  return {
    statusCode: 201,
    headers,
    body: JSON.stringify(spielzug),
  };
}

async function updateSpielzug(id: string, event: APIGatewayProxyEvent, headers: any): Promise<APIGatewayProxyResult> {
  const body = JSON.parse(event.body || '{}');
  
  const existingSpielzug = await docClient.send(new GetCommand({
    TableName: HANDBALL_TABLE_NAME,
    Key: {
      PK: 'SPIELZUG',
      SK: `SPIELZUG#${id}`,
    },
  }));

  if (!existingSpielzug.Item) {
    return {
      statusCode: 404,
      headers,
      body: JSON.stringify({ error: 'Spielzug not found' }),
    };
  }

  const updatedSpielzug = {
    ...existingSpielzug.Item,
    name: body.name ?? existingSpielzug.Item.name,
    description: body.description ?? existingSpielzug.Item.description,
    attackingPlayers: body.attackingPlayers ?? existingSpielzug.Item.attackingPlayers,
    defendingPlayers: body.defendingPlayers ?? existingSpielzug.Item.defendingPlayers,
    actions: body.actions ?? existingSpielzug.Item.actions,
    updatedAt: new Date().toISOString(),
  };

  await docClient.send(new PutCommand({
    TableName: HANDBALL_TABLE_NAME,
    Item: updatedSpielzug,
  }));

  return {
    statusCode: 200,
    headers,
    body: JSON.stringify(updatedSpielzug),
  };
}

async function deleteSpielzug(id: string, headers: any): Promise<APIGatewayProxyResult> {
  // Delete the spielzug
  await docClient.send(new DeleteCommand({
    TableName: HANDBALL_TABLE_NAME,
    Key: {
      PK: 'SPIELZUG',
      SK: `SPIELZUG#${id}`,
    },
  }));

  // Delete all team-spielzug relations using GSI1
  const relationsResult = await docClient.send(new QueryCommand({
    TableName: HANDBALL_TABLE_NAME,
    IndexName: 'GSI1',
    KeyConditionExpression: 'GSI1PK = :pk',
    ExpressionAttributeValues: {
      ':pk': `SPIELZUG#${id}`,
    },
  }));

  const relations = relationsResult.Items || [];
  if (relations.length > 0) {
    const deleteRequests = relations.map(relation => ({
      DeleteRequest: {
        Key: {
          PK: relation.PK,
          SK: relation.SK,
        },
      },
    }));

    // Batch delete in chunks of 25 (DynamoDB limit)
    for (let i = 0; i < deleteRequests.length; i += 25) {
      const chunk = deleteRequests.slice(i, i + 25);
      await docClient.send(new BatchWriteCommand({
        RequestItems: {
          [HANDBALL_TABLE_NAME]: chunk,
        },
      }));
    }
  }

  return {
    statusCode: 204,
    headers,
    body: '',
  };
}

// Team-Spielzug Relations
async function assignSpielzugToTeam(teamId: string, event: APIGatewayProxyEvent, headers: any): Promise<APIGatewayProxyResult> {
  const body = JSON.parse(event.body || '{}');
  const spielzugId = body.spielzugId;

  if (!spielzugId) {
    return {
      statusCode: 400,
      headers,
      body: JSON.stringify({ error: 'spielzugId is required' }),
    };
  }

  // Verify team exists
  const teamResult = await docClient.send(new GetCommand({
    TableName: HANDBALL_TABLE_NAME,
    Key: {
      PK: 'TEAM',
      SK: `TEAM#${teamId}`,
    },
  }));

  if (!teamResult.Item) {
    return {
      statusCode: 404,
      headers,
      body: JSON.stringify({ error: 'Team not found' }),
    };
  }

  // Verify spielzug exists
  const spielzugResult = await docClient.send(new GetCommand({
    TableName: HANDBALL_TABLE_NAME,
    Key: {
      PK: 'SPIELZUG',
      SK: `SPIELZUG#${spielzugId}`,
    },
  }));

  if (!spielzugResult.Item) {
    return {
      statusCode: 404,
      headers,
      body: JSON.stringify({ error: 'Spielzug not found' }),
    };
  }

  // Create relation
  await docClient.send(new PutCommand({
    TableName: HANDBALL_TABLE_NAME,
    Item: {
      PK: `TEAM#${teamId}`,
      SK: `SPIELZUG#${spielzugId}`,
      GSI1PK: `SPIELZUG#${spielzugId}`,
      GSI1SK: `TEAM#${teamId}`,
      teamId,
      spielzugId,
      createdAt: new Date().toISOString(),
    },
  }));

  return {
    statusCode: 201,
    headers,
    body: JSON.stringify({ teamId, spielzugId, message: 'Spielzug assigned to team' }),
  };
}

async function unassignSpielzugFromTeam(teamId: string, spielzugId: string, headers: any): Promise<APIGatewayProxyResult> {
  await docClient.send(new DeleteCommand({
    TableName: HANDBALL_TABLE_NAME,
    Key: {
      PK: `TEAM#${teamId}`,
      SK: `SPIELZUG#${spielzugId}`,
    },
  }));

  return {
    statusCode: 204,
    headers,
    body: '',
  };
}
