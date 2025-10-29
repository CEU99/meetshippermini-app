import { NextRequest, NextResponse } from 'next/server';
import { getSession } from '@/lib/auth';
import { getServerSupabase } from '@/lib/supabase';
import { isInCooldown, getCooldownExpiry, hasActiveMatch, getPendingProposalCount, MATCHING_CONFIG } from '@/lib/services/matching-service';
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
    console.log('[API] === Create Manual Match Request Started ===');

    const session = await getSession();
    if (!session) {
      console.log('[API] ❌ No session found');
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }
    console.log('[API] ✅ Session valid, requester FID:', session.fid);

    const body = await request.json();
    const { targetFid, introductionMessage } = body;
    console.log('[API] Request body:', { targetFid, messageLength: introductionMessage?.length });

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
    console.log('[API] 🔍 Looking up target user FID:', targetFid);
    const { data: targetUser, error: userError } = await supabase
      .from('users')
      .select('fid, username, display_name, avatar_url, bio, has_joined_meetshipper')
      .eq('fid', targetFid)
      .single();

    let isExternalUser = false;
    let externalUserData = null;

    if (userError) {
      console.log('[API] User not in database, will check Farcaster. Error:', userError.message);
    } else {
      console.log('[API] ✅ Target user found in database:', targetUser.username);
      console.log('[API] Has joined MeetShipper:', targetUser.has_joined_meetshipper);

      // If user exists but hasn't joined MeetShipper, treat as external
      if (!targetUser.has_joined_meetshipper) {
        console.log('[API] User exists in DB but has not joined MeetShipper - treating as external');
        isExternalUser = true;
        externalUserData = {
          fid: targetUser.fid,
          username: targetUser.username,
          display_name: targetUser.display_name,
          avatar_url: targetUser.avatar_url || '',
          bio: targetUser.bio || '',
        };
      }
    }

    // If user not found in database OR is marked as external, fetch from Farcaster
    // (we skip Farcaster fetch if they're already in DB with their data as external)
    if ((userError || !targetUser) && !isExternalUser) {
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

        // Insert minimal record for external user to satisfy foreign key constraint
        // Mark as has_joined_meetshipper = false to indicate they haven't logged in
        console.log('[API] 💾 Creating minimal record for external user...');
        const { error: insertError } = await supabase
          .from('users')
          .upsert({
            fid: externalUserData.fid,
            username: externalUserData.username,
            display_name: externalUserData.display_name,
            avatar_url: externalUserData.avatar_url,
            bio: externalUserData.bio,
            has_joined_meetshipper: false, // Mark as external-only user
            updated_at: new Date().toISOString(),
          }, {
            onConflict: 'fid',
            ignoreDuplicates: false, // Update if user already exists
          });

        if (insertError) {
          console.error('[API] ❌ Error creating external user record:', insertError);
          return NextResponse.json(
            { error: 'Failed to register external user' },
            { status: 500 }
          );
        }
        console.log('[API] ✅ External user record created (has_joined_meetshipper = false)');
      } catch (error) {
        console.error('[API] Error fetching user from Farcaster:', error);
        return NextResponse.json(
          { error: 'Target user not found' },
          { status: 404 }
        );
      }
    }

    // Check for cooldown
    console.log('[API] 🔍 Checking cooldown...');
    const inCooldown = await isInCooldown(requesterFid, targetFid);
    if (inCooldown) {
      console.log('[API] ❌ User is in cooldown period');

      // Get cooldown expiry time for user feedback
      const cooldownExpiry = await getCooldownExpiry(requesterFid, targetFid);

      if (cooldownExpiry) {
        const now = new Date();
        const hoursRemaining = Math.ceil((cooldownExpiry.getTime() - now.getTime()) / (1000 * 60 * 60));
        const daysRemaining = Math.ceil(hoursRemaining / 24);

        console.log('[API] Cooldown expires at:', cooldownExpiry.toISOString());
        console.log('[API] Hours remaining:', hoursRemaining);

        return NextResponse.json(
          {
            error: 'You have recently declined or cancelled a match with this user.',
            cooldownExpiry: cooldownExpiry.toISOString(),
            hoursRemaining,
            daysRemaining,
          },
          { status: 400 }
        );
      }

      // Fallback if we can't get expiry time
      return NextResponse.json(
        { error: 'You have recently declined or cancelled a match with this user. Please wait before requesting again.' },
        { status: 400 }
      );
    }
    console.log('[API] ✅ No cooldown');

    // Check for existing active match
    console.log('[API] 🔍 Checking for active match...');
    const activeMatch = await hasActiveMatch(requesterFid, targetFid);
    if (activeMatch) {
      console.log('[API] ❌ Active match already exists');
      return NextResponse.json(
        { error: 'You already have an active match with this user' },
        { status: 400 }
      );
    }
    console.log('[API] ✅ No active match');

    // Check pending proposal limits
    console.log('[API] 🔍 Checking pending proposal limits...');
    const requesterPending = await getPendingProposalCount(requesterFid);
    console.log('[API] Requester pending count:', requesterPending);

    if (requesterPending >= MATCHING_CONFIG.MAX_PROPOSALS_PER_USER) {
      console.log('[API] ❌ Requester has too many pending proposals');
      return NextResponse.json(
        { error: `You have reached the maximum of ${MATCHING_CONFIG.MAX_PROPOSALS_PER_USER} pending matches. Please respond to your existing matches first.` },
        { status: 400 }
      );
    }
    console.log('[API] ✅ Requester pending count OK');

    // Only check target pending for registered users
    if (!isExternalUser) {
      const targetPending = await getPendingProposalCount(targetFid);
      console.log('[API] Target pending count:', targetPending);

      if (targetPending >= MATCHING_CONFIG.MAX_PROPOSALS_PER_USER) {
        console.log('[API] ❌ Target has too many pending proposals');
        return NextResponse.json(
          { error: `${targetUser.display_name || targetUser.username} has too many pending matches. Please try again later.` },
          { status: 400 }
        );
      }
      console.log('[API] ✅ Target pending count OK');
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
    console.log('[API] 💾 Creating match in database...');
    console.log('[API] Match data:', JSON.stringify(matchData, null, 2));
    const { data: match, error: matchError } = await supabase
      .from('matches')
      .insert(matchData)
      .select()
      .single();

    if (matchError) {
      console.error('[API] ❌ Database error creating match:');
      console.error('[API] Error code:', matchError.code);
      console.error('[API] Error message:', matchError.message);
      console.error('[API] Error details:', matchError.details);
      console.error('[API] Error hint:', matchError.hint);
      return NextResponse.json(
        { error: `Failed to create match request: ${matchError.message}` },
        { status: 500 }
      );
    }
    console.log('[API] ✅ Match created successfully, ID:', match.id);

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
      console.log('[API] Using signer from session:', session.signerUuid ? 'delegated' : 'global');

      const notificationResult = await sendMatchRequestNotification(
        externalUserData,
        match.id,
        session.signerUuid // Pass user's delegated signer if available
      );

      if (notificationResult.success) {
        console.log('[API] ✅ Notification sent successfully');
        console.log('[API] Cast hash:', notificationResult.castHash);
        console.log('[API] Signer used:', notificationResult.signerUsed);
        console.log('[API] Signer status:', notificationResult.signerStatus);
      } else {
        console.warn('[API] ⚠️ Failed to send notification:', notificationResult.error);
        console.warn('[API] Signer used:', notificationResult.signerUsed);
        console.warn('[API] Signer status:', notificationResult.signerStatus);
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

    console.log('[API] ✅ Match request completed successfully');
    return NextResponse.json(response, { status: 201 });
  } catch (error: unknown) {
    console.error('[API] ❌ Unexpected error in create manual match:');
    console.error('[API] Error type:', error?.constructor?.name);
    console.error('[API] Error:', error);

    if (error instanceof Error) {
      console.error('[API] Error message:', error.message);
      console.error('[API] Error stack:', error.stack);
      return NextResponse.json(
        { error: `Failed to create match request: ${error.message}` },
        { status: 500 }
      );
    }

    return NextResponse.json(
      { error: 'Failed to create match request: Unknown error' },
      { status: 500 }
    );
  }
}
