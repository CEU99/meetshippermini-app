import { NextRequest, NextResponse } from 'next/server';
import { getSession } from '@/lib/auth';
import { sendMessage, markFirstJoin } from '@/lib/services/chat-service';

/**
 * POST /api/chat/rooms/[id]/message
 * Sends a message in a chat room
 * Body: { body: string }
 */
export async function POST(
  request: NextRequest,
  { params }: { params: { id: string } }
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

    const roomId = params.id;
    const { body } = await request.json();

    // Validate message body
    if (!body || typeof body !== 'string' || body.trim().length === 0) {
      return NextResponse.json(
        { error: 'Message body is required' },
        { status: 400 }
      );
    }

    if (body.length > 2000) {
      return NextResponse.json(
        { error: 'Message body is too long (max 2000 characters)' },
        { status: 400 }
      );
    }

    // Mark first join if not already set (in case they send message before GET)
    await markFirstJoin(roomId);

    // Send message (includes all validation and checks)
    const message = await sendMessage(roomId, session.fid, body.trim());

    return NextResponse.json({
      success: true,
      data: message,
    });
  } catch (error: any) {
    console.error('Error sending message:', error);

    // Return specific error messages
    if (error.message === 'Chat room not found') {
      return NextResponse.json(
        { error: 'Chat room not found' },
        { status: 404 }
      );
    }

    if (error.message === 'Chat room is closed') {
      return NextResponse.json(
        { error: 'Chat room is closed. No new messages allowed.' },
        { status: 400 }
      );
    }

    if (error.message === 'Chat room has expired') {
      return NextResponse.json(
        { error: 'Chat room has expired (2-hour limit reached)' },
        { status: 400 }
      );
    }

    if (error.message === 'You are not a participant of this chat room') {
      return NextResponse.json(
        { error: 'You are not a participant of this chat room' },
        { status: 403 }
      );
    }

    return NextResponse.json(
      { error: 'Failed to send message' },
      { status: 500 }
    );
  }
}
