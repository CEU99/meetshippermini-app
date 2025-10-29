import { NextRequest, NextResponse } from 'next/server';
import { getSession } from '@/lib/auth';
import { getServerSupabase } from '@/lib/supabase';
import { getCooldownExpiry } from '@/lib/services/matching-service';

/**
 * POST /api/matches/suggestions
 * Create a new match suggestion between two users
 */
export async function POST(request: NextRequest) {
  try {
    const session = await getSession();
    if (!session) {
      console.error('[API] Suggestions: No session found');
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const body = await request.json();
    const { userAFid, userBFid, message } = body;

    console.log('[API] Creating match suggestion:', {
      suggesterFid: session.fid,
      userAFid,
      userBFid,
      hasMessage: !!message,
    });

    // Validation
    if (!userAFid || !userBFid || !message) {
      return NextResponse.json(
        { error: 'Missing required fields: userAFid, userBFid, and message are required' },
        { status: 400 }
      );
    }

    // Validate numeric FIDs
    if (typeof userAFid !== 'number' || typeof userBFid !== 'number') {
      return NextResponse.json(
        { error: 'Invalid FID format: userAFid and userBFid must be numeric' },
        { status: 400 }
      );
    }

    if (isNaN(userAFid) || isNaN(userBFid) || userAFid <= 0 || userBFid <= 0) {
      return NextResponse.json(
        { error: 'Invalid FID: FIDs must be positive numbers' },
        { status: 400 }
      );
    }

    // Validate A ≠ B
    if (userAFid === userBFid) {
      return NextResponse.json(
        { error: 'User A and User B must be different people' },
        { status: 400 }
      );
    }

    // Validate message length (20-100 characters)
    const trimmedMessage = message.trim();
    if (trimmedMessage.length < 20) {
      return NextResponse.json(
        { error: 'Message must be at least 20 characters' },
        { status: 400 }
      );
    }

    if (trimmedMessage.length > 100) {
      return NextResponse.json(
        { error: 'Message must not exceed 100 characters' },
        { status: 400 }
      );
    }

    if (userAFid === session.fid || userBFid === session.fid) {
      return NextResponse.json(
        { error: 'Cannot suggest a match involving yourself' },
        { status: 400 }
      );
    }

    const supabase = getServerSupabase();

    // Check if both users exist
    const { data: usersCheck, error: usersError } = await supabase
      .from('users')
      .select('fid')
      .in('fid', [userAFid, userBFid]);

    if (usersError) {
      console.error('[API] Error checking users:', usersError);
      return NextResponse.json(
        { error: 'Failed to validate users', details: usersError.message },
        { status: 500 }
      );
    }

    if (!usersCheck || usersCheck.length !== 2) {
      return NextResponse.json(
        { error: 'One or both users not found in the system' },
        { status: 404 }
      );
    }

    // Check cooldown
    console.log('[API] Checking suggestion cooldown...');
    const { data: cooldownCheck } = await supabase.rpc(
      'check_suggestion_cooldown',
      {
        p_user_a_fid: userAFid,
        p_user_b_fid: userBFid,
      }
    );

    if (cooldownCheck === false) {
      console.log('[API] ❌ Suggestion is in cooldown period');

      // Get cooldown expiry time for user feedback
      const cooldownExpiry = await getCooldownExpiry(userAFid, userBFid);

      if (cooldownExpiry) {
        const now = new Date();
        const hoursRemaining = Math.ceil(
          (cooldownExpiry.getTime() - now.getTime()) / (1000 * 60 * 60)
        );
        const daysRemaining = Math.ceil(hoursRemaining / 24);

        console.log('[API] Cooldown expires at:', cooldownExpiry.toISOString());
        console.log('[API] Hours remaining:', hoursRemaining);

        return NextResponse.json(
          {
            error: 'A suggestion between these users was recently declined.',
            cooldownExpiry: cooldownExpiry.toISOString(),
            hoursRemaining,
            daysRemaining,
          },
          { status: 400 }
        );
      }

      // Fallback if we can't get expiry time
      return NextResponse.json(
        {
          error: 'A suggestion between these users was recently declined. Please wait before suggesting again.',
        },
        { status: 400 }
      );
    }
    console.log('[API] ✅ No cooldown for suggestion');

    // Create the suggestion
    const { data: suggestion, error: createError } = await supabase
      .from('match_suggestions')
      .insert({
        created_by_fid: session.fid,
        user_a_fid: userAFid,
        user_b_fid: userBFid,
        message: trimmedMessage,
        status: 'proposed',
      })
      .select()
      .single();

    if (createError) {
      console.error('[API] Error creating suggestion:', createError);
      console.error('[API] Error code:', createError.code);
      console.error('[API] Error details:', createError.details);
      console.error('[API] Error hint:', createError.hint);
      console.error('[API] Error message:', createError.message);

      // Check for duplicate suggestion
      if (createError.code === '23505') {
        return NextResponse.json(
          {
            error: 'Duplicate suggestion',
            message:
              'A pending suggestion already exists between these users',
          },
          { status: 409 }
        );
      }

      // Check for RLS policy violation
      if (createError.code === '42501' || createError.message?.includes('policy')) {
        return NextResponse.json(
          {
            error: 'Permission denied',
            message: 'Unable to create suggestion due to access restrictions',
            details: createError.message,
          },
          { status: 403 }
        );
      }

      return NextResponse.json(
        {
          error: 'Failed to create suggestion',
          details: createError.message,
          code: createError.code,
        },
        { status: 500 }
      );
    }

    console.log('[API] Match suggestion created successfully:', suggestion.id);

    // TODO: Send notifications to both users (implement later with your notification system)
    // await sendNotification(userAFid, 'new_suggestion', { suggestionId: suggestion.id });
    // await sendNotification(userBFid, 'new_suggestion', { suggestionId: suggestion.id });

    return NextResponse.json(
      {
        success: true,
        suggestion: {
          id: suggestion.id,
          status: suggestion.status,
          created_at: suggestion.created_at,
        },
        message:
          'Match suggestion created successfully! Both users will see it in their inbox.',
      },
      { status: 201 }
    );
  } catch (error) {
    console.error('[API] Suggestions error (uncaught):', error);
    const errorMessage =
      error instanceof Error ? error.message : 'Unknown error';
    return NextResponse.json(
      {
        error: 'Failed to create match suggestion',
        message: errorMessage,
      },
      { status: 500 }
    );
  }
}
