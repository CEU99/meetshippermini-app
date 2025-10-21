import { getServerSupabase } from './supabase';

/**
 * Generates a random 10-digit unique ID
 * Format: 1000000000 to 9999999999
 */
export function generateUniqueId(): string {
  // Generate a random number between 1000000000 and 9999999999 (10 digits)
  const min = 1000000000;
  const max = 9999999999;
  const randomNum = Math.floor(Math.random() * (max - min + 1)) + min;
  return randomNum.toString();
}

/**
 * Checks if a unique ID already exists in the database
 */
export async function isUniqueIdTaken(uniqueId: string): Promise<boolean> {
  const supabase = getServerSupabase();

  const { data, error } = await supabase
    .from('users')
    .select('unique_id')
    .eq('unique_id', uniqueId)
    .single();

  // If no data found, the ID is not taken
  // If error with code 'PGRST116' (no rows), ID is available
  return data !== null && !error;
}

/**
 * Generates a unique 10-digit ID that doesn't exist in the database
 * Retries up to 10 times to ensure uniqueness
 */
export async function generateUniqueUserId(): Promise<string> {
  const maxAttempts = 10;

  for (let attempt = 0; attempt < maxAttempts; attempt++) {
    const uniqueId = generateUniqueId();

    // Check if this ID already exists
    const isTaken = await isUniqueIdTaken(uniqueId);

    if (!isTaken) {
      return uniqueId;
    }

    // If taken, try again
    console.log(`Unique ID ${uniqueId} already exists, generating new one...`);
  }

  // If we couldn't generate a unique ID after max attempts, throw error
  throw new Error('Failed to generate unique user ID after maximum attempts');
}
