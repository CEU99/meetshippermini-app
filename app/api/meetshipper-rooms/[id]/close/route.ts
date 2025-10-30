import { NextRequest, NextResponse } from 'next/server';
import { getSession } from '@/lib/auth';
import { closeMeetshipperRoom, getMeetshipperRoomById } from '@/lib/services/meetshipper-room-service';

/**
 * POST /api/meetshipper-rooms/:id/close
 * Closes a conversation room permanently
 */
export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const session = await getSession();
    if (!session) {
      console.error('[API] Close room: No session found');
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { id } = await params;

    console.log('[API] Close room request:', {
      roomId: id,
      userFid: session.fid,
      username: session.username,
    });

    // Get the room to verify access
    const room = await getMeetshipperRoomById(id);

    if (!room) {
      console.error('[API] Close room: Room not found:', id);
      return NextResponse.json({ error: 'Room not found' }, { status: 404 });
    }

    // Check if user is a participant
    const isParticipant = room.user_a_fid === session.fid || room.user_b_fid === session.fid;

    if (!isParticipant) {
      console.error('[API] Close room: User not a participant');
      return NextResponse.json(
        { error: 'You are not a participant in this conversation room' },
        { status: 403 }
      );
    }

    // Check if already closed
    if (room.is_closed) {
      return NextResponse.json(
        { error: 'This conversation room is already closed' },
        { status: 400 }
      );
    }

    // Close the room
    const closedRoom = await closeMeetshipperRoom(id, session.fid);

    console.log('[API] Room closed successfully:', {
      roomId: closedRoom.id,
      closedBy: session.username,
      closedAt: closedRoom.closed_at,
    });

    return NextResponse.json({
      success: true,
      room: closedRoom,
    });
  } catch (error) {
    console.error('[API] Close room error (uncaught):', {
      error,
      message: error instanceof Error ? error.message : 'Unknown error',
      stack: error instanceof Error ? error.stack : undefined,
    });
    const finalErrorMessage = error instanceof Error ? error.message : 'Unknown error';
    const errorDetails = error instanceof Error ? error.toString() : 'Unknown error';
    return NextResponse.json(
      {
        error: 'Failed to close conversation room',
        message: finalErrorMessage,
        details: errorDetails,
      },
      { status: 500 }
    );
  }
}
