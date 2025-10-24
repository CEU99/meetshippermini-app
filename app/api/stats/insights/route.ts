import { NextRequest, NextResponse } from 'next/server';
import { getServerSupabase } from '@/lib/supabase';

// ============================================================================
// GET Handler - Fetch verified users insights (analytics) - USER-SCOPED
// ============================================================================

export async function GET(request: NextRequest) {
  try {
    console.log('[API /api/stats/insights GET] Fetching verified users insights');

    // Get user FID from query params
    const { searchParams } = new URL(request.url);
    const fid = searchParams.get('fid');

    if (!fid) {
      console.error('[API /api/stats/insights GET] Missing fid parameter');
      return NextResponse.json(
        {
          success: false,
          error: 'Missing fid parameter',
          details: 'User FID is required for fetching insights',
        },
        { status: 400 }
      );
    }

    const userFid = parseInt(fid, 10);
    if (isNaN(userFid)) {
      console.error('[API /api/stats/insights GET] Invalid fid parameter');
      return NextResponse.json(
        {
          success: false,
          error: 'Invalid fid parameter',
          details: 'FID must be a valid number',
        },
        { status: 400 }
      );
    }

    console.log('[API /api/stats/insights GET] Fetching insights for user FID:', userFid);

    const supabase = getServerSupabase();

    // ========================================================================
    // 1. Verifications Over Time (Last 14 Days) - FOR THIS USER ONLY
    // ========================================================================

    const fourteenDaysAgo = new Date();
    fourteenDaysAgo.setDate(fourteenDaysAgo.getDate() - 14);
    const fourteenDaysAgoISO = fourteenDaysAgo.toISOString();

    const { data: recentVerifications, error: timeError } = await supabase
      .from('attestations')
      .select('created_at')
      .eq('fid', userFid)
      .gte('created_at', fourteenDaysAgoISO)
      .order('created_at', { ascending: true });

    if (timeError) {
      console.error('[API /api/stats/insights GET] Error fetching time data:', timeError);
      return NextResponse.json(
        {
          success: false,
          error: 'Failed to fetch verifications over time',
          details: timeError.message,
        },
        { status: 500 }
      );
    }

    // Group by date
    const verificationsByDate: { [key: string]: number } = {};

    recentVerifications?.forEach((record) => {
      const date = new Date(record.created_at).toISOString().split('T')[0];
      verificationsByDate[date] = (verificationsByDate[date] || 0) + 1;
    });

    // Fill in missing dates with 0
    const verificationsOverTime: Array<{ date: string; count: number }> = [];
    for (let i = 13; i >= 0; i--) {
      const date = new Date();
      date.setDate(date.getDate() - i);
      const dateStr = date.toISOString().split('T')[0];
      verificationsOverTime.push({
        date: dateStr,
        count: verificationsByDate[dateStr] || 0,
      });
    }

    console.log('[API /api/stats/insights GET] Verifications over time:', verificationsOverTime.length, 'days');

    // ========================================================================
    // 2. Top Verified Users (Most Verifications) - FOR THIS USER ONLY
    // Note: This will show the same username multiple times if they have
    // multiple attestations, which is expected for per-user stats
    // ========================================================================

    const { data: allVerifications, error: usersError } = await supabase
      .from('attestations')
      .select('username')
      .eq('fid', userFid);

    if (usersError) {
      console.error('[API /api/stats/insights GET] Error fetching users data:', usersError);
      return NextResponse.json(
        {
          success: false,
          error: 'Failed to fetch top verified users',
          details: usersError.message,
        },
        { status: 500 }
      );
    }

    // Count verifications per user
    const userCounts: { [key: string]: number } = {};

    allVerifications?.forEach((record) => {
      const username = record.username;
      userCounts[username] = (userCounts[username] || 0) + 1;
    });

    // Sort and get top 5
    const topVerifiedUsers = Object.entries(userCounts)
      .map(([username, count]) => ({ username, count }))
      .sort((a, b) => b.count - a.count)
      .slice(0, 5);

    console.log('[API /api/stats/insights GET] Top verified users:', topVerifiedUsers.length);

    // ========================================================================
    // 3. Return Response
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
    console.error('[API /api/stats/insights GET] Unexpected error:', error);

    return NextResponse.json(
      {
        success: false,
        error: 'Internal server error',
        details: error.message || 'Unknown error',
      },
      { status: 500 }
    );
  }
}
