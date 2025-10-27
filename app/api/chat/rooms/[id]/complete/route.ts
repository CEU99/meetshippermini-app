import { NextRequest, NextResponse } from 'next/server';
import { getSession } from '@/lib/auth';
import { markParticipantCompleted } from '@/lib/services/chat-service';

/**
 * POST /api/chat/rooms/[id]/complete
 * Marks the current user as having completed the meeting
 * If both participants mark complete, the room closes immediately
 */
export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    // Authenticate user
    const session = await getSession();
    if (!session) {
      return NextResponse.json(
        { error: 'Unauthorized' },
        { status: 401 }
      );
    }

    const { id: roomId } = await params;

    // Mark participant as completed
    const result = await markParticipantCompleted(roomId, session.fid);

    return NextResponse.json({
      success: true,
      data: {
        room_closed: result.roomClosed,
        message: result.roomClosed
          ? 'Both participants marked complete. Chat room has been closed.'
          : 'You have marked the meeting as complete. Waiting for the other participant.',
      },
    });
  } catch (error: any) {
    console.error('Error marking participant completed:', error);

    return NextResponse.json(
      { error: error.message || 'Failed to mark meeting as complete' },
      { status: 500 }
    );
  }
}
