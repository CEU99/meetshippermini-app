import { NextRequest, NextResponse } from 'next/server';
import { getSession } from '@/lib/auth';
import { getChatRoom, markFirstJoin } from '@/lib/services/chat-service';

/**
 * GET /api/chat/rooms/[id]
 * Fetches chat room details with participants and messages
 * Also marks first join if this is the first access
 */
export async function GET(
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

    // Get chat room with details
    const room = await getChatRoom(roomId);

    if (!room) {
      return NextResponse.json(
        { error: 'Chat room not found' },
        { status: 404 }
      );
    }

    // Verify user is a participant
    const isParticipant = room.participants.some(
      (p) => p.fid === session.fid
    );

    if (!isParticipant) {
      return NextResponse.json(
        { error: 'You are not a participant of this chat room' },
        { status: 403 }
      );
    }

    // Mark first join if not already set
    if (!room.first_join_at) {
      await markFirstJoin(roomId);
      // Update the room object
      room.first_join_at = new Date().toISOString();
      // Recalculate remaining seconds (should be full TTL now)
      room.remaining_seconds = room.ttl_seconds;
    }

    return NextResponse.json({
      success: true,
      data: room,
    });
  } catch (error) {
    console.error('Error fetching chat room:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
