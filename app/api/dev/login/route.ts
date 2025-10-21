import { NextRequest, NextResponse } from 'next/server';
import { createSession, getSession } from '@/lib/auth';
import { getServerSupabase } from '@/lib/supabase';

/**
 * DEV LOGIN ENDPOINT
 *
 * Purpose: Create test sessions without Farcaster OAuth
 *
 * SECURITY: Only works in development (NODE_ENV !== 'production')
 *
 * Usage:
 *
 * 1. Browser (simplest):
 *    http://localhost:3000/api/dev/login?fid=1111&username=alice&displayName=Alice&userCode=6287777951
 *
 * 2. POST with JSON:
 *    curl -X POST http://localhost:3000/api/dev/login \
 *      -H "Content-Type: application/json" \
 *      -d '{"fid": 1111, "username": "alice", "displayName": "Alice", "userCode": "6287777951"}' \
 *      -c cookies.txt
 *
 * 3. Check session:
 *    curl http://localhost:3000/api/dev/login -b cookies.txt
 */

// Mark this route as dynamic (not static)
export const dynamic = 'force-dynamic';

/**
 * GET /api/dev/login
 *
 * With query params: Creates a session
 * Without query params: Returns current session status
 */
export async function GET(request: NextRequest) {
  // SECURITY: Only allow in development
  if (process.env.NODE_ENV === 'production') {
    return NextResponse.json(
      { error: 'Dev login disabled in production' },
      { status: 403 }
    );
  }

  try {
    const { searchParams } = new URL(request.url);
    const fid = searchParams.get('fid');
    const username = searchParams.get('username');
    const displayName = searchParams.get('displayName');
    const userCode = searchParams.get('userCode');

    // If no params, return current session
    if (!fid && !username) {
      const session = await getSession();

      if (!session) {
        return NextResponse.json({
          authenticated: false,
          session: null,
          hint: 'No session found. Create one with ?fid=1111&username=alice'
        });
      }

      return NextResponse.json({
        authenticated: true,
        session
      });
    }

    // Validate required params
    if (!fid || !username) {
      return NextResponse.json(
        {
          error: 'Both fid and username are required',
          example: '?fid=1111&username=alice&displayName=Alice&userCode=6287777951'
        },
        { status: 400 }
      );
    }

    const fidNumber = parseInt(fid, 10);
    if (isNaN(fidNumber)) {
      return NextResponse.json(
        { error: 'fid must be a number' },
        { status: 400 }
      );
    }

    // Ensure user exists in database
    const supabase = getServerSupabase();
    const { data: existingUser, error: fetchError } = await supabase
      .from('users')
      .select('*')
      .eq('fid', fidNumber)
      .single();

    if (fetchError && fetchError.code !== 'PGRST116') {
      console.error('[Dev Login] Error checking user:', fetchError);
    }

    // Create or update user in database
    const userData = {
      fid: fidNumber,
      username,
      display_name: displayName || username,
      avatar_url: `https://avatar.vercel.sh/${username}`,
      user_code: userCode,
    };

    if (!existingUser) {
      console.log(`[Dev Login] Creating user in database: ${username} (${fidNumber})`);
      const { error: insertError } = await supabase
        .from('users')
        .insert(userData);

      if (insertError) {
        console.error('[Dev Login] Failed to create user:', insertError);
        // Continue anyway - session can work without DB user
      }
    } else {
      console.log(`[Dev Login] User already exists: ${username} (${fidNumber})`);
    }

    // Create session
    const token = await createSession({
      fid: fidNumber,
      username,
      displayName: displayName || username,
      avatarUrl: `https://avatar.vercel.sh/${username}`,
      userCode,
    });

    console.log(`[Dev Login] ✅ Session created for ${username} (${fidNumber})`);

    // Return response with session info
    const response = NextResponse.json({
      success: true,
      authenticated: true,
      message: `Logged in as ${username}`,
      session: {
        fid: fidNumber,
        username,
        displayName: displayName || username,
        userCode,
      },
      hint: 'Session cookie has been set. You can now access protected routes.',
    });

    // Ensure cookie is set (redundant but explicit)
    response.cookies.set('session', token, {
      httpOnly: true,
      secure: false, // false for localhost
      sameSite: 'lax',
      maxAge: 7 * 24 * 60 * 60, // 7 days
      path: '/',
    });

    return response;
  } catch (error: any) {
    console.error('[Dev Login] Error:', error);
    return NextResponse.json(
      {
        error: 'Failed to create session',
        message: error.message,
        stack: process.env.NODE_ENV === 'development' ? error.stack : undefined
      },
      { status: 500 }
    );
  }
}

/**
 * POST /api/dev/login
 *
 * Create session with JSON body
 */
export async function POST(request: NextRequest) {
  // SECURITY: Only allow in development
  if (process.env.NODE_ENV === 'production') {
    return NextResponse.json(
      { error: 'Dev login disabled in production' },
      { status: 403 }
    );
  }

  try {
    const body = await request.json();
    const { fid, username, displayName, avatarUrl, userCode } = body;

    if (!fid || !username) {
      return NextResponse.json(
        { error: 'fid and username are required' },
        { status: 400 }
      );
    }

    // Ensure user exists in database
    const supabase = getServerSupabase();
    const { data: existingUser } = await supabase
      .from('users')
      .select('*')
      .eq('fid', fid)
      .single();

    if (!existingUser) {
      console.log(`[Dev Login] Creating user in database: ${username} (${fid})`);
      await supabase.from('users').insert({
        fid,
        username,
        display_name: displayName || username,
        avatar_url: avatarUrl || `https://avatar.vercel.sh/${username}`,
        user_code: userCode,
      });
    }

    // Create session
    const token = await createSession({
      fid,
      username,
      displayName: displayName || username,
      avatarUrl: avatarUrl || `https://avatar.vercel.sh/${username}`,
      userCode,
    });

    console.log(`[Dev Login] ✅ Session created for ${username} (${fid})`);

    const response = NextResponse.json({
      success: true,
      authenticated: true,
      message: `Logged in as ${username}`,
      session: {
        fid,
        username,
        displayName: displayName || username,
      },
      token, // Include token for curl users
      hint: 'Session cookie has been set. Use -c cookies.txt with curl to save it, -b cookies.txt to use it.',
    });

    // Explicitly set cookie in response
    response.cookies.set('session', token, {
      httpOnly: true,
      secure: false, // false for localhost
      sameSite: 'lax',
      maxAge: 7 * 24 * 60 * 60, // 7 days
      path: '/',
    });

    return response;
  } catch (error: any) {
    console.error('[Dev Login] Error:', error);
    return NextResponse.json(
      { error: 'Failed to create session', message: error.message },
      { status: 500 }
    );
  }
}
