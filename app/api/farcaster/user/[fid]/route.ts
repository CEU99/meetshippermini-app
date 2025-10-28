import { NextRequest, NextResponse } from 'next/server';
import { getSession } from '@/lib/auth';
import { neynarAPI, convertNeynarUserToUser } from '@/lib/neynar';

// GET /api/farcaster/user/[fid] - Get a single Farcaster user by FID
export async function GET(
  request: NextRequest,
  context: { params: Promise<{ fid: string }> }
) {
  try {
    const session = await getSession();
    if (!session) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    // Next.js 15+ requires awaiting params before accessing properties
    const { fid: fidString } = await context.params;
    const fid = parseInt(fidString);

    if (isNaN(fid)) {
      return NextResponse.json(
        { error: 'Invalid FID' },
        { status: 400 }
      );
    }

    console.log('[API Farcaster User] Fetching user with FID:', fid);

    // Fetch user from Neynar
    const neynarUser = await neynarAPI.getUserByFid(fid);

    if (!neynarUser) {
      return NextResponse.json(
        { error: 'User not found' },
        { status: 404 }
      );
    }

    // Convert to app format
    const user = {
      fid: neynarUser.fid,
      username: neynarUser.username || `user${neynarUser.fid}`,
      display_name: neynarUser.display_name || neynarUser.username || `User ${neynarUser.fid}`,
      avatar_url: neynarUser.pfp_url || '',
      bio: neynarUser.profile?.bio?.text || '',
    };

    console.log('[API Farcaster User] Returning user:', user);

    return NextResponse.json(user);
  } catch (error: any) {
    console.error('[API Farcaster User] Error fetching user:', error);
    console.error('[API Farcaster User] Error details:', {
      message: error?.message,
      status: error?.status,
    });
    return NextResponse.json(
      {
        error: 'Failed to fetch Farcaster user',
        details: error?.message || 'Unknown error',
      },
      { status: 500 }
    );
  }
}
