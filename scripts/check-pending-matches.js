#!/usr/bin/env node
/**
 * Check for pending matches that can be used for testing decline
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
  console.log('🔍 Checking for pending matches...\n');

  if (!process.env.NEXT_PUBLIC_SUPABASE_URL || !process.env.SUPABASE_SERVICE_ROLE_KEY) {
    console.error('❌ Missing Supabase credentials');
    process.exit(1);
  }

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

  // Get pending matches
  const { data: matches, error } = await supabase
    .from('matches')
    .select(`
      id,
      status,
      user_a_fid,
      user_b_fid,
      a_accepted,
      b_accepted,
      created_at,
      message
    `)
    .in('status', ['proposed', 'pending', 'accepted_by_a', 'accepted_by_b'])
    .order('created_at', { ascending: false })
    .limit(10);

  if (error) {
    console.error('❌ Error fetching matches:', error);
    process.exit(1);
  }

  if (!matches || matches.length === 0) {
    console.log('📭 No pending matches found\n');
    console.log('You can create a test match using the manual match feature\n');
    return;
  }

  console.log(`✅ Found ${matches.length} pending match(es):\n`);

  matches.forEach((match, idx) => {
    console.log(`${idx + 1}. Match ID: ${match.id}`);
    console.log(`   Status: ${match.status}`);
    console.log(`   User A: ${match.user_a_fid} (accepted: ${match.a_accepted})`);
    console.log(`   User B: ${match.user_b_fid} (accepted: ${match.b_accepted})`);
    console.log(`   Created: ${new Date(match.created_at).toLocaleString()}`);
    if (match.message) {
      console.log(`   Message: ${match.message.substring(0, 50)}...`);
    }
    console.log('');
  });

  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('To test declining, use one of these match IDs:');
  console.log('  node scripts/diagnose-match-decline.js <match-id>');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
}

main().catch(error => {
  console.error('❌ Unexpected error:', error);
  process.exit(1);
});
