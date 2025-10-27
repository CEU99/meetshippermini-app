import { NextRequest, NextResponse } from 'next/server';
import { getSession } from '@/lib/auth';
import { neynarAPI } from '@/lib/neynar';

// GET /api/farcaster/following - Get user's following list from Farcaster
export async function GET(request: NextRequest) {
  try {
    const session = await getSession();
    if (!session) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { searchParams } = new URL(request.url);
    const limitParam = searchParams.get('limit');
    const cursorParam = searchParams.get('cursor');
    const getAllParam = searchParams.get('all'); // ?all=true to fetch all with pagination

    // Parse and clamp limit between 1 and 100
    let limit = limitParam ? parseInt(limitParam, 10) : 100;
    limit = Math.max(1, Math.min(100, limit));

    if (getAllParam === 'true') {
      // Fetch all following users (handles pagination automatically)
      const maxLimit = limitParam ? parseInt(limitParam, 10) : 500;
      const following = await neynarAPI.getAllUserFollowing(session.fid, maxLimit);

      console.log('[API Following] Raw following data sample:', following[0]);

      // Transform to simpler format with proper fallbacks
      // Note: Neynar returns data nested as { object: 'follow', user: {...} }
      const users = following.map((item) => {
        // Extract the actual user object from the nested structure
        const user = item.user || item;

        const transformed = {
          fid: user.fid,
          username: user.username || `user${user.fid}`,
          displayName: user.display_name || user.username || `User ${user.fid}`,
          pfpUrl: user.pfp_url || '',
          bio: user.profile?.bio?.text || '',
        };
        return transformed;
      });

      console.log('[API Following] Transformed user sample:', users[0]);
      console.log(`[API Following] Returning ${users.length} users`);

      return NextResponse.json({
        users,
        total: users.length,
      });
    } else {
      // Fetch single page with optional cursor
      const result = await neynarAPI.getUserFollowing(
        session.fid,
        limit,
        cursorParam || undefined
      );

      // Transform to simpler format
      // Note: Neynar returns data nested as { object: 'follow', user: {...} }
      const users = result.users.map((item) => {
        // Extract the actual user object from the nested structure
        const user = item.user || item;

        return {
          fid: user.fid,
          username: user.username || `user${user.fid}`,
          displayName: user.display_name || user.username || `User ${user.fid}`,
          pfpUrl: user.pfp_url || '',
          bio: user.profile?.bio?.text || '',
        };
      });

      return NextResponse.json({
        users,
        next_cursor: result.next_cursor,
        has_more: !!result.next_cursor,
      });
    }
  } catch (error: any) {
    console.error('[API Following] Error fetching following:', error);
    console.error('[API Following] Error details:', {
      message: error?.message,
      status: error?.status,
      response: error?.response,
    });
    return NextResponse.json(
      {
        error: 'Failed to fetch following list',
        details: error?.message || 'Unknown error',
      },
      { status: 500 }
    );
  }
}
