import { NextRequest, NextResponse } from 'next/server';
import { getSession } from '@/lib/auth';
import { getServerSupabase } from '@/lib/supabase';

/**
 * GET /api/inbox/suggestions
 * Fetch all suggestions where current user is a participant
 * IMPORTANT: Does NOT reveal suggester identity
 */
export async function GET(request: NextRequest) {
  try {
    const session = await getSession();
    if (!session) {
      console.error('[API] Inbox Suggestions: No session found');
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const supabase = getServerSupabase();
    const userFid = session.fid;

    console.log('[API] Fetching suggestions for user:', userFid);

    // Fetch suggestions where user is participant
    const { data: suggestions, error } = await supabase
      .from('match_suggestions')
      .select('*')
      .or(`user_a_fid.eq.${userFid},user_b_fid.eq.${userFid}`)
      .order('created_at', { ascending: false });

    if (error) {
      console.error('[API] Error fetching suggestions:', error);
      console.error('[API] Error details:', {
        code: error.code,
        message: error.message,
        details: error.details,
        hint: error.hint,
      });
      return NextResponse.json(
        {
          error: 'Failed to fetch suggestions',
          details: error.message,
        },
        { status: 500 }
      );
    }

    if (!suggestions || suggestions.length === 0) {
      console.log('[API] No suggestions found for user:', userFid);
      return NextResponse.json({
        success: true,
        suggestions: [],
        total: 0,
      });
    }

    // Get all unique FIDs for the "other user" in each suggestion
    const otherUserFids = new Set<number>();
    suggestions.forEach((s: any) => {
      const isUserA = s.user_a_fid === userFid;
      otherUserFids.add(isUserA ? s.user_b_fid : s.user_a_fid);
    });

    // Fetch user details in bulk
    const { data: users, error: usersError } = await supabase
      .from('users')
      .select('fid, username, display_name, avatar_url')
      .in('fid', Array.from(otherUserFids));

    if (usersError) {
      console.error('[API] Error fetching user details:', usersError);
      return NextResponse.json(
        {
          error: 'Failed to fetch user details',
          details: usersError.message,
        },
        { status: 500 }
      );
    }

    // Create a map of FID -> User
    const userMap = new Map();
    (users || []).forEach((user: any) => {
      userMap.set(user.fid, user);
    });

    // Transform suggestions to hide suggester identity
    // and show only the OTHER participant to each user
    const transformedSuggestions = suggestions.map((suggestion: any) => {
      const isUserA = suggestion.user_a_fid === userFid;
      const otherUserFid = isUserA ? suggestion.user_b_fid : suggestion.user_a_fid;
      const otherUserData = userMap.get(otherUserFid);

      // Determine which participant data to show (the OTHER user)
      const otherUser = {
        fid: otherUserFid,
        username: otherUserData?.username || '',
        displayName: otherUserData?.display_name || 'Unknown User',
        avatarUrl: otherUserData?.avatar_url || '/default-avatar.png',
      };

      return {
        id: suggestion.id,
        message: suggestion.message,
        status: suggestion.status,
        myAcceptance: isUserA
          ? suggestion.a_accepted
          : suggestion.b_accepted,
        otherAcceptance: isUserA
          ? suggestion.b_accepted
          : suggestion.a_accepted,
        otherUser,
        chatRoomId: suggestion.chat_room_id,
        createdAt: suggestion.created_at,
        updatedAt: suggestion.updated_at,
        // Do NOT include created_by_fid (privacy!)
      };
    });

    console.log(
      `[API] Returning ${transformedSuggestions.length} suggestions for user ${userFid}`
    );

    return NextResponse.json({
      success: true,
      suggestions: transformedSuggestions,
      total: transformedSuggestions.length,
    });
  } catch (error) {
    console.error('[API] Inbox suggestions error (uncaught):', error);
    const errorMessage =
      error instanceof Error ? error.message : 'Unknown error';
    return NextResponse.json(
      {
        error: 'Failed to fetch suggestions',
        message: errorMessage,
      },
      { status: 500 }
    );
  }
}
