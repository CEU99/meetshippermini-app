import { NextRequest, NextResponse } from 'next/server';
import { getServerSupabase } from '@/lib/supabase';

export async function GET(
  request: NextRequest,
  context: { params: Promise<{ code: string }> }
) {
  try {
    // Next.js 15+ requires awaiting params before accessing properties
    const { code: userCode } = await context.params;
    const supabase = getServerSupabase();

    if (!userCode || userCode.trim().length === 0) {
      return NextResponse.json(
        { error: 'Invalid User Code' },
        { status: 400 }
      );
    }

    const { data, error } = await supabase
      .from('users')
      .select('fid, username, display_name, avatar_url, bio, user_code, traits, created_at, updated_at')
      .eq('user_code', userCode.trim().toUpperCase())
      .single();

    if (error) {
      console.error('[API] Error fetching user by code:', error);

      if (error.code === 'PGRST116') {
        return NextResponse.json(
          { error: 'User not found with this User Code' },
          { status: 404 }
        );
      }

      return NextResponse.json(
        { error: 'Failed to fetch user', details: error.message },
        { status: 500 }
      );
    }

    return NextResponse.json({ user: data });
  } catch (error: unknown) {
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
    console.error('[API] Error in user by code endpoint:', errorMessage);
    return NextResponse.json(
      { error: 'Internal server error', message: errorMessage },
      { status: 500 }
    );
  }
}
