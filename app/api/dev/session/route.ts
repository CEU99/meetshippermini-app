import { NextRequest, NextResponse } from 'next/server';
import { getSession } from '@/lib/auth';

/**
 * GET /api/dev/session
 *
 * Returns current session status
 *
 * Usage:
 *   curl http://localhost:3000/api/dev/session
 *   curl http://localhost:3000/api/dev/session -b cookies.txt
 */

// Mark as dynamic
export const dynamic = 'force-dynamic';

export async function GET(_request: NextRequest) {
  try {
    const session = await getSession();

    if (!session) {
      return NextResponse.json({
        authenticated: false,
        session: null,
        hint: 'No active session. Login at /api/dev/login'
      });
    }

    return NextResponse.json({
      authenticated: true,
      session: {
        fid: session.fid,
        username: session.username,
        displayName: session.displayName,
        avatarUrl: session.avatarUrl,
        userCode: session.userCode,
        expiresAt: new Date(session.expiresAt).toISOString(),
      }
    });
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
    console.error('[Dev Session] Error:', error);
    return NextResponse.json(
      {
        authenticated: false,
        session: null,
        error: errorMessage
      },
      { status: 500 }
    );
  }
}
