/**
 * Automatic Match Runner
 * Core algorithm for finding and creating automatic matches
 */

import { getServerSupabase } from '@/lib/supabase';
import {
  getMatchableUsers,
  findBestMatches,
  createMatchProposal,
  MATCHING_CONFIG,
  type MatchCandidate,
} from './matching-service';

export interface AutoMatchResult {
  runId: string;
  usersProcessed: number;
  matchesCreated: number;
  errors: string[];
  startedAt: Date;
  completedAt: Date;
  duration: number;
}

/**
 * Main automatic matching function
 * Runs the full matching algorithm for all eligible users
 */
export async function runAutomaticMatching(): Promise<AutoMatchResult> {
  const startedAt = new Date();
  const supabase = getServerSupabase();

  // Create auto_match_run record
  const { data: run, error: runError } = await supabase
    .from('auto_match_runs')
    .insert({
      started_at: startedAt.toISOString(),
      status: 'running',
    })
    .select('id')
    .single();

  if (runError || !run) {
    console.error('Failed to create auto_match_run record:', runError);
    throw new Error('Failed to start auto matching');
  }

  const runId = run.id;
  const errors: string[] = [];
  let usersProcessed = 0;
  let matchesCreated = 0;

  try {
    // 1. Get all matchable users
    console.log('[Auto-Match] Fetching matchable users...');
    const users = await getMatchableUsers();
    console.log(`[Auto-Match] Found ${users.length} matchable users`);

    if (users.length < 2) {
      console.log('[Auto-Match] Not enough users to match');
      await finishRun(runId, usersProcessed, matchesCreated, 'completed', null);
      return {
        runId,
        usersProcessed,
        matchesCreated,
        errors,
        startedAt,
        completedAt: new Date(),
        duration: Date.now() - startedAt.getTime(),
      };
    }

    // 2. For each user, find best matches
    for (const user of users) {
      try {
        console.log(`[Auto-Match] Processing user: ${user.username} (${user.fid})`);

        // Find best matches for this user
        const matches = await findBestMatches(user, users);

        console.log(`[Auto-Match] Found ${matches.length} potential matches for ${user.username}`);

        // Create proposals for top matches
        for (const match of matches) {
          try {
            const result = await createMatchProposal(match, 'system');

            if (result.success) {
              matchesCreated++;
              console.log(
                `[Auto-Match] ✓ Created match: ${match.userA.username} <-> ${match.userB.username} (score: ${match.overallScore})`
              );
            } else {
              console.log(`[Auto-Match] ✗ Skipped: ${result.error}`);
              errors.push(result.error || 'Unknown error');
            }
          } catch (error: any) {
            console.error('[Auto-Match] Error creating proposal:', error);
            errors.push(`Failed to create proposal: ${error.message}`);
          }
        }

        usersProcessed++;
      } catch (error: any) {
        console.error(`[Auto-Match] Error processing user ${user.username}:`, error);
        errors.push(`Error processing ${user.username}: ${error.message}`);
      }
    }

    // 3. Finish successfully
    await finishRun(runId, usersProcessed, matchesCreated, 'completed', null);

    const completedAt = new Date();
    const duration = completedAt.getTime() - startedAt.getTime();

    console.log(
      `[Auto-Match] Completed! Processed ${usersProcessed} users, created ${matchesCreated} matches in ${duration}ms`
    );

    return {
      runId,
      usersProcessed,
      matchesCreated,
      errors,
      startedAt,
      completedAt,
      duration,
    };
  } catch (error: any) {
    console.error('[Auto-Match] Fatal error:', error);
    errors.push(`Fatal error: ${error.message}`);

    await finishRun(runId, usersProcessed, matchesCreated, 'failed', error.message);

    throw error;
  }
}

/**
 * Update auto_match_run record with final results
 */
async function finishRun(
  runId: string,
  usersProcessed: number,
  matchesCreated: number,
  status: 'completed' | 'failed',
  errorMessage: string | null
): Promise<void> {
  const supabase = getServerSupabase();

  await supabase
    .from('auto_match_runs')
    .update({
      completed_at: new Date().toISOString(),
      users_processed: usersProcessed,
      matches_created: matchesCreated,
      status,
      error_message: errorMessage,
    })
    .eq('id', runId);
}

/**
 * Get recent auto-match runs
 */
export async function getRecentAutoMatchRuns(limit: number = 10): Promise<any[]> {
  const supabase = getServerSupabase();

  const { data, error } = await supabase
    .from('auto_match_runs')
    .select('*')
    .order('started_at', { ascending: false })
    .limit(limit);

  if (error) {
    console.error('Error fetching auto match runs:', error);
    return [];
  }

  return data || [];
}

/**
 * Check if auto-matching should run based on last run time
 */
export async function shouldRunAutoMatching(): Promise<boolean> {
  const supabase = getServerSupabase();

  const { data, error } = await supabase
    .from('auto_match_runs')
    .select('completed_at')
    .eq('status', 'completed')
    .order('completed_at', { ascending: false })
    .limit(1)
    .maybeSingle();

  if (error) {
    console.error('Error checking last run:', error);
    return true; // Run if we can't check
  }

  if (!data || !data.completed_at) {
    return true; // No previous run, should run
  }

  const lastRun = new Date(data.completed_at);
  const now = new Date();
  const hoursSinceLastRun = (now.getTime() - lastRun.getTime()) / (1000 * 60 * 60);

  return hoursSinceLastRun >= MATCHING_CONFIG.AUTO_MATCH_INTERVAL_HOURS;
}

/**
 * Cleanup expired cooldowns (maintenance task)
 */
export async function cleanupExpiredCooldowns(): Promise<number> {
  const supabase = getServerSupabase();

  const { data, error } = await supabase.rpc('cleanup_expired_cooldowns');

  if (error) {
    console.error('Error cleaning up cooldowns:', error);
    return 0;
  }

  return data || 0;
}
