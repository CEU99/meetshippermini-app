#!/usr/bin/env node
/**
 * Diagnostic script for match decline issue
 * Run with: node scripts/diagnose-match-decline.js <match-id>
 */

const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');
const path = require('path');

// Load environment variables from .env.local
const envPath = path.join(__dirname, '..', '.env.local');
if (fs.existsSync(envPath)) {
  const envFile = fs.readFileSync(envPath, 'utf8');
  envFile.split('\n').forEach(line => {
    const match = line.match(/^([^=:#]+)=(.*)$/);
    if (match) {
      const key = match[1].trim();
      const value = match[2].trim();
      process.env[key] = value;
    }
  });
}

async function main() {
  const matchId = process.argv[2];

  if (!matchId) {
    console.error('❌ Please provide a match ID');
    console.error('Usage: node scripts/diagnose-match-decline.js <match-id>');
    console.error('\nTo get a match ID, check your inbox or database');
    process.exit(1);
  }

  console.log(`🔍 Diagnosing match decline issue for match: ${matchId}\n`);

  // Check environment variables
  if (!process.env.NEXT_PUBLIC_SUPABASE_URL) {
    console.error('❌ Missing NEXT_PUBLIC_SUPABASE_URL');
    process.exit(1);
  }

  if (!process.env.SUPABASE_SERVICE_ROLE_KEY) {
    console.error('❌ Missing SUPABASE_SERVICE_ROLE_KEY');
    process.exit(1);
  }

  // Create Supabase client with service role
  const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL,
    process.env.SUPABASE_SERVICE_ROLE_KEY,
    {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    }
  );

  console.log('✅ Connected to Supabase\n');

  // 1. Check if match exists
  console.log('1️⃣ Checking if match exists...\n');
  const { data: match, error: fetchError } = await supabase
    .from('matches')
    .select('*')
    .eq('id', matchId)
    .single();

  if (fetchError) {
    console.error('❌ Error fetching match:', fetchError);
    console.error('   This match may not exist or there may be a permission issue\n');
    process.exit(1);
  }

  if (!match) {
    console.error('❌ Match not found\n');
    process.exit(1);
  }

  console.log('✅ Match found:');
  console.log('   ID:', match.id);
  console.log('   Status:', match.status);
  console.log('   User A FID:', match.user_a_fid);
  console.log('   User B FID:', match.user_b_fid);
  console.log('   A Accepted:', match.a_accepted);
  console.log('   B Accepted:', match.b_accepted);
  console.log('   Created By:', match.created_by_fid);
  console.log('   Message:', match.message ? match.message.substring(0, 50) + '...' : 'None');
  console.log('');

  // 2. Check if match can be declined (status check)
  console.log('2️⃣ Checking if match is in valid state for decline...\n');
  const validStatuses = ['proposed', 'accepted_by_a', 'accepted_by_b', 'pending'];

  if (!validStatuses.includes(match.status)) {
    console.log('⚠️  Match status is:', match.status);
    console.log('   Valid statuses for decline:', validStatuses.join(', '));
    console.log('   This match cannot be declined in its current state\n');
  } else {
    console.log('✅ Match is in valid state:', match.status, '\n');
  }

  // 3. Test declining the match (simulate the API call)
  console.log('3️⃣ Testing match decline update...\n');

  const updateData = {
    status: 'declined',
    message: match.message ? `${match.message}\n\nDecline reason: Test decline` : 'Decline reason: Test decline',
  };

  console.log('   Update data:', JSON.stringify(updateData, null, 2));
  console.log('');

  const { data: updatedMatch, error: updateError } = await supabase
    .from('matches')
    .update(updateData)
    .eq('id', matchId)
    .select()
    .single();

  if (updateError) {
    console.error('❌ Failed to update match:');
    console.error('   Error:', updateError);
    console.error('   Code:', updateError.code);
    console.error('   Message:', updateError.message);
    console.error('   Details:', updateError.details);
    console.error('   Hint:', updateError.hint);
    console.error('');

    // Provide specific guidance based on error code
    if (updateError.code === '42501') {
      console.log('💡 This is a permission error (RLS policy violation)');
      console.log('   Solution: Check RLS policies on the matches table\n');
    } else if (updateError.code === '23514') {
      console.log('💡 This is a check constraint violation');
      console.log('   The status value may not be in the allowed list\n');
    } else if (updateError.code === '23503') {
      console.log('💡 This is a foreign key constraint violation\n');
    }

    process.exit(1);
  }

  if (!updatedMatch) {
    console.error('⚠️  Update succeeded but no data returned\n');
  } else {
    console.log('✅ Match declined successfully!');
    console.log('   New status:', updatedMatch.status);
    console.log('   Updated message:', updatedMatch.message ? updatedMatch.message.substring(0, 100) + '...' : 'None');
    console.log('');
  }

  // 4. Revert the change (set back to original status)
  console.log('4️⃣ Reverting test decline...\n');

  const { error: revertError } = await supabase
    .from('matches')
    .update({ status: match.status, message: match.message })
    .eq('id', matchId);

  if (revertError) {
    console.error('⚠️  Failed to revert:', revertError.message);
    console.log('   You may need to manually update this match in the database\n');
  } else {
    console.log('✅ Match reverted to original state\n');
  }

  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('✅ Diagnosis complete!');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
}

main().catch(error => {
  console.error('❌ Unexpected error:', error);
  process.exit(1);
});
