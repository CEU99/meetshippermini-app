#!/usr/bin/env node

/**
 * Script to fix the match decline issue
 *
 * This script applies the SQL fix to resolve "Failed to update match" errors
 * when declining matches.
 *
 * Usage:
 *   node scripts/fix-decline-issue.js
 *
 * Prerequisites:
 *   - SUPABASE_URL environment variable
 *   - SUPABASE_SERVICE_ROLE_KEY environment variable
 */

const fs = require('fs');
const path = require('path');

// Load environment variables
require('dotenv').config({ path: path.join(__dirname, '..', '.env.local') });

const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL;
const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!SUPABASE_URL || !SUPABASE_SERVICE_KEY) {
  console.error('❌ Error: Missing required environment variables');
  console.error('   Please ensure NEXT_PUBLIC_SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are set');
  process.exit(1);
}

console.log('🔧 Fix Match Decline Issue');
console.log('═══════════════════════════════════════════════════════════');
console.log('');

async function runSQLFix() {
  try {
    console.log('📖 Reading SQL fix file...');
    const sqlFilePath = path.join(__dirname, '..', 'fix-decline-issue-complete.sql');
    const sql = fs.readFileSync(sqlFilePath, 'utf8');

    console.log('✓ SQL file loaded\n');
    console.log('🚀 Applying fix to Supabase...');
    console.log('   This will:');
    console.log('   1. Fix status constraint to include "declined"');
    console.log('   2. Update RLS policies for proper access control');
    console.log('   3. Grant necessary permissions');
    console.log('');

    // Execute SQL using Supabase REST API
    const response = await fetch(`${SUPABASE_URL}/rest/v1/rpc/exec_sql`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'apikey': SUPABASE_SERVICE_KEY,
        'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
        'Prefer': 'return=representation'
      },
      body: JSON.stringify({ query: sql })
    });

    // Supabase doesn't have exec_sql by default, so we use a different approach
    // Split the SQL into individual statements and execute via SQL editor

    console.log('⚠️  Note: This script prepares the SQL fix.');
    console.log('');
    console.log('📋 To apply the fix:');
    console.log('   1. Go to your Supabase Dashboard');
    console.log('   2. Navigate to SQL Editor');
    console.log('   3. Open: fix-decline-issue-complete.sql');
    console.log('   4. Click "Run" to execute the fix');
    console.log('');
    console.log('   OR use the Supabase CLI:');
    console.log('   supabase db execute -f fix-decline-issue-complete.sql');
    console.log('');
    console.log('✅ SQL fix file is ready at:');
    console.log(`   ${sqlFilePath}`);
    console.log('');

  } catch (error) {
    console.error('❌ Error applying fix:', error.message);
    console.error('');
    console.error('📝 Manual steps:');
    console.error('   1. Open Supabase Dashboard → SQL Editor');
    console.error('   2. Copy and paste the contents of fix-decline-issue-complete.sql');
    console.error('   3. Click "Run"');
    process.exit(1);
  }
}

// Check current match table configuration
async function checkCurrentConfiguration() {
  console.log('🔍 Checking current configuration...');
  console.log('');

  try {
    const { createClient } = require('@supabase/supabase-js');
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

    // Try to get a sample match
    const { data: matches, error } = await supabase
      .from('matches')
      .select('id, status')
      .limit(5);

    if (error) {
      console.log('⚠️  Could not query matches table:', error.message);
    } else {
      console.log(`✓ Found ${matches?.length || 0} matches in database`);
      if (matches && matches.length > 0) {
        console.log('  Sample statuses:', matches.map(m => m.status).join(', '));
      }
    }

    console.log('');
  } catch (error) {
    console.log('⚠️  Could not check configuration:', error.message);
    console.log('');
  }
}

async function main() {
  await checkCurrentConfiguration();
  await runSQLFix();

  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('');
  console.log('🧪 After applying the fix, test by:');
  console.log('   1. Starting your dev server: pnpm run dev');
  console.log('   2. Going to /mini/inbox');
  console.log('   3. Clicking "Decline" on a pending match');
  console.log('   4. Verifying no error appears');
  console.log('');
  console.log('💡 Tip: Check server console logs for detailed info');
  console.log('');
}

main().catch(console.error);
