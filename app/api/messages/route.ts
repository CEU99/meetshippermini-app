import { NextRequest, NextResponse } from 'next/server';
import { getSession } from '@/lib/auth';
import { getServerSupabase } from '@/lib/supabase';

// GET /api/messages?matchId=xxx - Get all messages for a match
export async function GET(request: NextRequest) {
  try {
    const session = await getSession();
    if (!session) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { searchParams } = new URL(request.url);
    const matchId = searchParams.get('matchId');

    if (!matchId) {
      return NextResponse.json(
        { error: 'Missing matchId parameter' },
        { status: 400 }
      );
    }

    const supabase = getServerSupabase();

    // First, verify user has access to this match
    const { data: match } = await supabase
      .from('matches')
      .select('*')
      .eq('id', matchId)
      .single();

    if (!match) {
      return NextResponse.json({ error: 'Match not found' }, { status: 404 });
    }

    const userFid = session.fid;
    const hasAccess =
      match.user_a_fid === userFid ||
      match.user_b_fid === userFid ||
      match.created_by_fid === userFid;

    if (!hasAccess) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 });
    }

    // Get messages
    const { data: messages, error } = await supabase
      .from('message_details')
      .select('*')
      .eq('match_id', matchId)
      .order('created_at', { ascending: true });

    if (error) {
      console.error('Error fetching messages:', error);
      return NextResponse.json(
        { error: 'Failed to fetch messages' },
        { status: 500 }
      );
    }

    return NextResponse.json({ messages: messages || [] });
  } catch (error) {
    console.error('Get messages error:', error);
    return NextResponse.json(
      { error: 'Failed to fetch messages' },
      { status: 500 }
    );
  }
}

// POST /api/messages - Send a message
export async function POST(request: NextRequest) {
  try {
    const session = await getSession();
    if (!session) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const body = await request.json();
    const { matchId, content } = body;

    if (!matchId || !content || content.trim() === '') {
      return NextResponse.json(
        { error: 'Missing required fields: matchId and content' },
        { status: 400 }
      );
    }

    const supabase = getServerSupabase();

    // Verify user has access to this match
    const { data: match } = await supabase
      .from('matches')
      .select('*')
      .eq('id', matchId)
      .single();

    if (!match) {
      return NextResponse.json({ error: 'Match not found' }, { status: 404 });
    }

    const userFid = session.fid;
    const hasAccess =
      match.user_a_fid === userFid || match.user_b_fid === userFid;

    if (!hasAccess) {
      return NextResponse.json(
        { error: 'You are not a participant in this match' },
        { status: 403 }
      );
    }

    // Insert message
    const { data: message, error } = await supabase
      .from('messages')
      .insert({
        match_id: matchId,
        sender_fid: userFid,
        content: content.trim(),
        is_system_message: false,
      })
      .select()
      .single();

    if (error) {
      console.error('Error creating message:', error);
      return NextResponse.json(
        { error: 'Failed to send message' },
        { status: 500 }
      );
    }

    // Fetch the full message details
    const { data: messageDetails } = await supabase
      .from('message_details')
      .select('*')
      .eq('id', message.id)
      .single();

    return NextResponse.json({ message: messageDetails }, { status: 201 });
  } catch (error) {
    console.error('Send message error:', error);
    return NextResponse.json(
      { error: 'Failed to send message' },
      { status: 500 }
    );
  }
}
