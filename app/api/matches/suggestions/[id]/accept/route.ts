import { NextRequest, NextResponse } from 'next/server';
import { getSession } from '@/lib/auth';
import { getServerSupabase } from '@/lib/supabase';
import { ensureMeetshipperRoom } from '@/lib/services/meetshipper-room-service';

/**
 * POST /api/matches/suggestions/[id]/accept
 * Accept a match suggestion
 */
export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const session = await getSession();
    if (!session) {
      console.error('[API] Accept Suggestion: No session found');
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { id } = await params;

    console.log('[API] Accepting suggestion:', {
      suggestionId: id,
      userFid: session.fid,
    });

    const supabase = getServerSupabase();

    // Get the suggestion
    const { data: suggestion, error: fetchError } = await supabase
      .from('match_suggestions')
      .select('*')
      .eq('id', id)
      .single();

    if (fetchError || !suggestion) {
      console.error('[API] Error fetching suggestion:', fetchError);
      return NextResponse.json(
        { error: 'Suggestion not found' },
        { status: 404 }
      );
    }

    // Check if user is a participant
    const isUserA = suggestion.user_a_fid === session.fid;
    const isUserB = suggestion.user_b_fid === session.fid;

    if (!isUserA && !isUserB) {
      return NextResponse.json(
        { error: 'You are not a participant in this suggestion' },
        { status: 403 }
      );
    }

    // Check if already accepted
    if (isUserA && suggestion.a_accepted) {
      return NextResponse.json(
        { error: 'You have already accepted this suggestion' },
        { status: 400 }
      );
    }

    if (isUserB && suggestion.b_accepted) {
      return NextResponse.json(
        { error: 'You have already accepted this suggestion' },
        { status: 400 }
      );
    }

    // Check if already declined or cancelled
    if (['declined', 'cancelled'].includes(suggestion.status)) {
      return NextResponse.json(
        { error: 'This suggestion is no longer active' },
        { status: 400 }
      );
    }

    // Update acceptance flag
    const updateData: { a_accepted?: boolean; b_accepted?: boolean } = {};
    if (isUserA) {
      updateData.a_accepted = true;
    } else {
      updateData.b_accepted = true;
    }

    console.log('[API] Updating suggestion with:', updateData);

    const { data: updatedSuggestion, error: updateError } = await supabase
      .from('match_suggestions')
      .update(updateData)
      .eq('id', id)
      .select()
      .single();

    if (updateError) {
      console.error('[API] Error updating suggestion:', updateError);
      return NextResponse.json(
        { error: 'Failed to accept suggestion', details: updateError.message },
        { status: 500 }
      );
    }

    console.log('[API] Suggestion updated:', {
      id: updatedSuggestion.id,
      status: updatedSuggestion.status,
      a_accepted: updatedSuggestion.a_accepted,
      b_accepted: updatedSuggestion.b_accepted,
    });

    // If both accepted, create MeetShipper conversation room
    let roomId: string | undefined;
    if (updatedSuggestion.a_accepted && updatedSuggestion.b_accepted) {
      console.log('[API] Both users accepted, creating MeetShipper conversation room');

      try {
        // First, create a regular match record for compatibility with existing system
        const { data: match, error: matchError } = await supabase
          .from('matches')
          .insert({
            user_a_fid: suggestion.user_a_fid,
            user_b_fid: suggestion.user_b_fid,
            created_by_fid: suggestion.created_by_fid,
            status: 'accepted',
            a_accepted: true,
            b_accepted: true,
            message: `Match suggestion: ${suggestion.message}`,
            rationale: {
              suggestionId: suggestion.id,
              type: 'suggestion',
            },
          })
          .select()
          .single();

        if (matchError) {
          console.error('[API] Error creating match record:', matchError);
          throw matchError;
        }

        // Create MeetShipper conversation room
        const room = await ensureMeetshipperRoom(
          match.id,
          suggestion.user_a_fid,
          suggestion.user_b_fid
        );
        roomId = room.id;

        // Update suggestion with room_id
        await supabase
          .from('match_suggestions')
          .update({ chat_room_id: roomId })
          .eq('id', id);

        console.log('[API] MeetShipper conversation room created:', roomId);

        // TODO: Send notifications about conversation room availability
        // TODO: Award points to suggester and participants
      } catch (error) {
        console.error('[API] Error creating MeetShipper conversation room:', error);
        // Don't fail the acceptance, just log the error
        // The room can be created later or manually if needed
      }
    }

    return NextResponse.json({
      success: true,
      suggestion: updatedSuggestion,
      roomId,
      bothAccepted: updatedSuggestion.a_accepted && updatedSuggestion.b_accepted,
      message: roomId
        ? 'Conversation room is ready! Both parties accepted.'
        : 'Suggestion accepted! Waiting for the other party.',
    });
  } catch (error) {
    console.error('[API] Accept suggestion error (uncaught):', error);
    const errorMessage =
      error instanceof Error ? error.message : 'Unknown error';
    return NextResponse.json(
      {
        error: 'Failed to accept suggestion',
        message: errorMessage,
      },
      { status: 500 }
    );
  }
}
