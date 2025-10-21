import { getServerSupabase } from './supabase';

/**
 * Generates a random 10-digit user code (fallback if DB trigger fails)
 */
function generateUserCode(): string {
  return String(Math.floor(Math.random() * 1e10)).padStart(10, '0');
}

/**
 * Ensures a user has a user_code assigned.
 * Relies primarily on the database trigger, but includes fallback logic
 * in case the trigger isn't set up or fails.
 *
 * @param fid - The user's Farcaster ID
 * @returns The user's 10-digit user code, or null if column doesn't exist
 */
export async function ensureUserCode(fid: number): Promise<string | null> {
  const supabase = getServerSupabase();

  // First, try to get existing user_code
  const { data, error } = await supabase
    .from('users')
    .select('user_code')
    .eq('fid', fid)
    .maybeSingle();

  // Handle missing column error (42703)
  if (error && error.code === '42703') {
    console.error('❌ DATABASE MIGRATION REQUIRED:');
    console.error('The user_code column does not exist in your Supabase database.');
    console.error('Please run supabase-user-code-complete.sql in Supabase SQL Editor');
    console.error('See: https://supabase.com/dashboard -> SQL Editor');
    return null; // Return null instead of crashing
  }

  // Handle other errors (except "no rows returned")
  if (error && error.code !== 'PGRST116') {
    console.error('Error fetching user_code:', error);
    return null; // Return null instead of crashing
  }

  // If user already has a code, return it
  if (data?.user_code) {
    console.log(`User ${fid} already has user_code: ${data.user_code}`);
    return data.user_code;
  }

  // Fallback: Generate and assign a code manually (retry up to 5 times)
  console.log(`User ${fid} has no user_code, generating one...`);

  for (let attempt = 0; attempt < 5; attempt++) {
    const candidate = generateUserCode();

    try {
      const { error: updateError } = await supabase
        .from('users')
        .update({ user_code: candidate })
        .eq('fid', fid);

      // Success - no error
      if (!updateError) {
        console.log(`✅ Successfully assigned user_code ${candidate} to user ${fid}`);
        return candidate;
      }

      // Handle missing column error
      if (updateError.code === '42703') {
        console.error('❌ Cannot assign user_code: column does not exist');
        return null;
      }

      // Check if error is due to unique constraint violation
      const errorMessage = String(updateError.message || '').toLowerCase();
      if (!errorMessage.includes('unique') && !errorMessage.includes('duplicate')) {
        // Different error, log and return null
        console.error('Unexpected error assigning user_code:', updateError);
        return null;
      }

      // Unique constraint violation, try again with new code
      console.log(
        `user_code ${candidate} already exists, retrying... (attempt ${attempt + 1}/5)`
      );
    } catch (err) {
      console.error('Error in ensureUserCode:', err);
      return null;
    }
  }

  // Failed after all retries
  console.error('Failed to assign unique user_code after 5 attempts');
  return null;
}

/**
 * Gets a user's code from the database
 * Returns null if user doesn't exist or doesn't have a code
 */
export async function getUserCode(fid: number): Promise<string | null> {
  const supabase = getServerSupabase();

  const { data, error } = await supabase
    .from('users')
    .select('user_code')
    .eq('fid', fid)
    .single();

  if (error || !data) {
    return null;
  }

  return data.user_code || null;
}
