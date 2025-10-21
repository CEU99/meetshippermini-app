import { NextRequest, NextResponse } from 'next/server';
import { getSession } from '@/lib/auth';
import { getServerSupabase } from '@/lib/supabase';

/**
 * POST /api/matches/suggestions/[id]/decline
 * Decline a match suggestion (triggers 7-day cooldown)
 */
export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const session = await getSession();
    if (!session) {
      console.error('[API] Decline Suggestion: No session found');
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { id } = await params;

    console.log('[API] Declining suggestion:', {
      suggestionId: id,
      userFid: session.fid,
    });

    const supabase = getServerSupabase();

    // Get the suggestion
    const { data: suggestion, error: fetchError } = await supabase
      .from('match_suggestions')
      .select('*')
      .eq('id', id)
      .single();

    if (fetchError || !suggestion) {
      console.error('[API] Error fetching suggestion:', fetchError);
      return NextResponse.json(
        { error: 'Suggestion not found' },
        { status: 404 }
      );
    }

    // Check if user is a participant
    const isUserA = suggestion.user_a_fid === session.fid;
    const isUserB = suggestion.user_b_fid === session.fid;

    if (!isUserA && !isUserB) {
      return NextResponse.json(
        { error: 'You are not a participant in this suggestion' },
        { status: 403 }
      );
    }

    // Check if already declined
    if (suggestion.status === 'declined') {
      return NextResponse.json(
        { error: 'This suggestion has already been declined' },
        { status: 400 }
      );
    }

    // Update status to declined
    // The trigger will automatically create the cooldown
    const { data: updatedSuggestion, error: updateError } = await supabase
      .from('match_suggestions')
      .update({ status: 'declined' })
      .eq('id', id)
      .select()
      .single();

    if (updateError) {
      console.error('[API] Error declining suggestion:', updateError);
      return NextResponse.json(
        { error: 'Failed to decline suggestion', details: updateError.message },
        { status: 500 }
      );
    }

    console.log('[API] Suggestion declined:', {
      id: updatedSuggestion.id,
      status: updatedSuggestion.status,
    });

    // TODO: Send notification to the other party
    // TODO: Optionally notify suggester (if privacy rules allow)

    return NextResponse.json({
      success: true,
      suggestion: updatedSuggestion,
      message:
        'Suggestion declined. A 7-day cooldown has been applied to this pair.',
    });
  } catch (error) {
    console.error('[API] Decline suggestion error (uncaught):', error);
    const errorMessage =
      error instanceof Error ? error.message : 'Unknown error';
    return NextResponse.json(
      {
        error: 'Failed to decline suggestion',
        message: errorMessage,
      },
      { status: 500 }
    );
  }
}
