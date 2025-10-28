import { NextRequest, NextResponse } from 'next/server';
import { getSession } from '@/lib/auth';
import { getServerSupabase } from '@/lib/supabase';
import { isInCooldown, hasActiveMatch, getPendingProposalCount, MATCHING_CONFIG } from '@/lib/services/matching-service';
import { checkMatchRequestAchievements } from '@/lib/services/achievement-service';
import { neynarAPI } from '@/lib/neynar';
import { sendMatchRequestNotification } from '@/lib/services/farcaster-notification-service';

/**
 * POST /api/matches/manual
 * Create a manual match request from current user to target user
 *
 * Body:
 * - targetFid: number (FID of the person you want to match with)
 * - introductionMessage: string (20-100 characters)
 */
export async function POST(request: NextRequest) {
  try {
    const session = await getSession();
    if (!session) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const body = await request.json();
    const { targetFid, introductionMessage } = body;

    // Validate input
    if (!targetFid || typeof targetFid !== 'number') {
      return NextResponse.json(
        { error: 'Missing or invalid targetFid' },
        { status: 400 }
      );
    }

    if (!introductionMessage || typeof introductionMessage !== 'string') {
      return NextResponse.json(
        { error: 'Missing introduction message' },
        { status: 400 }
      );
    }

    const message = introductionMessage.trim();

    // Validate message length
    if (message.length < 20) {
      return NextResponse.json(
        { error: 'Introduction message must be at least 20 characters' },
        { status: 400 }
      );
    }

    if (message.length > 100) {
      return NextResponse.json(
        { error: 'Introduction message must be at most 100 characters' },
        { status: 400 }
      );
    }

    // Validate not matching with self
    if (targetFid === session.fid) {
      return NextResponse.json(
        { error: 'You cannot create a match request with yourself' },
        { status: 400 }
      );
    }

    const supabase = getServerSupabase();
    const requesterFid = session.fid;

    // Check if target user exists in our database
    const { data: targetUser, error: userError } = await supabase
      .from('users')
      .select('fid, username, display_name')
      .eq('fid', targetFid)
      .single();

    let isExternalUser = false;
    let externalUserData = null;

    // If user not found in database, try fetching from Farcaster via Neynar
    if (userError || !targetUser) {
      console.log('[API] Target user not in database, fetching from Farcaster:', targetFid);

      try {
        const farcasterUser = await neynarAPI.getUserByFid(targetFid);

        if (!farcasterUser) {
          return NextResponse.json(
            { error: 'Target user not found on Farcaster' },
            { status: 404 }
          );
        }

        isExternalUser = true;
        externalUserData = {
          fid: farcasterUser.fid,
          username: farcasterUser.username || `user${farcasterUser.fid}`,
          display_name: farcasterUser.display_name || farcasterUser.username || `User ${farcasterUser.fid}`,
          avatar_url: farcasterUser.pfp_url || '',
          bio: farcasterUser.profile?.bio?.text || '',
        };

        console.log('[API] External Farcaster user found:', externalUserData.username);
      } catch (error) {
        console.error('[API] Error fetching user from Farcaster:', error);
        return NextResponse.json(
          { error: 'Target user not found' },
          { status: 404 }
        );
      }
    }

    // Check for cooldown
    const inCooldown = await isInCooldown(requesterFid, targetFid);
    if (inCooldown) {
      return NextResponse.json(
        { error: 'You have recently declined or cancelled a match with this user. Please wait before requesting again.' },
        { status: 400 }
      );
    }

    // Check for existing active match
    const activeMatch = await hasActiveMatch(requesterFid, targetFid);
    if (activeMatch) {
      return NextResponse.json(
        { error: 'You already have an active match with this user' },
        { status: 400 }
      );
    }

    // Check pending proposal limits
    const requesterPending = await getPendingProposalCount(requesterFid);

    if (requesterPending >= MATCHING_CONFIG.MAX_PROPOSALS_PER_USER) {
      return NextResponse.json(
        { error: `You have reached the maximum of ${MATCHING_CONFIG.MAX_PROPOSALS_PER_USER} pending matches. Please respond to your existing matches first.` },
        { status: 400 }
      );
    }

    // Only check target pending for registered users
    if (!isExternalUser) {
      const targetPending = await getPendingProposalCount(targetFid);

      if (targetPending >= MATCHING_CONFIG.MAX_PROPOSALS_PER_USER) {
        return NextResponse.json(
          { error: `${targetUser.display_name || targetUser.username} has too many pending matches. Please try again later.` },
          { status: 400 }
        );
      }
    }

    // Prepare match data
    const matchData: any = {
      user_a_fid: requesterFid, // Person sending the request
      user_b_fid: targetFid,     // Person receiving the request
      created_by_fid: requesterFid,
      created_by: 'user', // Manual match from user
      status: isExternalUser ? 'pending_external' : 'proposed',
      message: message,
      rationale: {
        score: 0,
        manualMatch: true,
        requestedBy: requesterFid,
        introductionMessage: message,
        isExternalUser: isExternalUser,
      },
      a_accepted: false, // Requester hasn't "accepted" yet (they initiated)
      b_accepted: false, // Target hasn't accepted yet
    };

    // For external users, store their data in the rationale
    if (isExternalUser && externalUserData) {
      matchData.rationale.externalUserData = externalUserData;
    }

    // Create the match
    const { data: match, error: matchError } = await supabase
      .from('matches')
      .insert(matchData)
      .select()
      .single();

    if (matchError) {
      console.error('[API] Error creating manual match:', matchError);
      return NextResponse.json(
        { error: 'Failed to create match request' },
        { status: 500 }
      );
    }

    // Create a system message in the match to show the introduction
    const { error: messageError } = await supabase
      .from('messages')
      .insert({
        match_id: match.id,
        sender_fid: requesterFid,
        content: `Match request: "${message}"`,
        is_system_message: true,
      });

    if (messageError) {
      console.error('[API] Error creating system message:', messageError);
      // Don't fail the request if message creation fails
    }

    // For external users, send Farcaster notification
    if (isExternalUser && externalUserData) {
      console.log('[API] Sending Farcaster notification to external user...');
      console.log('[API] Target:', externalUserData.username, `(FID: ${targetFid})`);

      const notificationResult = await sendMatchRequestNotification(
        externalUserData,
        match.id
      );

      if (notificationResult.success) {
        console.log('[API] ✅ Notification sent successfully, cast hash:', notificationResult.castHash);
      } else {
        console.warn('[API] ⚠️ Failed to send notification:', notificationResult.error);
        // Don't fail the match creation if notification fails - it's a best-effort delivery
      }
    }

    // Check and award match request achievements
    try {
      const achievementsAwarded = await checkMatchRequestAchievements(requesterFid);
      if (achievementsAwarded.length > 0) {
        console.log(`[Achievement] Awarded ${achievementsAwarded.length} match request achievement(s)`);
        achievementsAwarded.forEach(a => {
          if (a.awarded) {
            console.log(`[Achievement] ✅ ${a.code} (+${a.points}pts) - Level ${a.level}`);
          }
        });
      }
    } catch (achError) {
      // Don't fail the request if achievement check fails
      console.error('[Achievement] Error checking match request achievements:', achError);
    }

    // Fetch the full match details
    const { data: matchDetails } = await supabase
      .from('match_details')
      .select('*')
      .eq('id', match.id)
      .single();

    const response: any = { match: matchDetails };

    // Add info message for external users
    if (isExternalUser) {
      response.isExternalUser = true;
      response.message = `Match request sent! ${externalUserData?.display_name || 'This user'} will be notified to join MeetShipper to respond.`;
    }

    return NextResponse.json(response, { status: 201 });
  } catch (error: unknown) {
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
    console.error('[API] Create manual match error:', errorMessage);
    return NextResponse.json(
      { error: 'Failed to create match request' },
      { status: 500 }
    );
  }
}
