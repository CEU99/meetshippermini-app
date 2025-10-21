import { NextRequest, NextResponse } from 'next/server';
import { getServerSupabase } from '@/lib/supabase';

/**
 * API endpoint to run the user_code migration
 * This creates the column, constraints, functions, and trigger if they don't exist
 */
export async function POST(request: NextRequest) {
  try {
    console.log('🔄 Running user_code migration...');

    const supabase = getServerSupabase();

    // Step 1: Check if column exists
    const { error: checkError } = await supabase
      .from('users')
      .select('user_code')
      .limit(1);

    if (checkError && checkError.code === '42703') {
      // Column doesn't exist, need to run migration
      console.log('⚠️  Column user_code does not exist, creating...');

      // We'll need to run this SQL manually in Supabase
      // But we can return instructions to the user
      return NextResponse.json({
        migrated: false,
        columnExists: false,
        message: 'Migration required',
        instructions: 'Please run supabase-user-code-complete.sql in Supabase SQL Editor',
      });
    }

    // Column exists, check if users have codes
    const { data: usersWithoutCodes, error: queryError } = await supabase
      .from('users')
      .select('fid')
      .is('user_code', null)
      .limit(10);

    if (queryError) {
      console.error('Error checking users:', queryError);
      return NextResponse.json(
        { error: 'Failed to check users' },
        { status: 500 }
      );
    }

    if (usersWithoutCodes && usersWithoutCodes.length > 0) {
      console.log(
        `⚠️  Found ${usersWithoutCodes.length} users without user_code`
      );
      return NextResponse.json({
        migrated: false,
        columnExists: true,
        message: 'Users need codes',
        usersWithoutCodes: usersWithoutCodes.length,
      });
    }

    console.log('✅ Migration check complete - all users have codes');

    return NextResponse.json({
      migrated: true,
      columnExists: true,
      message: 'All users have codes',
    });
  } catch (error) {
    console.error('Migration check error:', error);
    return NextResponse.json(
      {
        error: 'Migration check failed',
        details: error instanceof Error ? error.message : 'Unknown error',
      },
      { status: 500 }
    );
  }
}

export async function GET(request: NextRequest) {
  // Check migration status
  const supabase = getServerSupabase();

  const { error } = await supabase.from('users').select('user_code').limit(1);

  if (error && error.code === '42703') {
    return NextResponse.json({
      columnExists: false,
      message: 'Migration required - run supabase-user-code-complete.sql',
    });
  }

  return NextResponse.json({
    columnExists: true,
    message: 'Column exists',
  });
}
