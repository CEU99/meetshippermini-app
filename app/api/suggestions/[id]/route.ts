import { NextRequest, NextResponse } from 'next/server';
import { getServerSupabase } from '@/lib/supabase';

/**
 * GET /api/suggestions/[id]
 * Fetch a single match suggestion with user details
 */
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;

    console.log('[API] Fetching suggestion:', id);

    const supabase = getServerSupabase();

    // Fetch suggestion with user details
    const { data: suggestion, error: fetchError } = await supabase
      .from('match_suggestions')
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

    if (fetchError || !suggestion) {
      console.error('[API] Error fetching suggestion:', fetchError);
      return NextResponse.json(
        { error: 'Suggestion not found' },
        { status: 404 }
      );
    }

    // Fetch user details for all three parties
    const { data: users, error: usersError } = await supabase
      .from('users')
      .select('fid, username, display_name, avatar_url, bio')
      .in('fid', [suggestion.created_by_fid, suggestion.user_a_fid, suggestion.user_b_fid]);

    if (usersError) {
      console.error('[API] Error fetching users:', usersError);
      return NextResponse.json(
        { error: 'Failed to fetch user details', details: usersError.message },
        { status: 500 }
      );
    }

    // Map users by FID for easy lookup
    const userMap = new Map(users?.map(u => [u.fid, u]) || []);

    const suggesterData = userMap.get(suggestion.created_by_fid);
    const userAData = userMap.get(suggestion.user_a_fid);
    const userBData = userMap.get(suggestion.user_b_fid);

    if (!suggesterData || !userAData || !userBData) {
      console.error('[API] Missing user data:', {
        hasSuggester: !!suggesterData,
        hasUserA: !!userAData,
        hasUserB: !!userBData,
      });
      return NextResponse.json(
        { error: 'Failed to fetch complete user details' },
        { status: 500 }
      );
    }

    console.log('[API] Suggestion fetched successfully:', {
      id: suggestion.id,
      status: suggestion.status,
      suggester: suggesterData.username,
      userA: userAData.username,
      userB: userBData.username,
    });

    return NextResponse.json({
      success: true,
      suggestion: {
        id: suggestion.id,
        message: suggestion.message,
        status: suggestion.status,
        a_accepted: suggestion.a_accepted,
        b_accepted: suggestion.b_accepted,
        chat_room_id: suggestion.chat_room_id,
        created_at: suggestion.created_at,
        rationale: suggestion.rationale,
        suggester: {
          fid: suggesterData.fid,
          username: suggesterData.username,
          display_name: suggesterData.display_name,
          avatar_url: suggesterData.avatar_url,
          bio: suggesterData.bio,
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
    console.error('[API] Fetch suggestion error (uncaught):', error);
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
    return NextResponse.json(
      {
        error: 'Failed to fetch suggestion',
        message: errorMessage,
      },
      { status: 500 }
    );
  }
}
