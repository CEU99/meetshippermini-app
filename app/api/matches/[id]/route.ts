import { NextRequest, NextResponse } from 'next/server';
import { getSession } from '@/lib/auth';
import { getServerSupabase } from '@/lib/supabase';

// GET /api/matches/[id] - Get a specific match
// Supports both authenticated and public (external) access
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const supabase = getServerSupabase();

    console.log('[API] Fetching match:', id);

    // Fetch match with basic details
    const { data: match, error: fetchError } = await supabase
      .from('matches')
      .select(`
        id,
        created_by_fid,
        user_a_fid,
        user_b_fid,
        message,
        status,
        a_accepted,
        b_accepted,
        chat_room_id,
        created_at,
        rationale
      `)
      .eq('id', id)
      .single();

    if (fetchError || !match) {
      console.error('[API] Error fetching match:', fetchError);
      return NextResponse.json({ error: 'Match not found' }, { status: 404 });
    }

    // Fetch user details for all three parties
    const { data: users, error: usersError } = await supabase
      .from('users')
      .select('fid, username, display_name, avatar_url, bio')
      .in('fid', [match.created_by_fid, match.user_a_fid, match.user_b_fid]);

    if (usersError) {
      console.error('[API] Error fetching users:', usersError);
      return NextResponse.json(
        { error: 'Failed to fetch user details', details: usersError.message },
        { status: 500 }
      );
    }

    // Map users by FID for easy lookup
    const userMap = new Map(users?.map(u => [u.fid, u]) || []);

    const creatorData = userMap.get(match.created_by_fid);
    const userAData = userMap.get(match.user_a_fid);
    const userBData = userMap.get(match.user_b_fid);

    if (!creatorData || !userAData || !userBData) {
      console.error('[API] Missing user data:', {
        hasCreator: !!creatorData,
        hasUserA: !!userAData,
        hasUserB: !!userBData,
      });
      return NextResponse.json(
        { error: 'Failed to fetch complete user details' },
        { status: 500 }
      );
    }

    console.log('[API] Match fetched successfully:', {
      id: match.id,
      status: match.status,
      creator: creatorData.username,
      userA: userAData.username,
      userB: userBData.username,
    });

    // Optional session check for additional access control (but don't block external users)
    const session = await getSession();
    if (session) {
      const userFid = session.fid;
      const hasAccess =
        match.user_a_fid === userFid ||
        match.user_b_fid === userFid ||
        match.created_by_fid === userFid;

      console.log('[API] Authenticated user access:', { userFid, hasAccess });
    } else {
      console.log('[API] Unauthenticated access (external user view)');
    }

    return NextResponse.json({
      success: true,
      match: {
        id: match.id,
        message: match.message,
        status: match.status,
        a_accepted: match.a_accepted,
        b_accepted: match.b_accepted,
        chat_room_id: match.chat_room_id,
        created_at: match.created_at,
        rationale: match.rationale,
        creator: {
          fid: creatorData.fid,
          username: creatorData.username,
          display_name: creatorData.display_name,
          avatar_url: creatorData.avatar_url,
          bio: creatorData.bio,
        },
        user_a: {
          fid: userAData.fid,
          username: userAData.username,
          display_name: userAData.display_name,
          avatar_url: userAData.avatar_url,
          bio: userAData.bio,
        },
        user_b: {
          fid: userBData.fid,
          username: userBData.username,
          display_name: userBData.display_name,
          avatar_url: userBData.avatar_url,
          bio: userBData.bio,
        },
      },
    });
  } catch (error) {
    console.error('[API] Get match error:', error);
    return NextResponse.json(
      { error: 'Failed to fetch match' },
      { status: 500 }
    );
  }
}

// PATCH /api/matches/[id] - Update match (accept/decline)
export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const session = await getSession();
    if (!session) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { id } = await params;
    const body = await request.json();
    const { action } = body; // 'accept' or 'decline'

    if (!action || !['accept', 'decline'].includes(action)) {
      return NextResponse.json(
        { error: 'Invalid action. Must be "accept" or "decline"' },
        { status: 400 }
      );
    }

    const supabase = getServerSupabase();
    const userFid = session.fid;

    // Get the match first
    const { data: match, error: fetchError } = await supabase
      .from('matches')
      .select('*')
      .eq('id', id)
      .single();

    if (fetchError || !match) {
      return NextResponse.json({ error: 'Match not found' }, { status: 404 });
    }

    // Determine if user is user_a or user_b
    const updateData: Record<string, boolean> = {};

    if (match.user_a_fid === userFid) {
      if (action === 'accept') {
        updateData.a_accepted = true;
      } else {
        updateData.status = 'declined';
      }
    } else if (match.user_b_fid === userFid) {
      if (action === 'accept') {
        updateData.b_accepted = true;
      } else {
        updateData.status = 'declined';
      }
    } else {
      return NextResponse.json(
        { error: 'You are not a participant in this match' },
        { status: 403 }
      );
    }

    // Update the match
    const { error: updateError } = await supabase
      .from('matches')
      .update(updateData)
      .eq('id', id)
      .select()
      .single();

    if (updateError) {
      console.error('Error updating match:', updateError);
      return NextResponse.json(
        { error: 'Failed to update match' },
        { status: 500 }
      );
    }

    // Fetch the full match details
    const { data: matchDetails } = await supabase
      .from('match_details')
      .select('*')
      .eq('id', id)
      .single();

    return NextResponse.json({ match: matchDetails });
  } catch (error) {
    console.error('Update match error:', error);
    return NextResponse.json(
      { error: 'Failed to update match' },
      { status: 500 }
    );
  }
}

// DELETE /api/matches/[id] - Cancel a match (only creator can do this)
export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const session = await getSession();
    if (!session) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { id } = await params;
    const supabase = getServerSupabase();

    // Get the match first
    const { data: match, error: fetchError } = await supabase
      .from('matches')
      .select('*')
      .eq('id', id)
      .single();

    if (fetchError || !match) {
      return NextResponse.json({ error: 'Match not found' }, { status: 404 });
    }

    // Only creator can cancel
    if (match.created_by_fid !== session.fid) {
      return NextResponse.json(
        { error: 'Only the match creator can cancel it' },
        { status: 403 }
      );
    }

    // Update status to cancelled (don't actually delete to preserve history)
    const { error: updateError } = await supabase
      .from('matches')
      .update({ status: 'cancelled' })
      .eq('id', id);

    if (updateError) {
      console.error('Error cancelling match:', updateError);
      return NextResponse.json(
        { error: 'Failed to cancel match' },
        { status: 500 }
      );
    }

    return NextResponse.json({ success: true });
  } catch (error) {
    console.error('Delete match error:', error);
    return NextResponse.json(
      { error: 'Failed to cancel match' },
      { status: 500 }
    );
  }
}
