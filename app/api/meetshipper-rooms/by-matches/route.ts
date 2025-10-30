import { NextRequest, NextResponse } from 'next/server';
import { getSession } from '@/lib/auth';
import { getMeetshipperRoomsByMatchIds } from '@/lib/services/meetshipper-room-service';

/**
 * GET /api/meetshipper-rooms/by-matches
 * Fetches conversation room IDs for given match IDs
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

    // Fetch conversation rooms
    const roomMap = await getMeetshipperRoomsByMatchIds(matchIds);

    // Convert Map to array format
    const rooms = Array.from(roomMap.entries()).map(([match_id, id]) => ({
      id,
      match_id,
    }));

    return NextResponse.json({
      success: true,
      data: rooms,
    });
  } catch (error: any) {
    console.error('[API /api/meetshipper-rooms/by-matches] Unexpected error:', error);
    return NextResponse.json(
      { error: 'Internal server error', details: error.message },
      { status: 500 }
    );
  }
}
