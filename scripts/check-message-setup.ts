/**
 * Quick diagnostic script to check if message sending is ready
 * Run this to verify your database is properly set up
 */
import 'dotenv/config';
import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = process.env.SUPABASE_URL || 'https://mpsnsxmznxvoqcslcaom.supabase.co';
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY || '';

async function checkSetup() {
  console.log('🔍 MeetShipper Message Setup Diagnostic\n');
  console.log('=' .repeat(50) + '\n');

  if (!SUPABASE_SERVICE_ROLE_KEY) {
    console.error('❌ SUPABASE_SERVICE_ROLE_KEY not set');
    console.log('\n📋 Fix: Add SUPABASE_SERVICE_ROLE_KEY to your .env.local file\n');
    return false;
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  let allChecks = true;

  // Check 1: meetshipper_messages table
  console.log('1️⃣  Checking meetshipper_messages table...');
  const { error: tableError } = await supabase
    .from('meetshipper_messages')
    .select('*')
    .limit(0);

  if (tableError) {
    console.log('   ❌ Table not found');
    console.log('   💡 Solution: Apply the migration via Supabase Dashboard');
    console.log('      See MESSAGE_SENDING_FIX.md for step-by-step instructions\n');
    allChecks = false;
  } else {
    console.log('   ✅ Table exists\n');
  }

  // Check 2: meetshipper_message_details view
  console.log('2️⃣  Checking meetshipper_message_details view...');
  const { error: viewError } = await supabase
    .from('meetshipper_message_details')
    .select('*')
    .limit(0);

  if (viewError) {
    console.log('   ❌ View not found');
    console.log('   💡 This view is created by the same migration\n');
    allChecks = false;
  } else {
    console.log('   ✅ View exists\n');
  }

  // Check 3: meetshipper_rooms table (should exist)
  console.log('3️⃣  Checking meetshipper_rooms table...');
  const { data: rooms, error: roomsError } = await supabase
    .from('meetshipper_rooms')
    .select('*')
    .limit(1);

  if (roomsError) {
    console.log('   ❌ Table not found (this is unexpected)');
    allChecks = false;
  } else {
    console.log('   ✅ Table exists');
    if (rooms && rooms.length > 0) {
      console.log(`   ℹ️  Found ${rooms.length} room(s) for testing\n`);
    } else {
      console.log('   ⚠️  No rooms exist yet - create an accepted match first\n');
    }
  }

  // Summary
  console.log('=' .repeat(50));
  if (allChecks) {
    console.log('\n✅ All checks passed! Message sending should work.\n');
    console.log('🎉 You can now:');
    console.log('   1. Start the dev server: pnpm run dev');
    console.log('   2. Navigate to an accepted match');
    console.log('   3. Open the MeetShipper Conversation Room');
    console.log('   4. Send messages with real-time updates!\n');
    return true;
  } else {
    console.log('\n❌ Setup incomplete. Action required:\n');
    console.log('📋 To fix the issues above:');
    console.log('   1. Open: https://supabase.com/dashboard/project/mpsnsxmznxvoqcslcaom/sql/new');
    console.log('   2. Copy contents of: supabase/migrations/20250131_create_meetshipper_messages.sql');
    console.log('   3. Paste into SQL Editor and click "Run"');
    console.log('   4. Run this script again to verify\n');
    console.log('📖 Detailed instructions: MESSAGE_SENDING_FIX.md\n');
    return false;
  }
}

// Run the diagnostic
checkSetup()
  .then((success) => {
    process.exit(success ? 0 : 1);
  })
  .catch((error) => {
    console.error('\n💥 Unexpected error:', error.message);
    process.exit(1);
  });
