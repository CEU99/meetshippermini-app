import { NextRequest, NextResponse } from 'next/server';
import { getSession } from '@/lib/auth';
import { getServerSupabase } from '@/lib/supabase';
import { checkMeetingAchievements } from '@/lib/services/achievement-service';
import { closeMeetingRoom } from '@/lib/services/meeting-service';

/**
 * POST /api/matches/:id/complete
 * Mark a meeting as completed by the current user
 *
 * Flow:
 * 1. User A clicks "Meeting Completed" → a_completed = true
 * 2. User B clicks "Meeting Completed" → b_completed = true
 * 3. Trigger automatically sets status = 'completed' when both true
 * 4. Match moves from Accepted tab to Completed tab
 */
export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const session = await getSession();
    if (!session) {
      console.error('[API] Complete: No session found');
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { id } = await params;

    console.log('[API] Complete meeting request:', {
      matchId: id,
      userFid: session.fid,
      username: session.username,
    });

    const supabase = getServerSupabase();
    const userFid = session.fid;

    // Get the match
    const { data: match, error: fetchError } = await supabase
      .from('matches')
      .select('*')
      .eq('id', id)
      .single();

    if (fetchError) {
      console.error('[API] Complete: Error fetching match:', fetchError);
      return NextResponse.json(
        { error: 'Match not found', details: fetchError.message },
        { status: 404 }
      );
    }

    if (!match) {
      console.error('[API] Complete: Match not found:', id);
      return NextResponse.json({ error: 'Match not found' }, { status: 404 });
    }

    console.log('[API] Complete: Match found:', {
      matchId: match.id,
      user_a_fid: match.user_a_fid,
      user_b_fid: match.user_b_fid,
      status: match.status,
      a_accepted: match.a_accepted,
      b_accepted: match.b_accepted,
      a_completed: match.a_completed,
      b_completed: match.b_completed,
    });

    // Check if user is a participant
    const isUserA = match.user_a_fid === userFid;
    const isUserB = match.user_b_fid === userFid;

    if (!isUserA && !isUserB) {
      console.error('[API] Complete: User not a participant');
      return NextResponse.json(
        { error: 'You are not a participant in this match' },
        { status: 403 }
      );
    }

    // Check if match is in accepted status
    if (match.status !== 'accepted') {
      console.error('[API] Complete: Match not in accepted status:', match.status);
      return NextResponse.json(
        { error: 'Only accepted matches can be marked as completed' },
        { status: 400 }
      );
    }

    // Check if both users accepted
    if (!match.a_accepted || !match.b_accepted) {
      console.error('[API] Complete: Not both users accepted');
      return NextResponse.json(
        { error: 'Both users must accept before completing the meeting' },
        { status: 400 }
      );
    }

    // Check if user already marked as completed
    if (isUserA && match.a_completed) {
      return NextResponse.json(
        { error: 'You have already marked this meeting as completed' },
        { status: 400 }
      );
    }
    if (isUserB && match.b_completed) {
      return NextResponse.json(
        { error: 'You have already marked this meeting as completed' },
        { status: 400 }
      );
    }

    // Prepare update data
    const updateData: any = {};

    if (isUserA) {
      updateData.a_completed = true;
      console.log('[API] Complete: Marking User A as completed');
    } else {
      updateData.b_completed = true;
      console.log('[API] Complete: Marking User B as completed');
    }

    // Update the match
    const { data: updatedMatch, error: updateError } = await supabase
      .from('matches')
      .update(updateData)
      .eq('id', id)
      .select()
      .single();

    if (updateError) {
      console.error('[API] Complete: Error updating match:', {
        error: updateError,
        message: updateError.message,
        details: updateError.details,
        hint: updateError.hint,
        code: updateError.code,
      });
      return NextResponse.json(
        {
          error: 'Failed to mark meeting as completed',
          message: updateError.message,
          details: updateError.details,
          hint: updateError.hint,
        },
        { status: 500 }
      );
    }

    if (!updatedMatch) {
      console.error('[API] Complete: Update succeeded but no data returned');
      return NextResponse.json(
        { error: 'Failed to retrieve updated match' },
        { status: 500 }
      );
    }

    console.log('[API] Complete: Match updated successfully:', {
      matchId: updatedMatch.id,
      status: updatedMatch.status,
      a_completed: updatedMatch.a_completed,
      b_completed: updatedMatch.b_completed,
    });

    // Check if both completed (trigger should have updated status)
    const bothCompleted = updatedMatch.a_completed && updatedMatch.b_completed;

    // Create system message
    const completedByName = session.username || `User ${userFid}`;

    if (bothCompleted) {
      // Both users marked as completed
      console.log('[API] Complete: Both users completed, match status should be completed');

      await supabase.from('messages').insert([
        {
          match_id: id,
          sender_fid: match.user_a_fid,
          content: `✅ Meeting completed! Both parties confirmed the meeting took place.`,
          is_system_message: true,
        },
        {
          match_id: id,
          sender_fid: match.user_b_fid,
          content: `✅ Meeting completed! Both parties confirmed the meeting took place.`,
          is_system_message: true,
        }
      ]);

      // Check and award meeting achievements for BOTH users
      try {
        const [achievementsA, achievementsB] = await Promise.all([
          checkMeetingAchievements(match.user_a_fid),
          checkMeetingAchievements(match.user_b_fid),
        ]);

        if (achievementsA.length > 0) {
          console.log(`[Achievement] Awarded ${achievementsA.length} meeting achievement(s) to User A (${match.user_a_fid})`);
          achievementsA.forEach(a => {
            if (a.awarded) {
              console.log(`[Achievement] ✅ ${a.code} (+${a.points}pts) - Level ${a.level}`);
            }
          });
        }

        if (achievementsB.length > 0) {
          console.log(`[Achievement] Awarded ${achievementsB.length} meeting achievement(s) to User B (${match.user_b_fid})`);
          achievementsB.forEach(a => {
            if (a.awarded) {
              console.log(`[Achievement] ✅ ${a.code} (+${a.points}pts) - Level ${a.level}`);
            }
          });
        }
      } catch (achError) {
        // Don't fail the request if achievement check fails
        console.error('[Achievement] Error checking meeting achievements:', achError);
      }

      // Close the meeting room immediately when both complete
      try {
        console.log('[API] Complete: Closing meeting room (both users completed)');
        const closeResult = await closeMeetingRoom(id, 'manual');
        if (closeResult.success) {
          console.log('[API] Complete: ✓ Meeting room closed successfully');
        } else {
          console.error('[API] Complete: Room closure returned error:', closeResult.error);
        }
      } catch (closeError) {
        // Don't fail the request if room closure fails
        console.error('[API] Complete: Error closing room:', closeError);
      }
    } else {
      // Only one user marked as completed so far
      const otherUserFid = isUserA ? match.user_b_fid : match.user_a_fid;

      await supabase.from('messages').insert({
        match_id: id,
        sender_fid: userFid,
        content: `${completedByName} marked the meeting as completed. Waiting for the other party to confirm.`,
        is_system_message: true,
      });
    }

    // Fetch full match details
    const { data: matchDetails, error: detailsError } = await supabase
      .from('match_details')
      .select('*')
      .eq('id', id)
      .single();

    if (detailsError) {
      console.error('[API] Complete: Error fetching match details:', detailsError);
      // Still return success since the match was updated
      return NextResponse.json({
        success: true,
        match: updatedMatch,
        bothCompleted,
        message: bothCompleted
          ? 'Meeting marked as completed by both parties'
          : 'You have marked the meeting as completed',
      });
    }

    console.log('[API] Complete: Request completed successfully');

    return NextResponse.json({
      success: true,
      match: matchDetails || updatedMatch,
      bothCompleted,
      message: bothCompleted
        ? 'Meeting marked as completed by both parties'
        : 'You have marked the meeting as completed',
    });

  } catch (error: any) {
    console.error('[API] Complete error (uncaught):', {
      error,
      message: error?.message,
      stack: error?.stack,
    });
    return NextResponse.json(
      {
        error: 'Failed to mark meeting as completed',
        message: error?.message || 'Unknown error occurred',
        details: error?.toString(),
      },
      { status: 500 }
    );
  }
}
