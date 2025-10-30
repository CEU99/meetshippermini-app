/**
 * Apply meetshipper_messages migration to database
 * This script reads the SQL migration file and executes it via Supabase
 */

import { createClient } from '@supabase/supabase-js';
import { readFileSync } from 'fs';
import { join } from 'path';

const SUPABASE_URL = process.env.SUPABASE_URL || 'https://mpsnsxmznxvoqcslcaom.supabase.co';
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY || '';

async function applyMigration() {
  console.log('🚀 Applying meetshipper_messages migration...\n');

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

  // Read the migration file
  const migrationPath = join(
    process.cwd(),
    'supabase/migrations/20250131_create_meetshipper_messages.sql'
  );

  let migrationSQL: string;
  try {
    migrationSQL = readFileSync(migrationPath, 'utf-8');
    console.log('✅ Migration file loaded\n');
  } catch (error) {
    console.error('❌ Failed to read migration file:', error);
    process.exit(1);
  }

  // Execute the migration
  console.log('📝 Executing migration SQL...\n');

  try {
    // Split by semicolons and execute statements (Supabase client doesn't support multi-statement execution)
    // So we'll execute the entire migration as one statement
    const { data, error } = await (supabase as any).rpc('exec_sql', {
      sql_string: migrationSQL,
    });

    if (error) {
      console.error('❌ Migration failed via RPC:', error.message);
      console.log('\n📋 Manual application required:');
      console.log('   1. Go to https://supabase.com/dashboard/project/mpsnsxmznxvoqcslcaom/sql/new');
      console.log('   2. Copy and paste the contents of:');
      console.log('      supabase/migrations/20250131_create_meetshipper_messages.sql');
      console.log('   3. Click "Run" to execute the migration\n');
      process.exit(1);
    }

    console.log('✅ Migration executed successfully!\n');
  } catch (error: any) {
    console.error('❌ Migration execution error:', error.message);
    console.log('\n📋 Manual application required:');
    console.log('   1. Go to https://supabase.com/dashboard/project/mpsnsxmznxvoqcslcaom/sql/new');
    console.log('   2. Copy and paste the contents of:');
    console.log('      supabase/migrations/20250131_create_meetshipper_messages.sql');
    console.log('   3. Click "Run" to execute the migration\n');
    process.exit(1);
  }

  // Verify the table was created
  console.log('🔍 Verifying table creation...');
  const { data: tables, error: tablesError } = await supabase
    .from('meetshipper_messages')
    .select('*')
    .limit(0);

  if (tablesError) {
    console.error('❌ Table verification failed:', tablesError.message);
    process.exit(1);
  }

  console.log('✅ meetshipper_messages table exists and is accessible\n');
  console.log('🎉 Migration applied successfully!');
}

applyMigration().catch((error) => {
  console.error('💥 Unexpected error:', error);
  process.exit(1);
});
