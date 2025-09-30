import { Context } from 'aws-lambda';
import { BedrockRuntimeClient, InvokeModelCommand } from '@aws-sdk/client-bedrock-runtime';
import { DynamoDBClient, UpdateItemCommand, GetItemCommand } from '@aws-sdk/client-dynamodb';
import { LambdaClient, InvokeCommand } from '@aws-sdk/client-lambda';

const bedrockClient = new BedrockRuntimeClient({ region: process.env.AWS_REGION });
const dynamoClient = new DynamoDBClient({ region: process.env.AWS_REGION });
const lambdaClient = new LambdaClient({ region: process.env.AWS_REGION });

interface ArticleEnhancementPayload {
    transcriptionText: string;
    recordId: string;
    timestamp: string;
    originalFileName: string;
    audioFileKey: string;
}

interface BedrockRequest {
    anthropic_version: string;
    max_tokens: number;
    temperature: number;
    top_p: number;
    messages: Array<{
        role: 'user';
        content: string;
    }>;
}

interface BedrockResponse {
    content: Array<{
        type: 'text';
        text: string;
    }>;
    usage: {
        input_tokens: number;
        output_tokens: number;
    };
}

interface EmailPayload {
    enhancedArticleText: string;
    originalTranscription: string;
    originalFileName: string;
    timestamp: string;
    recordId: string;
    audioFileKey: string;
}

const GERMAN_NEWSPAPER_PROMPT = `
Du bist ein erfahrener Journalist für eine lokale deutsche Zeitung. Bitte schreibe einen Blogbeitrag für die Vereinswebseite hcvfl.de und verwandle den folgenden transkribierten Text in einen gut strukturierten Artikel auf Deutsch.

Anforderungen:
- Erstelle eine aussagekräftige Schlagzeile
- Strukturiere den Artikel mit klaren Absätzen
- Verwende einen journalistischen Schreibstil
- Korrigiere eventuelle Grammatik- oder Rechtschreibfehler aus der Transkription
- Behalte alle wichtigen Informationen bei
- Füge bei Bedarf Kontext hinzu, um den Artikel verständlicher zu machen
- Verwende eine professionelle, aber zugängliche Sprache
- Formatiere den Artikel mit HTML-Tags für bessere Darstellung
- Alle Spieler des HCVFL sollen erwähnt werden (auch Torhüter, auch ohne Torerfolg).
- Beide Trainer nennen.
- Am Ende den offiziellen nuLiga-Spielbericht verlinken
- Schreibe im lockeren, freundlichen Blogstil für Eltern & Fans.
- Erzeuge außerdem Meta-Daten im SEO-Format (Title, Description, Keywords, URL-Slug, OG Title, OG Description).

Transkribierter Text:
{transcriptionText}

Bitte erstelle daraus einen vollständigen Zeitungsartikel auf Deutsch.
`;

const BEDROCK_CONFIG = {
    modelId: 'anthropic.claude-3-7-sonnet-20250219-v1',
    maxTokens: 4000,
    temperature: 0.2, // Lower temperature for more consistent, professional output
    topP: 0.9
};

export const handler = async (event: any, context: Context) => {
    console.log('Article Enhancement handler triggered:', JSON.stringify(event, null, 2));

    // Handle both direct invocation and async invocation formats
    let payload: ArticleEnhancementPayload;

    if (event.transcriptionText !== undefined) {
        // Direct payload format
        payload = event as ArticleEnhancementPayload;
    } else {
        console.error('Unexpected event format - no transcriptionText found');
        console.error('Full event:', JSON.stringify(event, null, 2));
        throw new Error('Invalid event format - missing transcriptionText');
    }

    const { transcriptionText, recordId, timestamp, originalFileName, audioFileKey } = payload;

    console.log('Processing article enhancement for record:', recordId);
    console.log('Transcription text length:', transcriptionText?.length || 0);

    const maxRetries = 3;
    let retryCount = 0;

    while (retryCount < maxRetries) {
        try {
            // Update status to enhancing_article
            const updateStatusCommand = new UpdateItemCommand({
                TableName: process.env.DYNAMODB_TABLE_NAME,
                Key: {
                    PK: { S: recordId },
                    SK: { S: 'RECORD' },
                },
                UpdateExpression: 'SET #status = :status, updatedAt = :updatedAt',
                ExpressionAttributeNames: {
                    '#status': 'status',
                },
                ExpressionAttributeValues: {
                    ':status': { S: 'enhancing_article' },
                    ':updatedAt': { S: new Date().toISOString() },
                },
            });

            await dynamoClient.send(updateStatusCommand);
            console.log(`Updated record status to enhancing_article for ${recordId}`);

            // Prepare the prompt with the transcription text
            const prompt = GERMAN_NEWSPAPER_PROMPT.replace('{transcriptionText}', transcriptionText);

            // Prepare Bedrock request
            const bedrockRequest: BedrockRequest = {
                anthropic_version: 'bedrock-2023-05-31',
                max_tokens: BEDROCK_CONFIG.maxTokens,
                temperature: BEDROCK_CONFIG.temperature,
                top_p: BEDROCK_CONFIG.topP,
                messages: [
                    {
                        role: 'user',
                        content: prompt,
                    }
                ]
            };

            console.log('Sending request to Bedrock with model:', BEDROCK_CONFIG.modelId);
            console.log('Request payload size:', JSON.stringify(bedrockRequest).length);

            // Call Bedrock
            const invokeCommand = new InvokeModelCommand({
                modelId: BEDROCK_CONFIG.modelId,
                contentType: 'application/json',
                body: JSON.stringify(bedrockRequest),
            });

            const bedrockResponse = await bedrockClient.send(invokeCommand);

            if (!bedrockResponse.body) {
                throw new Error('No response body from Bedrock');
            }

            // Parse the response
            const responseBody = JSON.parse(new TextDecoder().decode(bedrockResponse.body));
            console.log('Bedrock response:', JSON.stringify(responseBody, null, 2));

            const bedrockResult = responseBody as BedrockResponse;

            if (!bedrockResult.content || bedrockResult.content.length === 0) {
                throw new Error('No content in Bedrock response');
            }

            const enhancedArticleText = bedrockResult.content[0].text;
            console.log('Enhanced article text length:', enhancedArticleText.length);
            console.log('Token usage:', bedrockResult.usage);

            // Update DynamoDB record with enhanced article
            const updateCommand = new UpdateItemCommand({
                TableName: process.env.DYNAMODB_TABLE_NAME,
                Key: {
                    PK: { S: recordId },
                    SK: { S: 'RECORD' },
                },
                UpdateExpression: 'SET #status = :status, enhancedArticleText = :enhancedText, bedrockProcessedAt = :processedAt, updatedAt = :updatedAt, bedrockTokenUsage = :tokenUsage',
                ExpressionAttributeNames: {
                    '#status': 'status',
                },
                ExpressionAttributeValues: {
                    ':status': { S: 'article_enhanced' },
                    ':enhancedText': { S: enhancedArticleText },
                    ':processedAt': { S: new Date().toISOString() },
                    ':updatedAt': { S: new Date().toISOString() },
                    ':tokenUsage': { S: JSON.stringify(bedrockResult.usage) },
                },
            });

            await dynamoClient.send(updateCommand);
            console.log(`Updated record with enhanced article text for ${recordId}`);

            // Prepare email payload with enhanced content
            const emailPayload: EmailPayload = {
                enhancedArticleText,
                originalTranscription: transcriptionText,
                originalFileName,
                timestamp,
                recordId,
                audioFileKey,
            };

            console.log('Email payload being sent:', JSON.stringify({
                ...emailPayload,
                enhancedArticleText: `${enhancedArticleText.substring(0, 100)}...`,
                originalTranscription: `${transcriptionText.substring(0, 100)}...`
            }, null, 2));

            // Invoke email handler
            const invokeEmailCommand = new InvokeCommand({
                FunctionName: process.env.EMAIL_HANDLER_FUNCTION_NAME,
                InvocationType: 'RequestResponse', // Synchronous invocation
                Payload: JSON.stringify(emailPayload),
            });

            const invokeResult = await lambdaClient.send(invokeEmailCommand);
            console.log(`Invoked email handler for ${recordId}`, {
                statusCode: invokeResult.StatusCode,
                payload: invokeResult.Payload ? Buffer.from(invokeResult.Payload).toString() : 'No payload'
            });

            return {
                statusCode: 200,
                body: JSON.stringify({
                    message: 'Article enhancement completed successfully',
                    recordId,
                    tokenUsage: bedrockResult.usage
                }),
            };

        } catch (error) {
            retryCount++;
            console.error(`Article enhancement attempt ${retryCount} failed:`, error);

            // Check if this is a rate limiting error or temporary failure
            const isRetryableError = error instanceof Error && (
                error.message.includes('ThrottlingException') ||
                error.message.includes('ServiceUnavailableException') ||
                error.message.includes('InternalServerException') ||
                error.message.includes('TooManyRequestsException')
            );

            if (retryCount >= maxRetries || !isRetryableError) {
                console.log('Max retries reached or non-retryable error, falling back to original transcription');

                // Fall back to sending original transcription
                try {
                    // Update status to indicate fallback
                    const updateCommand = new UpdateItemCommand({
                        TableName: process.env.DYNAMODB_TABLE_NAME,
                        Key: {
                            PK: { S: recordId },
                            SK: { S: 'RECORD' },
                        },
                        UpdateExpression: 'SET #status = :status, errorMessage = :error, updatedAt = :updatedAt, retryCount = :retryCount',
                        ExpressionAttributeNames: {
                            '#status': 'status',
                        },
                        ExpressionAttributeValues: {
                            ':status': { S: 'article_enhanced' }, // Still proceed to email
                            ':error': { S: `Bedrock enhancement failed, using original transcription: ${error instanceof Error ? error.message : 'Unknown error'}` },
                            ':updatedAt': { S: new Date().toISOString() },
                            ':retryCount': { N: retryCount.toString() },
                        },
                    });

                    await dynamoClient.send(updateCommand);

                    // Send original transcription as fallback
                    const fallbackEmailPayload: EmailPayload = {
                        enhancedArticleText: transcriptionText, // Use original as fallback
                        originalTranscription: transcriptionText,
                        originalFileName,
                        timestamp,
                        recordId,
                        audioFileKey,
                    };

                    const invokeEmailCommand = new InvokeCommand({
                        FunctionName: process.env.EMAIL_HANDLER_FUNCTION_NAME,
                        InvocationType: 'RequestResponse',
                        Payload: JSON.stringify(fallbackEmailPayload),
                    });

                    const invokeResult = await lambdaClient.send(invokeEmailCommand);
                    console.log(`Invoked email handler with fallback for ${recordId}`, {
                        statusCode: invokeResult.StatusCode
                    });

                    return {
                        statusCode: 200,
                        body: JSON.stringify({
                            message: 'Article enhancement failed, sent original transcription',
                            recordId,
                            fallback: true,
                            error: error instanceof Error ? error.message : 'Unknown error'
                        }),
                    };

                } catch (fallbackError) {
                    console.error('Fallback email sending also failed:', fallbackError);

                    // Update status to failed
                    const updateFailedCommand = new UpdateItemCommand({
                        TableName: process.env.DYNAMODB_TABLE_NAME,
                        Key: {
                            PK: { S: recordId },
                            SK: { S: 'RECORD' },
                        },
                        UpdateExpression: 'SET #status = :status, errorMessage = :error, updatedAt = :updatedAt, retryCount = :retryCount',
                        ExpressionAttributeNames: {
                            '#status': 'status',
                        },
                        ExpressionAttributeValues: {
                            ':status': { S: 'failed' },
                            ':error': { S: `Both enhancement and fallback failed: ${fallbackError instanceof Error ? fallbackError.message : 'Unknown error'}` },
                            ':updatedAt': { S: new Date().toISOString() },
                            ':retryCount': { N: retryCount.toString() },
                        },
                    });

                    await dynamoClient.send(updateFailedCommand);
                    throw fallbackError;
                }
            }

            // Wait before retry (exponential backoff)
            const waitTime = Math.pow(2, retryCount) * 1000; // 2s, 4s, 8s
            console.log(`Waiting ${waitTime}ms before retry ${retryCount + 1}`);
            await new Promise(resolve => setTimeout(resolve, waitTime));
        }
    }

    // This should never be reached due to the throw in the catch block
    return {
        statusCode: 500,
        body: JSON.stringify({ message: 'Unexpected error in article enhancement handler' }),
    };
};