import { NextRequest, NextResponse } from 'next/server';
import { getSession } from '@/lib/auth';
import {
  getRoomMessages,
  sendMessage,
} from '@/lib/services/meetshipper-message-service';
import { getMeetshipperRoomById } from '@/lib/services/meetshipper-room-service';

/**
 * GET /api/meetshipper-rooms/[id]/messages
 * Fetch messages for a conversation room
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

    const { id: roomId } = await params;

    // Verify user is a participant
    const room = await getMeetshipperRoomById(roomId);
    if (!room) {
      return NextResponse.json(
        { error: 'Room not found' },
        { status: 404 }
      );
    }

    if (room.user_a_fid !== session.fid && room.user_b_fid !== session.fid) {
      return NextResponse.json(
        { error: 'You are not a participant in this room' },
        { status: 403 }
      );
    }

    // Fetch messages
    const messages = await getRoomMessages(roomId, 100);

    return NextResponse.json({
      success: true,
      messages,
    });
  } catch (error) {
    console.error('[API] Error fetching messages:', error);
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
    return NextResponse.json(
      { error: 'Failed to fetch messages', message: errorMessage },
      { status: 500 }
    );
  }
}

/**
 * POST /api/meetshipper-rooms/[id]/messages
 * Send a message to a conversation room
 */
export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const session = await getSession();
    if (!session) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { id: roomId } = await params;
    const body = await request.json();
    const { content } = body;

    if (!content || typeof content !== 'string' || content.trim().length === 0) {
      return NextResponse.json(
        { error: 'Message content is required' },
        { status: 400 }
      );
    }

    if (content.length > 2000) {
      return NextResponse.json(
        { error: 'Message content too long (max 2000 characters)' },
        { status: 400 }
      );
    }

    // Verify user is a participant
    const room = await getMeetshipperRoomById(roomId);
    if (!room) {
      return NextResponse.json(
        { error: 'Room not found' },
        { status: 404 }
      );
    }

    if (room.user_a_fid !== session.fid && room.user_b_fid !== session.fid) {
      return NextResponse.json(
        { error: 'You are not a participant in this room' },
        { status: 403 }
      );
    }

    // Send message
    const message = await sendMessage(roomId, session.fid, content.trim());

    return NextResponse.json({
      success: true,
      message,
    });
  } catch (error) {
    console.error('[API] Error sending message:', error);
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';

    // Provide helpful error message if table doesn't exist
    if (errorMessage.includes('meetshipper_messages') && errorMessage.includes('not found')) {
      return NextResponse.json(
        {
          error: 'Database setup incomplete',
          message: 'The meetshipper_messages table does not exist. Please apply the database migration first.',
          details: 'See MESSAGE_SENDING_FIX.md for instructions'
        },
        { status: 500 }
      );
    }

    return NextResponse.json(
      { error: 'Failed to send message', message: errorMessage },
      { status: 500 }
    );
  }
}
