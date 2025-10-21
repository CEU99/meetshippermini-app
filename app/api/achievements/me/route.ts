import { NextRequest, NextResponse } from 'next/server';
import { getSession } from '@/lib/auth';
import { getServerSupabase } from '@/lib/supabase';
import { ACHIEVEMENTS, getAchievement } from '@/lib/constants/achievements';

/**
 * GET /api/achievements/me
 * Get current user's earned achievements
 */
export async function GET(request: NextRequest) {
  try {
    const session = await getSession();
    if (!session) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const supabase = getServerSupabase();
    const userFid = session.fid;

    // Get all earned achievements for this user
    const { data: achievements, error: achievementsError } = await supabase
      .from('user_achievements')
      .select('code, points, awarded_at')
      .eq('user_fid', userFid)
      .order('awarded_at', { ascending: true });

    if (achievementsError) {
      console.error('[API] Error fetching achievements:', achievementsError);
      return NextResponse.json(
        { error: 'Failed to fetch achievements' },
        { status: 500 }
      );
    }

    // Enrich with achievement details
    const enrichedAchievements = (achievements || []).map((earned) => {
      const achievement = getAchievement(earned.code as any);
      return {
        code: earned.code,
        title: achievement?.title || earned.code,
        description: achievement?.description || '',
        points: earned.points,
        icon: achievement?.icon || '🏆',
        awarded_at: earned.awarded_at,
        wave: achievement?.wave || 0,
      };
    });

    return NextResponse.json({
      achievements: enrichedAchievements,
      total_earned: enrichedAchievements.length,
      total_available: Object.keys(ACHIEVEMENTS).length,
    });
  } catch (error: any) {
    console.error('[API] Error in achievements/me:', error);
    return NextResponse.json(
      { error: 'Internal server error', message: error?.message },
      { status: 500 }
    );
  }
}
