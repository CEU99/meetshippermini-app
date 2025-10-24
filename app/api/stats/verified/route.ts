import { NextRequest, NextResponse } from 'next/server';
import { getServerSupabase } from '@/lib/supabase';

// ============================================================================
// GET Handler - Fetch verified users statistics (USER-SCOPED)
// ============================================================================

export async function GET(request: NextRequest) {
  try {
    console.log('[API /api/stats/verified GET] Fetching verified users statistics');

    // Get user FID from query params
    const { searchParams } = new URL(request.url);
    const fid = searchParams.get('fid');

    if (!fid) {
      console.error('[API /api/stats/verified GET] Missing fid parameter');
      return NextResponse.json(
        {
          success: false,
          error: 'Missing fid parameter',
          details: 'User FID is required for fetching statistics',
        },
        { status: 400 }
      );
    }

    const userFid = parseInt(fid, 10);
    if (isNaN(userFid)) {
      console.error('[API /api/stats/verified GET] Invalid fid parameter');
      return NextResponse.json(
        {
          success: false,
          error: 'Invalid fid parameter',
          details: 'FID must be a valid number',
        },
        { status: 400 }
      );
    }

    console.log('[API /api/stats/verified GET] Fetching stats for user FID:', userFid);

    // Get Supabase server client
    const supabase = getServerSupabase();

    // Get total count of verified users FOR THIS USER ONLY
    const { count, error: countError } = await supabase
      .from('attestations')
      .select('*', { count: 'exact', head: true })
      .eq('fid', userFid);

    if (countError) {
      console.error('[API /api/stats/verified GET] Error counting verified users:', countError);
      return NextResponse.json(
        {
          success: false,
          error: 'Failed to count verified users',
          details: countError.message,
        },
        { status: 500 }
      );
    }

    console.log('[API /api/stats/verified GET] Total verified attestations for user:', count);

    // Get last 5 verified attestations for THIS USER (most recent first)
    const { data: recentUsers, error: fetchError } = await supabase
      .from('attestations')
      .select('username, wallet_address, created_at')
      .eq('fid', userFid)
      .order('created_at', { ascending: false })
      .limit(5);

    if (fetchError) {
      console.error('[API /api/stats/verified GET] Error fetching recent users:', fetchError);
      return NextResponse.json(
        {
          success: false,
          error: 'Failed to fetch recent verified users',
          details: fetchError.message,
        },
        { status: 500 }
      );
    }

    console.log('[API /api/stats/verified GET] Recent users fetched:', recentUsers?.length || 0);

    // Transform data for response (convert snake_case to camelCase)
    const formattedUsers = recentUsers?.map((user) => ({
      username: user.username,
      walletAddress: user.wallet_address,
      createdAt: user.created_at,
    })) || [];

    return NextResponse.json(
      {
        success: true,
        data: {
          totalCount: count || 0,
          recentUsers: formattedUsers,
        },
      },
      { status: 200 }
    );
  } catch (error: any) {
    console.error('[API /api/stats/verified GET] Unexpected error:', error);

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
