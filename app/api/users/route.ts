import { NextRequest, NextResponse } from 'next/server';
import { getServerSupabase } from '@/lib/supabase';

export async function GET(request: NextRequest) {
  try {
    const supabase = getServerSupabase();
    const { searchParams } = new URL(request.url);

    // Get pagination params
    const page = parseInt(searchParams.get('page') || '1');
    const limit = parseInt(searchParams.get('limit') || '20');
    const search = searchParams.get('search') || '';
    const showAll = searchParams.get('showAll') === 'true'; // Admin debugging flag

    const offset = (page - 1) * limit;

    console.log('[API Users] Fetching users - showAll:', showAll);

    // Build query
    let query = supabase
      .from('users')
      .select('fid, username, display_name, avatar_url, bio, user_code, has_joined_meetshipper, created_at, updated_at', { count: 'exact' })
      .order('updated_at', { ascending: false });

    // Filter by has_joined_meetshipper unless showAll is true
    if (!showAll) {
      query = query.eq('has_joined_meetshipper', true);
      console.log('[API Users] Filtering for has_joined_meetshipper = true');
    } else {
      console.log('[API Users] Admin mode: showing all users (including external)');
    }

    // Add search filter if provided
    if (search) {
      query = query.or(`username.ilike.%${search}%,display_name.ilike.%${search}%`);
    }

    // Add pagination
    query = query.range(offset, offset + limit - 1);

    const { data, error, count } = await query;

    if (error) {
      console.error('[API] Error fetching users:', error);
      return NextResponse.json(
        { error: 'Failed to fetch users', details: error.message },
        { status: 500 }
      );
    }

    console.log('[API Users] Found', count, 'users');

    return NextResponse.json({
      users: data || [],
      pagination: {
        page,
        limit,
        total: count || 0,
        totalPages: Math.ceil((count || 0) / limit),
      },
      filters: {
        showAll,
        onlyJoinedUsers: !showAll,
      },
    });
  } catch (error) {
    console.error('[API] Error in users endpoint:', error);
    return NextResponse.json(
      { error: 'Internal server error', message: error instanceof Error ? error.message : 'Unknown error' },
      { status: 500 }
    );
  }
}
