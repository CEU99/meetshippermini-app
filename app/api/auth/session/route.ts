import { NextRequest, NextResponse } from 'next/server';
import { createSession } from '@/lib/auth';
import { getServerSupabase } from '@/lib/supabase';
import { ensureUserCode } from '@/lib/user-code';

export async function POST(request: NextRequest) {
  try {
    // DEBUG: Log Supabase connection details
    console.log('=== SUPABASE CONNECTION DEBUG ===');
    console.log('URL:', process.env.NEXT_PUBLIC_SUPABASE_URL);
    console.log('Project ID:', process.env.NEXT_PUBLIC_SUPABASE_URL?.split('//')[1]?.split('.')[0]);
    console.log('Has Anon Key:', !!process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY);
    console.log('Has Service Key:', !!process.env.SUPABASE_SERVICE_ROLE_KEY);
    console.log('================================');

    const body = await request.json();
    const { fid, username, displayName, pfpUrl, bio } = body;

    if (!fid || !username) {
      return NextResponse.json(
        { error: 'Missing required fields' },
        { status: 400 }
      );
    }

    // Create or update user in Supabase using UPSERT
    const supabase = getServerSupabase();

    // Upsert user (insert if new, update if exists)
    // The DB trigger will automatically generate user_code on insert
    const { error: upsertError } = await supabase
      .from('users')
      .upsert(
        {
          fid,
          username,
          display_name: displayName || username,
          avatar_url: pfpUrl || null,
          bio: bio || null,
          has_joined_meetshipper: true, // User has logged in to MeetShipper
          updated_at: new Date().toISOString(),
        },
        {
          onConflict: 'fid',
          ignoreDuplicates: false,
        }
      );

    if (upsertError) {
      console.error('Error upserting user:', upsertError);
      throw new Error('Failed to create/update user');
    }

    // Ensure user has a user_code (fallback if trigger didn't work)
    const userCode = await ensureUserCode(fid);

    // Fetch user's traits from database
    const { data: userData } = await supabase
      .from('users')
      .select('bio, traits')
      .eq('fid', fid)
      .single();

    const traits = userData?.traits || [];
    const userBio = userData?.bio || bio || '';

    // If userCode is null, it means the column doesn't exist yet
    if (!userCode) {
      console.warn(`⚠️  User ${fid} logged in without user_code`);
      console.warn('📋 To fix: Run supabase-user-code-complete.sql in Supabase SQL Editor');
      console.warn('    https://supabase.com/dashboard -> SQL Editor');

      // Still create session without userCode
      await createSession({
        fid,
        username,
        displayName: displayName || username,
        avatarUrl: pfpUrl || null,
        userCode: undefined,
      });

      return NextResponse.json({
        success: true,
        userCode: null,
        bio: userBio,
        traits,
        requiresMigration: true,
        migrationFile: 'supabase-user-code-complete.sql',
        migrationUrl: 'https://supabase.com/dashboard',
      });
    }

    // Success - user has userCode
    console.log(`✅ User ${fid} (${username}) session created with code: ${userCode}`);

    // Create JWT session with user_code
    await createSession({
      fid,
      username,
      displayName: displayName || username,
      avatarUrl: pfpUrl || null,
      userCode,
    });

    return NextResponse.json({
      success: true,
      userCode,
      bio: userBio,
      traits,
      requiresMigration: false,
    });
  } catch (error) {
    console.error('Session creation error:', error);
    return NextResponse.json(
      { error: 'Failed to create session' },
      { status: 500 }
    );
  }
}
