import { NextRequest, NextResponse } from 'next/server';
import { getSession } from '@/lib/auth';
import { getServerSupabase } from '@/lib/supabase';
import { isInCooldown, hasActiveMatch, getPendingProposalCount, MATCHING_CONFIG } from '@/lib/services/matching-service';
import { checkMatchRequestAchievements } from '@/lib/services/achievement-service';

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

    // Check if target user exists
    const { data: targetUser, error: userError } = await supabase
      .from('users')
      .select('fid, username, display_name')
      .eq('fid', targetFid)
      .single();

    if (userError || !targetUser) {
      return NextResponse.json(
        { error: 'Target user not found' },
        { status: 404 }
      );
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
    const targetPending = await getPendingProposalCount(targetFid);

    if (requesterPending >= MATCHING_CONFIG.MAX_PROPOSALS_PER_USER) {
      return NextResponse.json(
        { error: `You have reached the maximum of ${MATCHING_CONFIG.MAX_PROPOSALS_PER_USER} pending matches. Please respond to your existing matches first.` },
        { status: 400 }
      );
    }

    if (targetPending >= MATCHING_CONFIG.MAX_PROPOSALS_PER_USER) {
      return NextResponse.json(
        { error: `${targetUser.display_name || targetUser.username} has too many pending matches. Please try again later.` },
        { status: 400 }
      );
    }

    // Create the match
    // In manual matching: requester is user_a, target is user_b
    const { data: match, error: matchError } = await supabase
      .from('matches')
      .insert({
        user_a_fid: requesterFid, // Person sending the request
        user_b_fid: targetFid,     // Person receiving the request
        created_by_fid: requesterFid,
        created_by: 'user', // Manual match from user
        status: 'proposed',
        message: message,
        rationale: {
          score: 0,
          manualMatch: true,
          requestedBy: requesterFid,
          introductionMessage: message,
        },
        a_accepted: false, // Requester hasn't "accepted" yet (they initiated)
        b_accepted: false, // Target hasn't accepted yet
      })
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

    return NextResponse.json({ match: matchDetails }, { status: 201 });
  } catch (error: unknown) {
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
    console.error('[API] Create manual match error:', errorMessage);
    return NextResponse.json(
      { error: 'Failed to create match request' },
      { status: 500 }
    );
  }
}
