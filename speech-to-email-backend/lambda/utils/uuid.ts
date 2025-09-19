/**
 * UUID utility that handles ES module imports
 */
export async function generateUuid(): Promise<string> {
  const { v4: uuidv4 } = await import('uuid');
  return uuidv4();
}