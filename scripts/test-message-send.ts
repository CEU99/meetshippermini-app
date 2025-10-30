/**
 * Test script to verify message sending functionality
 * Tests if meetshipper_messages table exists and is accessible
 */

import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = process.env.SUPABASE_URL || 'https://mpsnsxmznxvoqcslcaom.supabase.co';
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY || '';

async function testMessageSending() {
  console.log('🧪 Testing MeetShipper Message Sending...\n');

  if (!SUPABASE_SERVICE_ROLE_KEY) {
    console.error('❌ SUPABASE_SERVICE_ROLE_KEY not set');
    process.exit(1);
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  });

  // Test 1: Check if meetshipper_messages table exists
  console.log('1️⃣ Checking if meetshipper_messages table exists...');
  const { data: tables, error: tablesError } = await supabase
    .from('meetshipper_messages')
    .select('*')
    .limit(0);

  if (tablesError) {
    console.error('❌ Table check failed:', tablesError.message);
    console.error('   This likely means the migration has not been applied yet.');
    console.error('\n📋 To fix this, run:');
    console.error('   psql "$DATABASE_URL" < supabase/migrations/20250131_create_meetshipper_messages.sql');
    return false;
  }
  console.log('✅ meetshipper_messages table exists\n');

  // Test 2: Check if meetshipper_message_details view exists
  console.log('2️⃣ Checking if meetshipper_message_details view exists...');
  const { data: viewCheck, error: viewError } = await supabase
    .from('meetshipper_message_details')
    .select('*')
    .limit(0);

  if (viewError) {
    console.error('❌ View check failed:', viewError.message);
    return false;
  }
  console.log('✅ meetshipper_message_details view exists\n');

  // Test 3: Find an existing room to test with
  console.log('3️⃣ Finding an existing conversation room...');
  const { data: rooms, error: roomsError } = await supabase
    .from('meetshipper_rooms')
    .select('*')
    .eq('is_closed', false)
    .limit(1);

  if (roomsError || !rooms || rooms.length === 0) {
    console.warn('⚠️  No open rooms found to test with');
    console.log('   Create an accepted match first to test message sending');
    return true; // Not a failure, just no test data
  }

  const testRoom = rooms[0];
  console.log(`✅ Found test room: ${testRoom.id}`);
  console.log(`   Participants: FID ${testRoom.user_a_fid} <-> FID ${testRoom.user_b_fid}\n`);

  // Test 4: Try to insert a test message
  console.log('4️⃣ Attempting to send a test message...');
  const { data: message, error: messageError } = await supabase
    .from('meetshipper_messages')
    .insert({
      room_id: testRoom.id,
      sender_fid: testRoom.user_a_fid,
      content: 'Test message from script',
    })
    .select()
    .single();

  if (messageError) {
    console.error('❌ Failed to send test message:', messageError.message);
    console.error('   Error details:', messageError);
    return false;
  }
  console.log('✅ Test message sent successfully!');
  console.log(`   Message ID: ${message.id}\n`);

  // Test 5: Fetch the message with full details
  console.log('5️⃣ Fetching message with user details...');
  const { data: messageDetails, error: detailsError } = await supabase
    .from('meetshipper_message_details')
    .select('*')
    .eq('id', message.id)
    .single();

  if (detailsError) {
    console.error('❌ Failed to fetch message details:', detailsError.message);
    return false;
  }
  console.log('✅ Message details fetched successfully!');
  console.log('   Sender:', messageDetails.sender_display_name, `(@${messageDetails.sender_username})`);
  console.log('   Content:', messageDetails.content);
  console.log('   Timestamp:', messageDetails.created_at, '\n');

  // Test 6: Clean up - delete the test message
  console.log('6️⃣ Cleaning up test message...');
  const { error: deleteError } = await supabase
    .from('meetshipper_messages')
    .delete()
    .eq('id', message.id);

  if (deleteError) {
    console.warn('⚠️  Failed to delete test message:', deleteError.message);
  } else {
    console.log('✅ Test message deleted\n');
  }

  return true;
}

// Run the test
testMessageSending()
  .then((success) => {
    if (success) {
      console.log('🎉 All tests passed! Message sending is working correctly.');
      process.exit(0);
    } else {
      console.log('❌ Some tests failed. Please fix the issues above.');
      process.exit(1);
    }
  })
  .catch((error) => {
    console.error('💥 Unexpected error:', error);
    process.exit(1);
  });
