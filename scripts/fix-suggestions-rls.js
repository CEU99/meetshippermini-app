#!/usr/bin/env node
/**
 * Script to fix match_suggestions RLS policies
 * Run with: node scripts/fix-suggestions-rls.js
 */

const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');
const path = require('path');
require('dotenv').config({ path: '.env.local' });

async function main() {
  console.log('🔧 Fixing match_suggestions RLS policies...\n');

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

  // Read the SQL file
  const sqlPath = path.join(__dirname, '..', 'fix-match-suggestions-rls-v2.sql');
  let sql;
  try {
    sql = fs.readFileSync(sqlPath, 'utf8');
    console.log('✅ Loaded SQL file\n');
  } catch (error) {
    console.error('❌ Failed to read SQL file:', error.message);
    process.exit(1);
  }

  // Execute the SQL
  console.log('Executing SQL...\n');
  const { data, error } = await supabase.rpc('exec_sql', { sql_query: sql });

  if (error) {
    console.error('❌ Error executing SQL:', error);
    console.log('\n📝 Trying to execute statements one by one...\n');

    // Split into individual statements and execute
    const statements = sql
      .split(';')
      .map(s => s.trim())
      .filter(s => s.length > 0 && !s.startsWith('--'));

    for (const statement of statements) {
      if (statement.toUpperCase().includes('DROP POLICY')) {
        const match = statement.match(/DROP POLICY IF EXISTS "([^"]+)" ON (\w+)/);
        if (match) {
          const [, policyName, tableName] = match;
          console.log(`Dropping policy: ${policyName} from ${tableName}...`);

          // Use raw SQL via Postgres
          const { error: dropError } = await supabase.rpc('exec_sql', {
            sql_query: statement + ';'
          });

          if (dropError) {
            console.log(`⚠️  Could not drop policy (it may not exist): ${dropError.message}`);
          } else {
            console.log(`✅ Dropped policy: ${policyName}`);
          }
        }
      }
    }
  } else {
    console.log('✅ SQL executed successfully');
    if (data) {
      console.log('Result:', data);
    }
  }

  // Verify by checking current policies
  console.log('\n📋 Verifying current RLS policies on match_suggestions...\n');

  const { data: policies, error: policyError } = await supabase
    .from('pg_policies')
    .select('*')
    .eq('schemaname', 'public')
    .eq('tablename', 'match_suggestions');

  if (policyError) {
    console.log('⚠️  Could not query policies (this is okay):', policyError.message);
    console.log('\n📝 Manual verification recommended. Please check your Supabase dashboard.\n');
  } else if (policies) {
    console.log('Current policies:');
    policies.forEach(p => {
      console.log(`  - ${p.policyname} (${p.cmd})`);
      if (p.policyname === 'Service role can manage suggestions') {
        console.log('    ⚠️  WARNING: This policy should be removed!');
      }
    });
  }

  console.log('\n✅ Script completed. Please test the suggest match feature now.');
}

main().catch(error => {
  console.error('❌ Unexpected error:', error);
  process.exit(1);
});
