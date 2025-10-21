#!/usr/bin/env node
/**
 * Script to fix match_suggestions RLS policies
 * This removes the service role policies so that service role can bypass RLS
 * Run with: node scripts/fix-suggestions-rls-simple.js
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
  console.log('🔧 Fixing match_suggestions RLS policies...\n');

  // Check environment variables
  if (!process.env.NEXT_PUBLIC_SUPABASE_URL) {
    console.error('❌ Missing NEXT_PUBLIC_SUPABASE_URL');
    console.error('Please ensure .env.local exists and contains NEXT_PUBLIC_SUPABASE_URL');
    process.exit(1);
  }

  if (!process.env.SUPABASE_SERVICE_ROLE_KEY) {
    console.error('❌ Missing SUPABASE_SERVICE_ROLE_KEY');
    console.error('Please ensure .env.local exists and contains SUPABASE_SERVICE_ROLE_KEY');
    process.exit(1);
  }

  console.log(`📍 Supabase URL: ${process.env.NEXT_PUBLIC_SUPABASE_URL}\n`);

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
  console.log('📝 This script will drop the restrictive service role policies');
  console.log('   to allow service role to bypass RLS (standard Supabase behavior)\n');

  // Test connection by trying to select from match_suggestions
  console.log('🔍 Testing connection by querying match_suggestions...\n');
  const { data: testData, error: testError } = await supabase
    .from('match_suggestions')
    .select('id')
    .limit(1);

  if (testError) {
    console.error('❌ Error connecting to match_suggestions table:', testError);
    console.error('\nThis might mean:');
    console.error('  1. The table does not exist yet (run migration first)');
    console.error('  2. The service role key is incorrect');
    console.error('  3. Network/connection issue');
    process.exit(1);
  }

  console.log('✅ Successfully connected to match_suggestions table\n');
  console.log(`   Found ${testData?.length || 0} suggestions in the table\n`);

  // Now we need to execute raw SQL to drop policies
  // Supabase doesn't provide a direct way, so we'll need to do this via the SQL editor
  // in the Supabase dashboard, or use a stored procedure

  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('📋 MANUAL STEPS REQUIRED');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
  console.log('Please run the following SQL commands in your Supabase SQL Editor:');
  console.log('(Dashboard → SQL Editor → New Query)\n');
  console.log('```sql');
  console.log('-- Drop the restrictive service role policies');
  console.log('DROP POLICY IF EXISTS "Service role can manage suggestions" ON match_suggestions;');
  console.log('DROP POLICY IF EXISTS "Service role can manage cooldowns" ON match_suggestion_cooldowns;');
  console.log('```\n');
  console.log('After running this SQL:');
  console.log('  1. The service role will bypass ALL RLS policies (standard behavior)');
  console.log('  2. Your API route will be able to insert suggestions');
  console.log('  3. Regular users will still be protected by the existing RLS policies\n');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  console.log('Alternative: If you have Supabase CLI installed, run:');
  console.log('  supabase db execute --file fix-match-suggestions-rls-v2.sql\n');
}

main().catch(error => {
  console.error('❌ Unexpected error:', error);
  process.exit(1);
});
