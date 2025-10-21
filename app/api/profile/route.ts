import { NextRequest, NextResponse } from 'next/server';
import { requireAuth } from '@/lib/auth';
import { getServerSupabase } from '@/lib/supabase';
import { validateTraits } from '@/lib/constants/traits';
import { checkProfileAchievements } from '@/lib/services/achievement-service';

/**
 * Helper: Reload PostgREST schema cache
 * Call this after detecting PGRST204 errors
 */
async function reloadSchemaCache(supabase: ReturnType<typeof getServerSupabase>) {
  try {
    console.log('🔄 Reloading PostgREST schema cache...');
    const { data, error } = await supabase.rpc('reload_pgrst_schema');

    if (error) {
      console.error('❌ RPC call failed:', JSON.stringify(error, null, 2));
      return false;
    }

    console.log('✅ RPC call succeeded, result:', data);
    // Wait longer for the cache to fully reload (Supabase needs time to propagate)
    console.log('⏳ Waiting 1.5 seconds for cache propagation...');
    await new Promise(resolve => setTimeout(resolve, 1500));
    console.log('✅ Schema cache should be reloaded');
    return true;
  } catch (error) {
    console.error('❌ Failed to reload schema cache:', error);
    return false;
  }
}

/**
 * GET /api/profile
 * Fetch current user's profile (bio and traits)
 * Returns empty values gracefully if columns don't exist
 */
export async function GET(request: NextRequest) {
  try {
    console.log('=== GET /api/profile ===');

    // Step 1: Authenticate user via JWT session
    const session = await requireAuth();
    console.log('✅ Authenticated FID:', session.fid);

    // Step 2: Initialize Supabase client with service role
    const supabase = getServerSupabase();

    // Step 3: Try to query with bio and traits
    console.log('🔍 Querying profile for FID:', session.fid);

    let query = supabase
      .from('users')
      .select('fid, username, display_name, avatar_url, user_code, bio, traits')
      .eq('fid', session.fid)
      .single();

    let { data: user, error } = await query;

    // Handle schema cache error - reload and retry once
    if (error?.code === 'PGRST204') {
      console.warn('⚠️  Schema cache error detected, attempting reload and retry...');

      const reloaded = await reloadSchemaCache(supabase);

      if (reloaded) {
        // Retry the query
        console.log('🔄 Retrying query after cache reload...');
        const retry = await supabase
          .from('users')
          .select('fid, username, display_name, avatar_url, user_code, bio, traits')
          .eq('fid', session.fid)
          .single();

        user = retry.data;
        error = retry.error;
      }
    }

    // Handle column not found error gracefully - return empty values
    if (error?.code === '42703') {
      console.warn('⚠️  Column does not exist (42703), returning empty profile');

      // Query without bio/traits to get basic user info
      const { data: basicUser } = await supabase
        .from('users')
        .select('fid, username, display_name, avatar_url, user_code')
        .eq('fid', session.fid)
        .single();

      if (!basicUser) {
        return NextResponse.json(
          { error: 'User not found' },
          { status: 404, headers: { 'Content-Type': 'application/json' } }
        );
      }

      // Return with empty bio and traits
      return NextResponse.json(
        {
          fid: basicUser.fid,
          username: basicUser.username,
          displayName: basicUser.display_name || basicUser.username,
          pfpUrl: basicUser.avatar_url || '',
          bio: '',
          userCode: basicUser.user_code || null,
          traits: [],
        },
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // If still schema cache error after retry, return empty
    if (error?.code === 'PGRST204') {
      console.warn('⚠️  Schema cache error persists after reload, returning empty profile');

      const { data: basicUser } = await supabase
        .from('users')
        .select('fid, username, display_name, avatar_url, user_code')
        .eq('fid', session.fid)
        .single();

      if (!basicUser) {
        return NextResponse.json(
          { error: 'User not found' },
          { status: 404, headers: { 'Content-Type': 'application/json' } }
        );
      }

      return NextResponse.json(
        {
          fid: basicUser.fid,
          username: basicUser.username,
          displayName: basicUser.display_name || basicUser.username,
          pfpUrl: basicUser.avatar_url || '',
          bio: '',
          userCode: basicUser.user_code || null,
          traits: [],
        },
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Handle other database errors
    if (error) {
      console.error('❌ Database error:', error);
      return NextResponse.json(
        { error: 'Failed to fetch profile', message: error.message },
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // User not found
    if (!user) {
      console.error('❌ User not found for FID:', session.fid);
      return NextResponse.json(
        { error: 'User not found' },
        { status: 404, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Success - return profile (with empty fallbacks)
    console.log('✅ Profile fetched successfully');
    console.log('   FID:', user.fid);
    console.log('   Username:', user.username);
    console.log('   Has bio:', !!user.bio);
    console.log('   Traits count:', Array.isArray(user.traits) ? user.traits.length : 0);

    return NextResponse.json(
      {
        fid: user.fid,
        username: user.username,
        displayName: user.display_name || user.username,
        pfpUrl: user.avatar_url || '',
        bio: user.bio || '',
        userCode: user.user_code || null,
        traits: Array.isArray(user.traits) ? user.traits : [],
      },
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('❌ GET /api/profile error:', error);

    // Handle authentication errors
    if (error instanceof Error && error.message === 'Unauthorized') {
      return NextResponse.json(
        { error: 'Unauthorized', message: 'Please sign in to access this resource' },
        { status: 401, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Handle other errors
    return NextResponse.json(
      {
        error: 'Internal server error',
        message: error instanceof Error ? error.message : 'An unknown error occurred'
      },
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
}

/**
 * PATCH /api/profile
 * Update current user's bio and/or traits
 */
export async function PATCH(request: NextRequest) {
  try {
    console.log('=== PATCH /api/profile ===');

    // Step 1: Authenticate user via JWT session
    const session = await requireAuth();
    console.log('✅ Authenticated FID:', session.fid);

    // Step 2: Parse request body
    const body = await request.json();
    const { bio, traits } = body;

    console.log('📦 Request body:');
    console.log('   Bio provided:', 'bio' in body);
    console.log('   Bio length:', bio?.length || 0);
    console.log('   Traits provided:', 'traits' in body);
    console.log('   Traits count:', traits?.length || 0);

    // Step 3: Validate bio (optional, max 500 characters)
    if (bio !== undefined && bio !== null) {
      if (typeof bio !== 'string') {
        console.error('❌ Validation failed: bio is not a string');
        return NextResponse.json(
          { error: 'Bio must be a string' },
          { status: 400, headers: { 'Content-Type': 'application/json' } }
        );
      }

      if (bio.length > 500) {
        console.error('❌ Validation failed: bio too long');
        return NextResponse.json(
          { error: 'Bio must be 500 characters or less' },
          { status: 400, headers: { 'Content-Type': 'application/json' } }
        );
      }

      console.log('✅ Bio validated');
    }

    // Step 4: Validate traits (must be array of 5-10 valid traits, or empty for reset)
    if (traits !== undefined && traits !== null) {
      // Allow empty array for reset operations, otherwise enforce min/max
      const allowEmpty = Array.isArray(traits) && traits.length === 0;
      const validation = validateTraits(traits, allowEmpty);
      if (!validation.valid) {
        console.error('❌ Validation failed:', validation.error);
        return NextResponse.json(
          { error: validation.error },
          { status: 400, headers: { 'Content-Type': 'application/json' } }
        );
      }
      if (allowEmpty) {
        console.log('✅ Traits reset (empty array)');
      } else {
        console.log('✅ Traits validated:', traits);
      }
    }

    // Step 5: Build update object
    const updates: Record<string, any> = {
      updated_at: new Date().toISOString(),
    };

    if (bio !== undefined) {
      updates.bio = bio;
    }

    // Pass traits array directly - Supabase handles JSONB conversion
    if (traits !== undefined) {
      updates.traits = traits;
    }

    console.log('📝 Updating fields:', Object.keys(updates).filter(k => k !== 'updated_at'));

    // Step 6: Update in database
    const supabase = getServerSupabase();

    let { data, error } = await supabase
      .from('users')
      .update(updates)
      .eq('fid', session.fid)
      .select('fid, username, display_name, avatar_url, bio, user_code, traits')
      .single();

    // Handle schema cache error - reload and retry once
    if (error?.code === 'PGRST204') {
      console.warn('⚠️  Schema cache error detected, attempting reload and retry...');
      console.warn('   Original error:', JSON.stringify(error, null, 2));

      const reloaded = await reloadSchemaCache(supabase);

      if (reloaded) {
        // Retry the update
        console.log('🔄 Retrying update after cache reload...');
        const retry = await supabase
          .from('users')
          .update(updates)
          .eq('fid', session.fid)
          .select('fid, username, display_name, avatar_url, bio, user_code, traits')
          .single();

        data = retry.data;
        error = retry.error;

        if (retry.error) {
          console.error('❌ Retry failed with error:', JSON.stringify(retry.error, null, 2));
        } else {
          console.log('✅ Retry succeeded!');
        }
      }
    }

    // Handle column not found error - migration required
    if (error?.code === '42703') {
      console.error('❌ Column does not exist:', error.message);
      console.error('');
      console.error('🔧 MIGRATION REQUIRED:');
      console.error('   The bio/traits columns do not exist in your database.');
      console.error('   File: supabase-add-profile-fields-v2.sql');
      console.error('   Dashboard: https://supabase.com/dashboard');
      console.error('');

      return NextResponse.json(
        {
          error: 'MIGRATION_REQUIRED',
          message: 'Database columns do not exist. Please run supabase-add-profile-fields-v2.sql in Supabase SQL Editor.',
          migrationFile: 'supabase-add-profile-fields-v2.sql',
          dashboardUrl: 'https://supabase.com/dashboard'
        },
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // If schema cache error persists after retry
    if (error?.code === 'PGRST204') {
      console.error('❌ Schema cache error persists after reload');
      return NextResponse.json(
        {
          error: 'SCHEMA_CACHE_ERROR',
          message: 'Schema cache could not be reloaded. Please run: SELECT reload_pgrst_schema(); in Supabase SQL Editor, then try again.',
          troubleshootingSteps: [
            'Run: SELECT reload_pgrst_schema(); in Supabase SQL Editor',
            'If function does not exist, run: supabase-reload-schema-rpc.sql',
            'Wait 1-2 seconds and try saving again'
          ]
        },
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Handle other database errors
    if (error) {
      console.error('❌ Database error:', error);
      return NextResponse.json(
        { error: 'Failed to update profile', message: error.message },
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Success
    console.log('✅ Profile updated successfully');
    console.log('   Bio updated:', !!data.bio);
    console.log('   Traits count:', Array.isArray(data.traits) ? data.traits.length : 0);

    // Check and award profile achievements (bio and traits)
    try {
      const achievementsAwarded = await checkProfileAchievements(session.fid);
      if (achievementsAwarded.length > 0) {
        console.log(`[Achievement] Awarded ${achievementsAwarded.length} profile achievement(s)`);
        achievementsAwarded.forEach(a => {
          if (a.awarded) {
            console.log(`[Achievement] ✅ ${a.code} (+${a.points}pts) - Level ${a.level}`);
          }
        });
      }
    } catch (achError) {
      // Don't fail the request if achievement check fails
      console.error('[Achievement] Error checking profile achievements:', achError);
    }

    return NextResponse.json(
      {
        ok: true,
        profile: {
          fid: data.fid,
          username: data.username,
          displayName: data.display_name || data.username,
          pfpUrl: data.avatar_url || '',
          bio: data.bio || '',
          userCode: data.user_code || null,
          traits: Array.isArray(data.traits) ? data.traits : [],
        },
      },
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('❌ PATCH /api/profile error:', error);

    // Handle authentication errors
    if (error instanceof Error && error.message === 'Unauthorized') {
      return NextResponse.json(
        { error: 'Unauthorized', message: 'Please sign in to access this resource' },
        { status: 401, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Handle JSON parse errors
    if (error instanceof SyntaxError) {
      return NextResponse.json(
        { error: 'Invalid JSON in request body' },
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Handle other errors
    return NextResponse.json(
      {
        error: 'Internal server error',
        message: error instanceof Error ? error.message : 'An unknown error occurred'
      },
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
}
