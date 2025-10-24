import { NextRequest, NextResponse } from 'next/server';
import { getServerSupabase } from '@/lib/supabase';

// ============================================================================
// GET Handler - Fetch growth analytics (weekly comparison) - USER-SCOPED
// ============================================================================

export async function GET(request: NextRequest) {
  try {
    console.log('[API /api/stats/growth GET] Fetching growth analytics');

    // Get user FID from query params
    const { searchParams } = new URL(request.url);
    const fid = searchParams.get('fid');

    if (!fid) {
      console.error('[API /api/stats/growth GET] Missing fid parameter');
      return NextResponse.json(
        {
          success: false,
          error: 'Missing fid parameter',
          details: 'User FID is required for fetching growth data',
        },
        { status: 400 }
      );
    }

    const userFid = parseInt(fid, 10);
    if (isNaN(userFid)) {
      console.error('[API /api/stats/growth GET] Invalid fid parameter');
      return NextResponse.json(
        {
          success: false,
          error: 'Invalid fid parameter',
          details: 'FID must be a valid number',
        },
        { status: 400 }
      );
    }

    console.log('[API /api/stats/growth GET] Fetching growth for user FID:', userFid);

    const supabase = getServerSupabase();

    // ========================================================================
    // 1. Get Daily Counts for Last 14 Days - FOR THIS USER ONLY
    // ========================================================================

    const fourteenDaysAgo = new Date();
    fourteenDaysAgo.setDate(fourteenDaysAgo.getDate() - 14);
    const fourteenDaysAgoISO = fourteenDaysAgo.toISOString();

    const { data: recentVerifications, error: fetchError } = await supabase
      .from('attestations')
      .select('created_at')
      .eq('fid', userFid)
      .gte('created_at', fourteenDaysAgoISO)
      .order('created_at', { ascending: true });

    if (fetchError) {
      console.error('[API /api/stats/growth GET] Error fetching data:', fetchError);
      return NextResponse.json(
        {
          success: false,
          error: 'Failed to fetch growth data',
          details: fetchError.message,
        },
        { status: 500 }
      );
    }

    // ========================================================================
    // 2. Group by Date
    // ========================================================================

    const verificationsByDate: { [key: string]: number } = {};

    recentVerifications?.forEach((record) => {
      const date = new Date(record.created_at).toISOString().split('T')[0];
      verificationsByDate[date] = (verificationsByDate[date] || 0) + 1;
    });

    // ========================================================================
    // 3. Build Daily Counts Array (Last 14 Days)
    // ========================================================================

    const dailyCounts: Array<{ date: string; count: number }> = [];
    for (let i = 13; i >= 0; i--) {
      const date = new Date();
      date.setDate(date.getDate() - i);
      const dateStr = date.toISOString().split('T')[0];
      dailyCounts.push({
        date: dateStr,
        count: verificationsByDate[dateStr] || 0,
      });
    }

    console.log('[API /api/stats/growth GET] Daily counts:', dailyCounts.length, 'days');

    // ========================================================================
    // 4. Calculate Weekly Totals
    // ========================================================================

    // Current Week (Last 7 days: indices 7-13)
    const currentWeekCounts = dailyCounts.slice(7, 14);
    const weeklyTotal = currentWeekCounts.reduce((sum, item) => sum + item.count, 0);

    // Previous Week (Days 0-6: indices 0-6)
    const previousWeekCounts = dailyCounts.slice(0, 7);
    const previousWeekTotal = previousWeekCounts.reduce((sum, item) => sum + item.count, 0);

    // Growth Rate Calculation
    let growthRate = 0;
    if (previousWeekTotal > 0) {
      growthRate = ((weeklyTotal - previousWeekTotal) / previousWeekTotal) * 100;
    } else if (weeklyTotal > 0) {
      growthRate = 100; // 100% growth if previous week was 0
    }

    console.log('[API /api/stats/growth GET] Current week:', weeklyTotal);
    console.log('[API /api/stats/growth GET] Previous week:', previousWeekTotal);
    console.log('[API /api/stats/growth GET] Growth rate:', growthRate.toFixed(1) + '%');

    // ========================================================================
    // 5. Return Response
    // ========================================================================

    return NextResponse.json(
      {
        success: true,
        data: {
          dailyCounts,
          weeklyTotal,
          previousWeekTotal,
          growthRate: Math.round(growthRate * 10) / 10, // Round to 1 decimal
          currentWeekCounts,
          previousWeekCounts,
        },
      },
      { status: 200 }
    );
  } catch (error: any) {
    console.error('[API /api/stats/growth GET] Unexpected error:', error);

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
