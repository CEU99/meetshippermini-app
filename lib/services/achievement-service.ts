/**
 * Achievement Service
 *
 * Handles awarding achievements and checking criteria
 */

import { getServerSupabase } from '@/lib/supabase';
import { AchievementCode } from '@/lib/constants/achievements';

export interface AwardResult {
  awarded: boolean;
  already_exists: boolean;
  code?: string;
  points?: number;
  points_total?: number;
  level?: number;
  level_progress?: number;
}

/**
 * Award a single achievement to a user (idempotent)
 */
export async function awardAchievement(
  userFid: number,
  code: AchievementCode,
  points: number
): Promise<AwardResult> {
  const supabase = getServerSupabase();

  try {
    // Check if already awarded
    const { data: existing } = await supabase
      .from('user_achievements')
      .select('code')
      .eq('user_fid', userFid)
      .eq('code', code)
      .single();

    if (existing) {
      console.log(`[Achievement] ${code} already awarded to user ${userFid}`);
      return {
        awarded: false,
        already_exists: true,
      };
    }

    // Insert achievement
    const { error: insertError } = await supabase
      .from('user_achievements')
      .insert({
        user_fid: userFid,
        code,
        points,
      });

    if (insertError) {
      console.error('[Achievement] Error inserting achievement:', insertError);
      throw insertError;
    }

    // Initialize or update user_levels
    const { data: currentLevel } = await supabase
      .from('user_levels')
      .select('points_total')
      .eq('user_fid', userFid)
      .single();

    if (!currentLevel) {
      // Create new level record
      await supabase.from('user_levels').insert({
        user_fid: userFid,
        points_total: points,
      });
    } else {
      // Update existing record
      const newTotal = Math.min(currentLevel.points_total + points, 2000);
      await supabase
        .from('user_levels')
        .update({ points_total: newTotal })
        .eq('user_fid', userFid);
    }

    // Get updated level info
    const { data: updatedLevel } = await supabase
      .from('user_levels')
      .select('*')
      .eq('user_fid', userFid)
      .single();

    console.log(`[Achievement] ✅ Awarded ${code} (+${points}pts) to user ${userFid}`);

    return {
      awarded: true,
      already_exists: false,
      code,
      points,
      points_total: updatedLevel?.points_total || points,
      level: Math.min(Math.floor((updatedLevel?.points_total || points) / 100), 20),
      level_progress: (updatedLevel?.points_total || points) % 100,
    };
  } catch (error: any) {
    console.error('[Achievement] Error awarding achievement:', error);
    throw error;
  }
}

/**
 * Check profile achievements (bio and traits)
 */
export async function checkProfileAchievements(userFid: number): Promise<AwardResult[]> {
  const supabase = getServerSupabase();
  const results: AwardResult[] = [];

  try {
    // Get user profile
    const { data: user } = await supabase
      .from('users')
      .select('bio, traits')
      .eq('fid', userFid)
      .single();

    if (!user) return results;

    // Check bio achievement
    if (user.bio && user.bio.trim().length > 0) {
      const bioResult = await awardAchievement(userFid, 'bio_done', 50);
      if (bioResult.awarded) {
        results.push(bioResult);
      }
    }

    // Check traits achievement (need at least 5)
    if (user.traits && Array.isArray(user.traits) && user.traits.length >= 5) {
      const traitsResult = await awardAchievement(userFid, 'traits_done', 50);
      if (traitsResult.awarded) {
        results.push(traitsResult);
      }
    }

    return results;
  } catch (error: any) {
    console.error('[Achievement] Error checking profile achievements:', error);
    return results;
  }
}

/**
 * Check match request achievements
 */
export async function checkMatchRequestAchievements(userFid: number): Promise<AwardResult[]> {
  const supabase = getServerSupabase();
  const results: AwardResult[] = [];

  try {
    // Count unique recipients this user has sent matches to
    const { data: matches } = await supabase
      .from('matches')
      .select('user_a_fid, user_b_fid')
      .eq('created_by_fid', userFid);

    if (!matches) return results;

    // Calculate unique recipients
    const uniqueRecipients = new Set<number>();
    for (const match of matches) {
      const recipient = match.user_a_fid === userFid ? match.user_b_fid : match.user_a_fid;
      uniqueRecipients.add(recipient);
    }

    const count = uniqueRecipients.size;

    console.log(`[Achievement] User ${userFid} has sent matches to ${count} unique users`);

    // Check thresholds (check highest first to avoid multiple awards)
    if (count >= 30) {
      const result = await awardAchievement(userFid, 'sent_30', 100);
      if (result.awarded) results.push(result);
    }
    if (count >= 20) {
      const result = await awardAchievement(userFid, 'sent_20', 100);
      if (result.awarded) results.push(result);
    }
    if (count >= 10) {
      const result = await awardAchievement(userFid, 'sent_10', 100);
      if (result.awarded) results.push(result);
    }
    if (count >= 5) {
      const result = await awardAchievement(userFid, 'sent_5', 100);
      if (result.awarded) results.push(result);
    }

    return results;
  } catch (error: any) {
    console.error('[Achievement] Error checking match request achievements:', error);
    return results;
  }
}

/**
 * Check meeting achievements
 */
export async function checkMeetingAchievements(userFid: number): Promise<AwardResult[]> {
  const supabase = getServerSupabase();
  const results: AwardResult[] = [];

  try {
    // Count completed meetings for this user
    const { data: matches, error } = await supabase
      .from('matches')
      .select('id')
      .or(`user_a_fid.eq.${userFid},user_b_fid.eq.${userFid}`)
      .eq('status', 'completed');

    if (error) {
      console.error('[Achievement] Error fetching completed meetings:', error);
      return results;
    }

    const count = matches?.length || 0;

    console.log(`[Achievement] User ${userFid} has ${count} completed meetings`);

    // Check thresholds (check highest first)
    if (count >= 40) {
      const result = await awardAchievement(userFid, 'joined_40', 400);
      if (result.awarded) results.push(result);
    }
    if (count >= 10) {
      const result = await awardAchievement(userFid, 'joined_10', 400);
      if (result.awarded) results.push(result);
    }
    if (count >= 5) {
      const result = await awardAchievement(userFid, 'joined_5', 400);
      if (result.awarded) results.push(result);
    }
    if (count >= 1) {
      const result = await awardAchievement(userFid, 'joined_1', 400);
      if (result.awarded) results.push(result);
    }

    return results;
  } catch (error: any) {
    console.error('[Achievement] Error checking meeting achievements:', error);
    return results;
  }
}

/**
 * Check all achievements for a user
 * Useful for recalculation or initial setup
 */
export async function checkAllAchievements(userFid: number): Promise<{
  profile: AwardResult[];
  matches: AwardResult[];
  meetings: AwardResult[];
}> {
  const [profile, matches, meetings] = await Promise.all([
    checkProfileAchievements(userFid),
    checkMatchRequestAchievements(userFid),
    checkMeetingAchievements(userFid),
  ]);

  return { profile, matches, meetings };
}
