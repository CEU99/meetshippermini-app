import { NextRequest, NextResponse } from 'next/server';
import { deleteSession } from '@/lib/auth';

/**
 * GET /api/dev/logout
 *
 * Clears the session cookie
 *
 * Usage:
 *   Browser: http://localhost:3000/api/dev/logout
 *   Curl: curl http://localhost:3000/api/dev/logout -b cookies.txt -c cookies.txt
 */

// Mark as dynamic
export const dynamic = 'force-dynamic';

export async function GET(request: NextRequest) {
  if (process.env.NODE_ENV === 'production') {
    return NextResponse.json(
      { error: 'Dev logout disabled in production' },
      { status: 403 }
    );
  }

  try {
    await deleteSession();

    console.log('[Dev Logout] Session cleared');

    const response = NextResponse.json({
      success: true,
      message: 'Logged out successfully',
      hint: 'Session cookie has been cleared'
    });

    // Explicitly clear the cookie
    response.cookies.set('session', '', {
      httpOnly: true,
      secure: false,
      sameSite: 'lax',
      maxAge: 0, // Expire immediately
      path: '/',
    });

    return response;
  } catch (error: any) {
    console.error('[Dev Logout] Error:', error);
    return NextResponse.json(
      { error: 'Failed to logout', message: error.message },
      { status: 500 }
    );
  }
}

// Also support POST for consistency
export async function POST(request: NextRequest) {
  return GET(request);
}
