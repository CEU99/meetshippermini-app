import { NextRequest, NextResponse } from 'next/server';
import { getServerSupabase } from '@/lib/supabase';

// ============================================================================
// GET Handler - Fetch verified users statistics (GLOBAL)
// ============================================================================
export async function GET(request: NextRequest) {
  try {
    console.log('[API /api/stats/verified GET] Fetching global verified users statistics');

    // Initialize Supabase server client
    const supabase = getServerSupabase();

    // Count total verified users (global)
    const { count, error: countError } = await supabase
      .from('attestations')
      .select('*', { count: 'exact', head: true });

    if (countError) {
      console.error('[API /api/stats/verified] Error counting users:', countError);
      return NextResponse.json(
        { success: false, error: 'Failed to count verified users', details: countError.message },
        { status: 500 }
      );
    }

    // Fetch the most recent 10 verified users (global)
    const { data: recentUsers, error: fetchError } = await supabase
      .from('attestations')
      .select('username, wallet_address, created_at')
      .order('created_at', { ascending: false })
      .limit(10);

    if (fetchError) {
      console.error('[API /api/stats/verified] Error fetching recent users:', fetchError);
      return NextResponse.json(
        { success: false, error: 'Failed to fetch recent verified users', details: fetchError.message },
        { status: 500 }
      );
    }

    // Format data for frontend
    const formattedUsers =
      recentUsers?.map((user) => ({
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
      { success: false, error: 'Internal server error', details: error.message || 'Unknown error' },
      { status: 500 }
    );
  }
}