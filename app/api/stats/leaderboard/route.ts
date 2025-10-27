import { NextRequest, NextResponse } from 'next/server';
import { getServerSupabase } from '@/lib/supabase';

// ============================================================================
// GET Handler - Fetch top users leaderboard by points
// ============================================================================
export async function GET(request: NextRequest) {
  try {
    console.log('[API /api/stats/leaderboard GET] Fetching top users by points');

    const supabase = getServerSupabase();

    // Fetch top 5 users by points, joining with users table for profile info
    const { data: leaderboard, error } = await supabase
      .from('user_levels')
      .select(`
        user_fid,
        points_total,
        level,
        users!inner(
          username,
          display_name,
          avatar_url
        )
      `)
      .order('points_total', { ascending: false })
      .limit(5);

    if (error) {
      console.error('[API /api/stats/leaderboard] Error fetching leaderboard:', error);
      return NextResponse.json(
        {
          success: false,
          error: 'Failed to fetch leaderboard',
          details: error.message
        },
        { status: 500 }
      );
    }

    // Format data for frontend
    const formattedLeaderboard = leaderboard?.map((entry: any, index: number) => ({
      rank: index + 1,
      fid: entry.user_fid,
      username: entry.users.username,
      displayName: entry.users.display_name,
      avatarUrl: entry.users.avatar_url,
      points: entry.points_total,
      level: entry.level,
    })) || [];

    return NextResponse.json(
      {
        success: true,
        data: formattedLeaderboard,
      },
      { status: 200 }
    );
  } catch (error: any) {
    console.error('[API /api/stats/leaderboard GET] Unexpected error:', error);
    return NextResponse.json(
      {
        success: false,
        error: 'Internal server error',
        details: error.message || 'Unknown error'
      },
      { status: 500 }
    );
  }
}
