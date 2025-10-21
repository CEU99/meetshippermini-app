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
    // Using the view for easier access to participant details
    const { data: suggestions, error } = await supabase
      .from('match_suggestions_with_details')
      .select('*')
      .or(`user_a_fid.eq.${userFid},user_b_fid.eq.${userFid}`)
      .order('created_at', { ascending: false });

    if (error) {
      console.error('[API] Error fetching suggestions:', error);
      return NextResponse.json(
        {
          error: 'Failed to fetch suggestions',
          details: error.message,
        },
        { status: 500 }
      );
    }

    // Transform suggestions to hide suggester identity
    // and show only the OTHER participant to each user
    const transformedSuggestions = (suggestions || []).map((suggestion) => {
      const isUserA = suggestion.user_a_fid === userFid;

      // Determine which participant data to show (the OTHER user)
      const otherUser = isUserA
        ? {
            fid: suggestion.user_b_fid,
            username: suggestion.user_b_username,
            displayName: suggestion.user_b_display_name,
            avatarUrl: suggestion.user_b_avatar_url,
          }
        : {
            fid: suggestion.user_a_fid,
            username: suggestion.user_a_username,
            displayName: suggestion.user_a_display_name,
            avatarUrl: suggestion.user_a_avatar_url,
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
