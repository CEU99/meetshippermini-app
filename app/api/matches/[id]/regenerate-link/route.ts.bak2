import { NextRequest, NextResponse } from 'next/server';
import { getSession } from '@/lib/auth';
import { getServerSupabase } from '@/lib/supabase';
import { scheduleMatch } from '@/lib/services/meeting-service';

/**
 * POST /api/matches/:id/regenerate-link
 * Regenerate meeting link for an accepted match
 *
 * This endpoint is useful when:
 * - The meeting link was generated with a wrong provider
 * - The link expired or is invalid
 * - You need to switch from one provider to another
 */
export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const session = await getSession();

    // Allow both authenticated users and dev mode
    const isDev = process.env.NODE_ENV === 'development';

    if (!session && !isDev) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { id } = await params;

    console.log('[API] Regenerate link request:', {
      matchId: id,
      userFid: session?.fid,
      isDev,
    });

    const supabase = getServerSupabase();

    // Get the match
    const { data: match, error: fetchError } = await supabase
      .from('matches')
      .select('*')
      .eq('id', id)
      .single();

    if (fetchError || !match) {
      return NextResponse.json(
        { error: 'Match not found' },
        { status: 404 }
      );
    }

    // Verify both users accepted
    if (!match.a_accepted || !match.b_accepted) {
      return NextResponse.json(
        { error: 'Both users must accept before generating meeting link' },
        { status: 400 }
      );
    }

    // Verify user is a participant (skip in dev mode)
    if (session && !isDev) {
      const isParticipant =
        match.user_a_fid === session.fid ||
        match.user_b_fid === session.fid;

      if (!isParticipant) {
        return NextResponse.json(
          { error: 'You are not a participant in this match' },
          { status: 403 }
        );
      }
    }

    console.log('[API] Regenerating meeting link for match:', {
      matchId: id,
      currentLink: match.meeting_link,
      status: match.status,
    });

    // Clear the old link first
    await supabase
      .from('matches')
      .update({
        meeting_link: null,
        scheduled_at: null,
      })
      .eq('id', id);

    console.log('[API] Cleared old link, generating new one...');

    // Generate new meeting link
    const result = await scheduleMatch(id);

    if (!result.success) {
      console.error('[API] Failed to regenerate link:', result.error);
      return NextResponse.json(
        { error: result.error || 'Failed to generate meeting link' },
        { status: 500 }
      );
    }

    console.log('[API] ✓ Meeting link regenerated:', result.meetingLink);

    // Fetch updated match
    const { data: updatedMatch } = await supabase
      .from('match_details')
      .select('*')
      .eq('id', id)
      .single();

    return NextResponse.json({
      success: true,
      message: 'Meeting link regenerated successfully',
      meetingLink: result.meetingLink,
      match: updatedMatch,
    });

  } catch (error: any) {
    console.error('[API] Regenerate link error:', error);
    return NextResponse.json(
      {
        error: 'Failed to regenerate meeting link',
        message: error?.message,
      },
      { status: 500 }
    );
  }
}
