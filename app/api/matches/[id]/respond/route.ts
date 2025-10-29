import { NextRequest, NextResponse } from 'next/server';
import { getSession } from '@/lib/auth';
import { getServerSupabase } from '@/lib/supabase';
import { ensureChatRoom, getChatRoomByMatchId } from '@/lib/services/chat-service';

/**
 * POST /api/matches/:id/respond
 * Accept or decline a match proposal
 */
export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const session = await getSession();
    if (!session) {
      console.error('[API] Respond: No session found');
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { id } = await params;
    const body = await request.json();
    const { response, reason } = body;

    console.log('[API] Respond request:', {
      matchId: id,
      userFid: session.fid,
      username: session.username,
      response,
      hasReason: !!reason,
    });

    // Validate response
    if (!response || !['accept', 'decline'].includes(response)) {
      console.error('[API] Respond: Invalid response type:', response);
      return NextResponse.json(
        { error: 'Invalid response. Must be "accept" or "decline"' },
        { status: 400 }
      );
    }

    const supabase = getServerSupabase();
    const userFid = session.fid;

    // Get the match
    const { data: match, error: fetchError } = await supabase
      .from('matches')
      .select('*')
      .eq('id', id)
      .single();

    if (fetchError) {
      console.error('[API] Respond: Error fetching match:', fetchError);
      return NextResponse.json(
        { error: 'Match not found', details: fetchError.message },
        { status: 404 }
      );
    }

    if (!match) {
      console.error('[API] Respond: Match not found:', id);
      return NextResponse.json({ error: 'Match not found' }, { status: 404 });
    }

    // Check if this is an external match
    const isExternalMatch = match.status === 'pending_external' ||
                           (match.rationale && typeof match.rationale === 'object' && 'isExternalUser' in match.rationale && match.rationale.isExternalUser);

    console.log('[API] Respond: Match found:', {
      matchId: match.id,
      user_a_fid: match.user_a_fid,
      user_b_fid: match.user_b_fid,
      status: match.status,
      a_accepted: match.a_accepted,
      b_accepted: match.b_accepted,
      isExternalMatch,
    });

    // Check if user is a participant
    const isUserA = match.user_a_fid === userFid;
    const isUserB = match.user_b_fid === userFid;

    console.log('[API] Respond: User participation check:', {
      userFid,
      isUserA,
      isUserB,
    });

    if (!isUserA && !isUserB) {
      console.error('[API] Respond: User not a participant');
      return NextResponse.json(
        { error: 'You are not a participant in this match' },
        { status: 403 }
      );
    }

    // Check if user already responded
    if (isUserA && match.a_accepted) {
      return NextResponse.json(
        { error: 'You have already accepted this match' },
        { status: 400 }
      );
    }
    if (isUserB && match.b_accepted) {
      return NextResponse.json(
        { error: 'You have already accepted this match' },
        { status: 400 }
      );
    }

    // Check if match is still in valid state
    if (!['proposed', 'accepted_by_a', 'accepted_by_b', 'pending', 'pending_external'].includes(match.status)) {
      console.error('[API] Respond: Match status not valid for response:', match.status);
      return NextResponse.json(
        { error: 'This match is no longer active' },
        { status: 400 }
      );
    }

    if (isExternalMatch) {
      console.log('[API] Respond: Processing external match response');
    }

    // Prepare update
    const updateData: Record<string, boolean | string> = {};

    if (response === 'accept') {
      if (isUserA) {
        updateData.a_accepted = true;
      } else {
        updateData.b_accepted = true;
      }

      // For external matches, handle status transition explicitly
      if (isExternalMatch) {
        console.log('[API] Respond: External match accepted by', isUserA ? 'user_a' : 'user_b');

        // Check if both will be accepted after this update
        const willBothAccept = (isUserA && match.b_accepted) || (isUserB && match.a_accepted) ||
                               (isUserA && updateData.b_accepted) || (isUserB && updateData.a_accepted);

        if (willBothAccept) {
          // Both accepted - transition to 'accepted'
          updateData.status = 'accepted';
          console.log('[API] Respond: External match - both parties accepted, transitioning to "accepted"');
        } else {
          // Only one accepted - keep as pending_external or transition to waiting state
          // For now, keep the status as is to maintain the external flag
          console.log('[API] Respond: External match - waiting for other party');
        }
      }
    } else {
      // Decline
      updateData.status = 'declined';
      // Optionally store decline reason
      if (reason) {
        updateData.message = match.message
          ? `${match.message}\n\nDecline reason: ${reason}`
          : `Decline reason: ${reason}`;
      }
      if (isExternalMatch) {
        console.log('[API] Respond: External match declined by', isUserA ? 'user_a' : 'user_b', reason ? `- Reason: ${reason}` : '');
      }
    }

    // Update the match
    console.log('[API] Respond: Updating match with data:', {
      matchId: id,
      updateData,
      currentStatus: match.status,
      targetStatus: updateData.status || 'unchanged',
      userRole: isUserA ? 'user_a' : 'user_b',
      isExternalMatch,
      currentAcceptance: { a_accepted: match.a_accepted, b_accepted: match.b_accepted },
      newAcceptance: {
        a_accepted: updateData.a_accepted !== undefined ? updateData.a_accepted : match.a_accepted,
        b_accepted: updateData.b_accepted !== undefined ? updateData.b_accepted : match.b_accepted,
      },
    });

    const { data: updatedMatch, error: updateError } = await supabase
      .from('matches')
      .update(updateData)
      .eq('id', id)
      .select()
      .single();

    if (updateError) {
      console.error('[API] Respond: Error updating match:', {
        error: updateError,
        message: updateError.message,
        details: updateError.details,
        hint: updateError.hint,
        code: updateError.code,
      });
      return NextResponse.json(
        {
          error: 'Failed to update match',
          message: updateError.message,
          details: updateError.details,
          hint: updateError.hint,
        },
        { status: 500 }
      );
    }

    if (!updatedMatch) {
      console.error('[API] Respond: Update succeeded but no data returned');
      return NextResponse.json(
        { error: 'Failed to retrieve updated match' },
        { status: 500 }
      );
    }

    console.log('[API] Respond: Match updated successfully:', {
      matchId: updatedMatch.id,
      status: updatedMatch.status,
      a_accepted: updatedMatch.a_accepted,
      b_accepted: updatedMatch.b_accepted,
    });

    // Initialize chatRoomId variable for use in all code paths
    let chatRoomId: string | undefined;

    // Create system messages for accept/decline
    if (response === 'decline') {
      // Notify the other user that match was declined
      const otherUserFid = isUserA ? match.user_b_fid : match.user_a_fid;
      const declinerName = session.username || `User ${userFid}`;

      await supabase.from('messages').insert({
        match_id: id,
        sender_fid: userFid,
        content: `Match declined by ${declinerName}${reason ? `: ${reason}` : ''}`,
        is_system_message: true,
      });

      // Also notify the requester if this was a manual match
      if (match.rationale && typeof match.rationale === 'object' && 'manualMatch' in match.rationale) {
        const requesterFid = match.user_a_fid;
        if (requesterFid !== userFid) {
          await supabase.from('messages').insert({
            match_id: id,
            sender_fid: otherUserFid,
            content: `Your match request was declined.`,
            is_system_message: true,
          });
        }
      }
    } else {
      // Acceptance
      const accepterName = session.username || `User ${userFid}`;

      // If both accepted, create chat room
      if (updatedMatch.a_accepted && updatedMatch.b_accepted) {
        console.log(`[Match] Both users accepted, creating chat room for match ${id}`);

        try {
          const chatRoom = await ensureChatRoom(id, match.user_a_fid, match.user_b_fid);
          chatRoomId = chatRoom.id;
          console.log(`[Match] Chat room created: ${chatRoomId}`);

          // Send system messages with chat room notification to BOTH users
          // Message 1: For User A
          await supabase.from('messages').insert({
            match_id: id,
            sender_fid: match.user_a_fid,
            content: `🎉 Match accepted! Both parties agreed to meet. Your chat room is ready. Click "Open Chat" to start your conversation. Note: Chat room will auto-close 2 hours after first entry.`,
            is_system_message: true,
          });

          // Message 2: For User B
          await supabase.from('messages').insert({
            match_id: id,
            sender_fid: match.user_b_fid,
            content: `🎉 Match accepted! Both parties agreed to meet. Your chat room is ready. Click "Open Chat" to start your conversation. Note: Chat room will auto-close 2 hours after first entry.`,
            is_system_message: true,
          });
        } catch (error) {
          console.error(`[Match] Failed to create chat room:`, error);

          // Send system messages about acceptance without chat room
          await supabase.from('messages').insert([
            {
              match_id: id,
              sender_fid: match.user_a_fid,
              content: `Match accepted by both parties! Chat room creation in progress...`,
              is_system_message: true,
            },
            {
              match_id: id,
              sender_fid: match.user_b_fid,
              content: `Match accepted by both parties! Chat room creation in progress...`,
              is_system_message: true,
            }
          ]);
        }
      } else {
        // Only one person accepted so far, notify the other
        const otherUserFid = isUserA ? match.user_b_fid : match.user_a_fid;

        await supabase.from('messages').insert({
          match_id: id,
          sender_fid: userFid,
          content: `${accepterName} accepted the match! Waiting for your response.`,
          is_system_message: true,
        });
      }
    }

    // Fetch full match details
    const { data: matchDetails, error: detailsError } = await supabase
      .from('match_details')
      .select('*')
      .eq('id', id)
      .single();

    if (detailsError) {
      console.error('[API] Respond: Error fetching match details:', detailsError);
      // Still return success since the match was updated, just without full details
      return NextResponse.json({
        success: true,
        match: updatedMatch,
        chatRoomId,
      });
    }

    console.log('[API] Respond: Request completed successfully');

    return NextResponse.json({
      success: true,
      match: matchDetails || updatedMatch,
      chatRoomId,
    });
  } catch (error) {
    console.error('[API] Respond error (uncaught):', {
      error,
      message: error instanceof Error ? error.message : 'Unknown error',
      stack: error instanceof Error ? error.stack : undefined,
    });
    const finalErrorMessage = error instanceof Error ? error.message : 'Unknown error';
    const errorDetails = error instanceof Error ? error.toString() : 'Unknown error';
    return NextResponse.json(
      {
        error: 'Failed to respond to match',
        message: finalErrorMessage,
        details: errorDetails,
      },
      { status: 500 }
    );
  }
}
