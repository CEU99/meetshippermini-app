import { NextRequest, NextResponse } from 'next/server';
import { getSession } from '@/lib/auth';
import { getServerSupabase } from '@/lib/supabase';

/**
 * GET /api/chat/rooms/by-matches
 * Fetches chat room IDs for given match IDs
 * Query params: ?matchIds=id1,id2,id3 (comma-separated match IDs)
 */
export async function GET(request: NextRequest) {
  try {
    // Authenticate user
    const session = await getSession();
    if (!session) {
      return NextResponse.json(
        { error: 'Unauthorized' },
        { status: 401 }
      );
    }

    // Get match IDs from query params
    const { searchParams } = new URL(request.url);
    const matchIdsParam = searchParams.get('matchIds');

    if (!matchIdsParam) {
      return NextResponse.json(
        { error: 'matchIds query parameter is required' },
        { status: 400 }
      );
    }

    // Parse match IDs
    const matchIds = matchIdsParam.split(',').filter(id => id.trim());

    if (matchIds.length === 0) {
      return NextResponse.json({
        success: true,
        data: [],
      });
    }

    const supabase = getServerSupabase();

    // Fetch chat rooms for these matches
    const { data: chatRooms, error } = await supabase
      .from('chat_rooms')
      .select('id, match_id')
      .in('match_id', matchIds);

    if (error) {
      console.error('[API /api/chat/rooms/by-matches] Error:', error);
      return NextResponse.json(
        { error: 'Failed to fetch chat rooms' },
        { status: 500 }
      );
    }

    return NextResponse.json({
      success: true,
      data: chatRooms || [],
    });
  } catch (error: any) {
    console.error('[API /api/chat/rooms/by-matches] Unexpected error:', error);
    return NextResponse.json(
      { error: 'Internal server error', details: error.message },
      { status: 500 }
    );
  }
}
