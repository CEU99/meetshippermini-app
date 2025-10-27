import { NextRequest, NextResponse } from 'next/server';
import { getSession } from '@/lib/auth';
import { getServerSupabase } from '@/lib/supabase';

/**
 * GET /api/matches/my-suggestions
 * Fetches match suggestions created by the current user
 */
export async function GET(request: NextRequest) {
  try {
    const session = await getSession();
    if (!session) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const supabase = getServerSupabase();

    // Fetch suggestions created by the current user
    const { data: suggestions, error } = await supabase
      .from('match_suggestions')
      .select('*')
      .eq('created_by_fid', session.fid)
      .order('created_at', { ascending: false });

    if (error) {
      console.error('[API /api/matches/my-suggestions] Error:', error);
      console.error('[API /api/matches/my-suggestions] Error details:', {
        code: error.code,
        message: error.message,
        details: error.details,
        hint: error.hint,
      });
      return NextResponse.json(
        { error: 'Failed to fetch your suggestions', details: error.message },
        { status: 500 }
      );
    }

    if (!suggestions || suggestions.length === 0) {
      return NextResponse.json({
        success: true,
        data: [],
        total: 0,
      });
    }

    // Get all unique FIDs
    const allFids = new Set<number>();
    suggestions.forEach((s: any) => {
      allFids.add(s.user_a_fid);
      allFids.add(s.user_b_fid);
    });

    // Fetch user details in bulk
    const { data: users, error: usersError } = await supabase
      .from('users')
      .select('fid, username, display_name, avatar_url')
      .in('fid', Array.from(allFids));

    if (usersError) {
      console.error('[API /api/matches/my-suggestions] Error fetching users:', usersError);
      return NextResponse.json(
        { error: 'Failed to fetch user details', details: usersError.message },
        { status: 500 }
      );
    }

    // Create a map of FID -> User
    const userMap = new Map();
    (users || []).forEach((user: any) => {
      userMap.set(user.fid, user);
    });

    // Map to a cleaner format with user details
    const formattedSuggestions = suggestions.map((s: any) => {
      const userA = userMap.get(s.user_a_fid);
      const userB = userMap.get(s.user_b_fid);

      return {
        id: s.id,
        userA: {
          fid: s.user_a_fid,
          username: userA?.username || '',
          displayName: userA?.display_name || 'Unknown User',
          avatarUrl: userA?.avatar_url || '/default-avatar.png',
        },
        userB: {
          fid: s.user_b_fid,
          username: userB?.username || '',
          displayName: userB?.display_name || 'Unknown User',
          avatarUrl: userB?.avatar_url || '/default-avatar.png',
        },
        message: s.message,
        status: s.status,
        aAccepted: s.a_accepted,
        bAccepted: s.b_accepted,
        chatRoomId: s.chat_room_id,
        createdAt: s.created_at,
        updatedAt: s.updated_at,
      };
    });

    return NextResponse.json({
      success: true,
      data: formattedSuggestions,
      total: formattedSuggestions.length,
    });
  } catch (error: any) {
    console.error('[API /api/matches/my-suggestions] Unexpected error:', error);
    return NextResponse.json(
      { error: 'Internal server error', details: error.message },
      { status: 500 }
    );
  }
}
