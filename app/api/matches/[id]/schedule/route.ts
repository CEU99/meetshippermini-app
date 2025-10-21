import { NextRequest, NextResponse } from 'next/server';
import { getSession } from '@/lib/auth';
import { getServerSupabase } from '@/lib/supabase';
import { scheduleMatch, getMeetingDetails } from '@/lib/services/meeting-service';

/**
 * POST /api/matches/:id/schedule
 * Manually schedule or reschedule a meeting
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

    const { id } = await params;
    const supabase = getServerSupabase();

    // Get the match
    const { data: match, error: fetchError } = await supabase
      .from('matches')
      .select('*')
      .eq('id', id)
      .single();

    if (fetchError || !match) {
      return NextResponse.json({ error: 'Match not found' }, { status: 404 });
    }

    // Check if user is a participant
    const userFid = session.fid;
    const isParticipant =
      match.user_a_fid === userFid || match.user_b_fid === userFid;

    if (!isParticipant) {
      return NextResponse.json(
        { error: 'You are not a participant in this match' },
        { status: 403 }
      );
    }

    // Check if both users accepted
    if (!match.a_accepted || !match.b_accepted) {
      return NextResponse.json(
        { error: 'Both users must accept before scheduling' },
        { status: 400 }
      );
    }

    // Schedule the meeting
    const result = await scheduleMatch(id);

    if (!result.success) {
      return NextResponse.json(
        { error: result.error || 'Failed to schedule meeting' },
        { status: 500 }
      );
    }

    return NextResponse.json({
      success: true,
      meetingLink: result.meetingLink,
    });
  } catch (error) {
    console.error('[API] Schedule error:', error);
    return NextResponse.json(
      {
        error: 'Failed to schedule meeting',
        message: error instanceof Error ? error.message : 'Unknown error',
      },
      { status: 500 }
    );
  }
}

/**
 * GET /api/matches/:id/schedule
 * Get meeting details for a match
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
    const supabase = getServerSupabase();

    // Check if user has access to this match
    const { data: match, error: fetchError } = await supabase
      .from('matches')
      .select('user_a_fid, user_b_fid, created_by_fid')
      .eq('id', id)
      .single();

    if (fetchError || !match) {
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

    // Get meeting details
    const meetingDetails = await getMeetingDetails(id);

    return NextResponse.json(meetingDetails);
  } catch (error) {
    console.error('[API] Get schedule error:', error);
    return NextResponse.json(
      { error: 'Failed to fetch meeting details' },
      { status: 500 }
    );
  }
}
