import { NextRequest, NextResponse } from 'next/server';
import { getSession } from '@/lib/auth';
import { getServerSupabase } from '@/lib/supabase';

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

    if (userAFid === userBFid) {
      return NextResponse.json(
        { error: 'Cannot suggest a match between the same user' },
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
    const { data: cooldownCheck } = await supabase.rpc(
      'check_suggestion_cooldown',
      {
        p_user_a_fid: userAFid,
        p_user_b_fid: userBFid,
      }
    );

    if (cooldownCheck === false) {
      return NextResponse.json(
        {
          error: 'Cooldown active',
          message:
            'A suggestion between these users was recently declined. Please wait 7 days before suggesting again.',
        },
        { status: 429 }
      );
    }

    // Create the suggestion
    const { data: suggestion, error: createError } = await supabase
      .from('match_suggestions')
      .insert({
        created_by_fid: session.fid,
        user_a_fid: userAFid,
        user_b_fid: userBFid,
        message: message.trim(),
        status: 'proposed',
      })
      .select()
      .single();

    if (createError) {
      console.error('[API] Error creating suggestion:', createError);

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

      return NextResponse.json(
        {
          error: 'Failed to create suggestion',
          details: createError.message,
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
