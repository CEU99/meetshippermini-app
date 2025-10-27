import { NextRequest, NextResponse } from 'next/server';
import { getServerSupabase } from '@/lib/supabase';

// ============================================================================
// GET Handler - Global verified users insights (analytics)
// ============================================================================

export async function GET(request: NextRequest) {
  try {
    console.log('[API /api/stats/insights GET] Fetching global verified users insights');

    const supabase = getServerSupabase();

    // ========================================================================
    // 1. Verifications Over Time (Last 14 Days)
    // ========================================================================
    const now = new Date();
    const fourteenDaysAgo = new Date();
    fourteenDaysAgo.setDate(now.getDate() - 14);

    const { data: verifications, error: verificationsError } = await supabase
      .from('attestations')
      .select('created_at')
      .gte('created_at', fourteenDaysAgo.toISOString())
      .lte('created_at', now.toISOString())
      .order('created_at', { ascending: true });

    if (verificationsError) throw verificationsError;

    // Group by date
    const grouped: Record<string, number> = {};
    verifications?.forEach((r) => {
      const date = new Date(r.created_at).toISOString().split('T')[0];
      grouped[date] = (grouped[date] || 0) + 1;
    });

    // Fill missing dates with 0
    const verificationsOverTime = Array.from({ length: 14 }).map((_, i) => {
      const d = new Date(fourteenDaysAgo);
      d.setDate(fourteenDaysAgo.getDate() + i);
      const key = d.toISOString().split('T')[0];
      return { date: key, count: grouped[key] || 0 };
    });

    // ========================================================================
    // 2. Top Verified Users (by username)
    // ========================================================================
    const { data: users, error: usersError } = await supabase
      .from('attestations')
      .select('username')
      .neq('username', null);

    if (usersError) throw usersError;

    const counts: Record<string, number> = {};
    users?.forEach((r) => {
      const name = r.username;
      counts[name] = (counts[name] || 0) + 1;
    });

    const topVerifiedUsers = Object.entries(counts)
      .map(([username, count]) => ({ username, count }))
      .sort((a, b) => b.count - a.count)
      .slice(0, 5);

    // ========================================================================
    // 3. Return response
    // ========================================================================
    return NextResponse.json(
      {
        success: true,
        data: {
          verificationsOverTime,
          topVerifiedUsers,
        },
      },
      { status: 200 }
    );
  } catch (error: any) {
    console.error('[API /api/stats/insights GET] Error:', error);
    return NextResponse.json(
      {
        success: false,
        error: 'Internal server error',
        details: error.message,
      },
      { status: 500 }
    );
  }
}