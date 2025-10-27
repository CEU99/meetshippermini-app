import { NextRequest, NextResponse } from 'next/server';
import { getSession } from '@/lib/auth';
import { getServerSupabase } from '@/lib/supabase';

// GET /api/matches - Get all matches for the authenticated user
// Optional query params: ?scope=inbox (filters by status categories)
export async function GET(request: NextRequest) {
  try {
    const session = await getSession();
    if (!session) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const supabase = getServerSupabase();
    const userFid = session.fid;

    console.log('[API /api/matches] Fetching matches for user:', userFid);

    // Get scope filter from query params
    const { searchParams } = new URL(request.url);
    const scope = searchParams.get('scope');

    console.log('[API /api/matches] Scope filter:', scope);

    // Step 1: Get matches where user is involved (as participant or creator)
    // Query from 'matches' table instead of 'match_details' view
    let query = supabase
      .from('matches')
      .select('*')
      .or(`user_a_fid.eq.${userFid},user_b_fid.eq.${userFid},created_by_fid.eq.${userFid}`);

    // Apply scope filters
    if (scope === 'inbox') {
      // All inbox-relevant matches (pending, waiting, accepted, declined)
      query = query.in('status', [
        'proposed',
        'pending',
        'accepted_by_a',
        'accepted_by_b',
        'accepted',
        'declined',
      ]);
    } else if (scope === 'pending') {
      // Waiting for my response - matches where I haven't accepted yet
      const pendingConditions = [
        `and(user_a_fid.eq.${userFid},a_accepted.eq.false)`,
        `and(user_b_fid.eq.${userFid},b_accepted.eq.false)`
      ];

      query = query
        .or(pendingConditions.join(','))
        .in('status', ['proposed', 'pending', 'accepted_by_a', 'accepted_by_b']);

    } else if (scope === 'awaiting') {
      // I accepted, waiting for other party - matches where I accepted but they haven't
      const awaitingConditions = [
        `and(user_a_fid.eq.${userFid},a_accepted.eq.true,b_accepted.eq.false)`,
        `and(user_b_fid.eq.${userFid},b_accepted.eq.true,a_accepted.eq.false)`
      ];

      query = query
        .or(awaitingConditions.join(','))
        .in('status', ['accepted_by_a', 'accepted_by_b', 'proposed', 'pending']);

    } else if (scope === 'accepted') {
      // Both accepted
      query = query.eq('status', 'accepted');
    } else if (scope === 'declined') {
      query = query.eq('status', 'declined');
    } else if (scope === 'completed') {
      // Completed meetings
      query = query.eq('status', 'completed');
    }

    query = query.order('created_at', { ascending: false });

    const { data: matches, error } = await query;

    if (error) {
      console.error('[API /api/matches] Error fetching matches:', error);
      console.error('[API /api/matches] Error details:', {
        code: error.code,
        message: error.message,
        details: error.details,
        hint: error.hint,
      });
      return NextResponse.json(
        { error: 'Failed to fetch matches', details: error.message },
        { status: 500 }
      );
    }

    if (!matches || matches.length === 0) {
      console.log('[API /api/matches] No matches found for user:', userFid);
      return NextResponse.json({ matches: [] });
    }

    console.log(`[API /api/matches] Found ${matches.length} matches`);

    // Step 2: Get all unique FIDs from matches
    const allFids = new Set<number>();
    matches.forEach((match: any) => {
      allFids.add(match.user_a_fid);
      allFids.add(match.user_b_fid);
      if (match.created_by_fid) {
        allFids.add(match.created_by_fid);
      }
    });

    console.log(`[API /api/matches] Fetching details for ${allFids.size} unique users`);

    // Step 3: Fetch user details in bulk
    const { data: users, error: usersError } = await supabase
      .from('users')
      .select('fid, username, display_name, avatar_url')
      .in('fid', Array.from(allFids));

    if (usersError) {
      console.error('[API /api/matches] Error fetching user details:', usersError);
      console.error('[API /api/matches] Error details:', {
        code: usersError.code,
        message: usersError.message,
        details: usersError.details,
        hint: usersError.hint,
      });
      return NextResponse.json(
        { error: 'Failed to fetch user details', details: usersError.message },
        { status: 500 }
      );
    }

    // Step 4: Create a map of FID -> User
    const userMap = new Map();
    (users || []).forEach((user: any) => {
      userMap.set(user.fid, user);
    });

    // Step 5: Transform matches to include user details
    const matchesWithDetails = matches.map((match: any) => {
      const userA = userMap.get(match.user_a_fid);
      const userB = userMap.get(match.user_b_fid);
      const creator = match.created_by_fid ? userMap.get(match.created_by_fid) : null;

      return {
        ...match,
        // Add user details
        user_a_username: userA?.username || '',
        user_a_display_name: userA?.display_name || 'Unknown User',
        user_a_avatar_url: userA?.avatar_url || '/default-avatar.png',
        user_b_username: userB?.username || '',
        user_b_display_name: userB?.display_name || 'Unknown User',
        user_b_avatar_url: userB?.avatar_url || '/default-avatar.png',
        created_by_username: creator?.username || '',
        created_by_display_name: creator?.display_name || 'Unknown',
        created_by_avatar_url: creator?.avatar_url || '/default-avatar.png',
      };
    });

    console.log(`[API /api/matches] Returning ${matchesWithDetails.length} matches with user details`);

    return NextResponse.json({ matches: matchesWithDetails });
  } catch (error) {
    console.error('[API /api/matches] Unexpected error:', error);
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
    return NextResponse.json(
      { error: 'Failed to fetch matches', message: errorMessage },
      { status: 500 }
    );
  }
}

// POST /api/matches - Create a new match
export async function POST(request: NextRequest) {
  try {
    const session = await getSession();
    if (!session) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const body = await request.json();
    const { userAFid, userBFid, message } = body;

    // Validate input
    if (!userAFid || !userBFid) {
      return NextResponse.json(
        { error: 'Missing required fields: userAFid and userBFid' },
        { status: 400 }
      );
    }

    if (userAFid === userBFid) {
      return NextResponse.json(
        { error: 'Cannot match a user with themselves' },
        { status: 400 }
      );
    }

    const supabase = getServerSupabase();

    // Check if users exist in the database
    const { data: users } = await supabase
      .from('users')
      .select('fid')
      .in('fid', [userAFid, userBFid]);

    if (!users || users.length < 2) {
      return NextResponse.json(
        { error: 'One or both users not found in the system' },
        { status: 404 }
      );
    }

    // Create the match
    const { data: match, error } = await supabase
      .from('matches')
      .insert({
        user_a_fid: userAFid,
        user_b_fid: userBFid,
        created_by_fid: session.fid,
        created_by: `admin:${session.fid}`,
        status: 'proposed',
        message: message || null,
        rationale: {
          traitOverlap: [],
          bioKeywords: [],
          score: 0,
          manualMatch: true,
        },
        a_accepted: false,
        b_accepted: false,
      })
      .select()
      .single();

    if (error) {
      console.error('[API /api/matches POST] Error creating match:', error);
      console.error('[API /api/matches POST] Error details:', {
        code: error.code,
        message: error.message,
        details: error.details,
        hint: error.hint,
      });
      return NextResponse.json(
        { error: 'Failed to create match', details: error.message },
        { status: 500 }
      );
    }

    console.log('[API /api/matches POST] Match created with ID:', match.id);

    // Fetch user details for the match
    const { data: matchUsers } = await supabase
      .from('users')
      .select('fid, username, display_name, avatar_url')
      .in('fid', [match.user_a_fid, match.user_b_fid, match.created_by_fid]);

    const userMap = new Map();
    (matchUsers || []).forEach((user: any) => {
      userMap.set(user.fid, user);
    });

    const userA = userMap.get(match.user_a_fid);
    const userB = userMap.get(match.user_b_fid);
    const creator = userMap.get(match.created_by_fid);

    const matchWithDetails = {
      ...match,
      user_a_username: userA?.username || '',
      user_a_display_name: userA?.display_name || 'Unknown User',
      user_a_avatar_url: userA?.avatar_url || '/default-avatar.png',
      user_b_username: userB?.username || '',
      user_b_display_name: userB?.display_name || 'Unknown User',
      user_b_avatar_url: userB?.avatar_url || '/default-avatar.png',
      created_by_username: creator?.username || '',
      created_by_display_name: creator?.display_name || 'Unknown',
      created_by_avatar_url: creator?.avatar_url || '/default-avatar.png',
    };

    console.log('[API /api/matches POST] Returning match with user details');

    return NextResponse.json({ match: matchWithDetails }, { status: 201 });
  } catch (error) {
    console.error('[API /api/matches POST] Unexpected error:', error);
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
    return NextResponse.json(
      { error: 'Failed to create match', message: errorMessage },
      { status: 500 }
    );
  }
}
