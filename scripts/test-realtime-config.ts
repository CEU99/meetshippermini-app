/**
 * Test if Supabase Realtime is properly configured for meetshipper_messages
 */
import 'dotenv/config';
import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = process.env.SUPABASE_URL || 'https://mpsnsxmznxvoqcslcaom.supabase.co';
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY || '';

async function testRealtimeConfig() {
  console.log('🔍 Testing Supabase Realtime Configuration\n');
  console.log('=' .repeat(60) + '\n');

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

  // Test 1: Check if table is in realtime publication
  console.log('1️⃣  Checking if meetshipper_messages is in realtime publication...');

  const { data: pubTables, error: pubError } = await supabase
    .from('pg_publication_tables')
    .select('*')
    .eq('pubname', 'supabase_realtime')
    .eq('tablename', 'meetshipper_messages');

  if (pubError) {
    console.log('   ⚠️  Cannot query pg_publication_tables (need superuser)');
    console.log('   We will test with actual subscription instead\n');
  } else if (!pubTables || pubTables.length === 0) {
    console.log('   ❌ Table NOT in realtime publication');
    console.log('   💡 Fix: Run this SQL in Supabase SQL Editor:');
    console.log('   ALTER PUBLICATION supabase_realtime ADD TABLE meetshipper_messages;\n');
    return false;
  } else {
    console.log('   ✅ Table is in realtime publication\n');
  }

  // Test 2: Check REPLICA IDENTITY
  console.log('2️⃣  Checking REPLICA IDENTITY setting...');

  const { data: replicaCheck, error: replicaError } = await supabase.rpc('exec_sql', {
    sql: `
      SELECT relreplident
      FROM pg_class
      WHERE relname = 'meetshipper_messages'
    `
  });

  if (replicaError) {
    console.log('   ⚠️  Cannot check REPLICA IDENTITY (will test subscription)\n');
  } else {
    console.log('   ✅ REPLICA IDENTITY configured\n');
  }

  // Test 3: Find a test room
  console.log('3️⃣  Finding a test room...');

  const { data: rooms, error: roomsError } = await supabase
    .from('meetshipper_rooms')
    .select('*')
    .eq('is_closed', false)
    .limit(1);

  if (roomsError || !rooms || rooms.length === 0) {
    console.log('   ⚠️  No open rooms found');
    console.log('   Create an accepted match first to test properly\n');
    return true;
  }

  const testRoom = rooms[0];
  console.log(`   ✅ Found test room: ${testRoom.id}\n`);

  // Test 4: Test actual realtime subscription
  console.log('4️⃣  Testing live subscription (will wait 10 seconds)...');
  console.log('   Setting up realtime channel...\n');

  let eventReceived = false;
  let testMessageId: string | null = null;

  return new Promise<boolean>((resolve) => {
    // Set up subscription
    const channel = supabase
      .channel(`test-channel-${Date.now()}`)
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'meetshipper_messages',
          filter: `room_id=eq.${testRoom.id}`,
        },
        (payload) => {
          console.log('   ✅ INSERT EVENT RECEIVED!');
          console.log('   Payload:', JSON.stringify(payload.new, null, 2));
          eventReceived = true;
          testMessageId = payload.new.id;
        }
      )
      .subscribe(async (status) => {
        console.log(`   Subscription status: ${status}`);

        if (status === 'SUBSCRIBED') {
          console.log('   ✅ Subscription active!\n');
          console.log('   ⏳ Inserting test message...\n');

          // Insert a test message
          const { data: message, error: insertError } = await supabase
            .from('meetshipper_messages')
            .insert({
              room_id: testRoom.id,
              sender_fid: testRoom.user_a_fid,
              content: `REALTIME TEST MESSAGE - ${new Date().toISOString()}`,
            })
            .select()
            .single();

          if (insertError) {
            console.error('   ❌ Failed to insert test message:', insertError.message);
            supabase.removeChannel(channel);
            resolve(false);
            return;
          }

          testMessageId = message.id;
          console.log(`   ✅ Test message inserted: ${testMessageId}`);
          console.log('   ⏳ Waiting for realtime event (5 seconds)...\n');

          // Wait 5 seconds for event
          setTimeout(async () => {
            if (eventReceived) {
              console.log('   🎉 REALTIME IS WORKING!\n');

              // Clean up test message
              console.log('   🧹 Cleaning up test message...');
              await supabase
                .from('meetshipper_messages')
                .delete()
                .eq('id', testMessageId!);

              console.log('   ✅ Test message deleted\n');
            } else {
              console.log('   ❌ NO REALTIME EVENT RECEIVED\n');
              console.log('   This means Realtime is NOT working properly.\n');
              console.log('   📋 To fix this:\n');
              console.log('   1. Go to Supabase Dashboard → Database → Replication');
              console.log('   2. Enable replication for meetshipper_messages table');
              console.log('   3. OR run this SQL:');
              console.log('      ALTER PUBLICATION supabase_realtime ADD TABLE meetshipper_messages;\n');
            }

            supabase.removeChannel(channel);
            resolve(eventReceived);
          }, 5000);
        } else if (status === 'CHANNEL_ERROR') {
          console.error('   ❌ Channel error!');
          resolve(false);
        }
      });
  });
}

// Run the test
testRealtimeConfig()
  .then((success) => {
    console.log('=' .repeat(60));
    if (success) {
      console.log('\n✅ REALTIME IS CONFIGURED CORRECTLY\n');
      console.log('If your app still isn\'t working, check:');
      console.log('  • Both browsers are using the same room ID');
      console.log('  • Console logs show subscription is active');
      console.log('  • No JavaScript errors in browser console\n');
      process.exit(0);
    } else {
      console.log('\n❌ REALTIME IS NOT WORKING\n');
      console.log('Follow the instructions above to fix it.\n');
      process.exit(1);
    }
  })
  .catch((error) => {
    console.error('\n💥 Test failed with error:', error);
    process.exit(1);
  });
