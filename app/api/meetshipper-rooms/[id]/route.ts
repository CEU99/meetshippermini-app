import { NextRequest, NextResponse } from 'next/server';
import { getSession } from '@/lib/auth';
import { getMeetshipperRoomById } from '@/lib/services/meetshipper-room-service';

/**
 * GET /api/meetshipper-rooms/[id]
 * Fetch a single MeetShipper conversation room by ID
 */
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const session = await getSession();
    if (!session) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { id } = await params;

    console.log('[API] Fetching room:', { roomId: id, userFid: session.fid });

    const room = await getMeetshipperRoomById(id);

    if (!room) {
      return NextResponse.json(
        { error: 'Room not found' },
        { status: 404 }
      );
    }

    // Verify user is a participant
    if (room.user_a_fid !== session.fid && room.user_b_fid !== session.fid) {
      return NextResponse.json(
        { error: 'You are not a participant in this room' },
        { status: 403 }
      );
    }

    return NextResponse.json({
      success: true,
      room,
    });
  } catch (error) {
    console.error('[API] Error fetching room:', error);
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
    return NextResponse.json(
      { error: 'Failed to fetch room', message: errorMessage },
      { status: 500 }
    );
  }
}
