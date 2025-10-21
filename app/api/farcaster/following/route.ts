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
    const limit = limitParam ? parseInt(limitParam, 10) : 100;

    // Fetch following from Neynar
    const following = await neynarAPI.getUserFollowing(session.fid, limit);

    // Transform to simpler format
    const users = following.map((user) => ({
      fid: user.fid,
      username: user.username,
      displayName: user.display_name,
      pfpUrl: user.pfp_url,
      bio: user.profile?.bio?.text || '',
    }));

    return NextResponse.json({ users });
  } catch (error) {
    console.error('Error fetching following:', error);
    return NextResponse.json(
      { error: 'Failed to fetch following list' },
      { status: 500 }
    );
  }
}
