import { NextRequest, NextResponse } from 'next/server';
import { getSession } from '@/lib/auth';
import { getServerSupabase } from '@/lib/supabase';

// GET /api/matches/[id] - Get a specific match
export async function GET(
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

    const { data: match, error } = await supabase
      .from('match_details')
      .select('*')
      .eq('id', id)
      .single();

    if (error || !match) {
      return NextResponse.json({ error: 'Match not found' }, { status: 404 });
    }

    // Check if user has access to this match
    const userFid = session.fid;
    const hasAccess =
      match.user_a_fid === userFid ||
      match.user_b_fid === userFid ||
      match.created_by_fid === userFid;

    if (!hasAccess) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 });
    }

    return NextResponse.json({ match });
  } catch (error) {
    console.error('Get match error:', error);
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
    let updateData: any = {};

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
    const { data: updatedMatch, error: updateError } = await supabase
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
