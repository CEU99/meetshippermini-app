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

    // Get scope filter from query params
    const { searchParams } = new URL(request.url);
    const scope = searchParams.get('scope');

    // Get matches where user is involved (as participant or creator)
    let query = supabase
      .from('match_details')
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
      console.error('Error fetching matches:', error);
      return NextResponse.json(
        { error: 'Failed to fetch matches' },
        { status: 500 }
      );
    }

    return NextResponse.json({ matches: matches || [] });
  } catch (error) {
    console.error('Get matches error:', error);
    return NextResponse.json(
      { error: 'Failed to fetch matches' },
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
      console.error('Error creating match:', error);
      return NextResponse.json(
        { error: 'Failed to create match' },
        { status: 500 }
      );
    }

    // Fetch the full match details with user info
    const { data: matchDetails } = await supabase
      .from('match_details')
      .select('*')
      .eq('id', match.id)
      .single();

    return NextResponse.json({ match: matchDetails }, { status: 201 });
  } catch (error) {
    console.error('Create match error:', error);
    return NextResponse.json(
      { error: 'Failed to create match' },
      { status: 500 }
    );
  }
}
