import { NextRequest, NextResponse } from 'next/server';
import { getServerSupabase } from '@/lib/supabase';

export async function GET(
  request: NextRequest,
  context: { params: Promise<{ fid: string }> }
) {
  try {
    // Next.js 15+ requires awaiting params before accessing properties
    const { fid: fidString } = await context.params;
    const supabase = getServerSupabase();
    const fid = parseInt(fidString);

    if (isNaN(fid)) {
      return NextResponse.json(
        { error: 'Invalid FID' },
        { status: 400 }
      );
    }

    const { data, error } = await supabase
      .from('users')
      .select('fid, username, display_name, avatar_url, bio, user_code, traits, created_at, updated_at')
      .eq('fid', fid)
      .single();

    if (error) {
      console.error('[API] Error fetching user:', error);

      if (error.code === 'PGRST116') {
        return NextResponse.json(
          { error: 'User not found' },
          { status: 404 }
        );
      }

      return NextResponse.json(
        { error: 'Failed to fetch user', details: error.message },
        { status: 500 }
      );
    }

    return NextResponse.json(data);
  } catch (error) {
    console.error('[API] Error in user endpoint:', error);
    return NextResponse.json(
      { error: 'Internal server error', message: error instanceof Error ? error.message : 'Unknown error' },
      { status: 500 }
    );
  }
}
