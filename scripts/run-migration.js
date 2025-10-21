#!/usr/bin/env node
/**
 * Script to run a Supabase migration
 * Usage: node scripts/run-migration.js <migration-file-name>
 * Example: node scripts/run-migration.js 20250122_create_match_suggestions.sql
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
  const migrationFile = process.argv[2];

  if (!migrationFile) {
    console.error('❌ Please provide a migration file name');
    console.error('Usage: node scripts/run-migration.js <migration-file-name>');
    console.error('Example: node scripts/run-migration.js 20250122_create_match_suggestions.sql');
    process.exit(1);
  }

  console.log(`🔧 Running migration: ${migrationFile}\n`);

  // Check environment variables
  if (!process.env.NEXT_PUBLIC_SUPABASE_URL) {
    console.error('❌ Missing NEXT_PUBLIC_SUPABASE_URL');
    process.exit(1);
  }

  if (!process.env.SUPABASE_SERVICE_ROLE_KEY) {
    console.error('❌ Missing SUPABASE_SERVICE_ROLE_KEY');
    process.exit(1);
  }

  // Read the migration file
  const migrationPath = path.join(__dirname, '..', 'supabase', 'migrations', migrationFile);

  if (!fs.existsSync(migrationPath)) {
    console.error(`❌ Migration file not found: ${migrationPath}`);
    console.error('\nAvailable migrations:');
    const migrationsDir = path.join(__dirname, '..', 'supabase', 'migrations');
    const files = fs.readdirSync(migrationsDir);
    files.forEach(f => console.error(`  - ${f}`));
    process.exit(1);
  }

  const sql = fs.readFileSync(migrationPath, 'utf8');
  console.log('✅ Loaded migration file\n');
  console.log(`📄 File size: ${sql.length} bytes\n`);

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
  console.log('⚠️  NOTE: Supabase JS client cannot execute raw SQL directly.');
  console.log('   You need to run this migration through one of these methods:\n');
  console.log('   1. Supabase Dashboard → SQL Editor');
  console.log('   2. Supabase CLI: supabase db push');
  console.log('   3. psql command-line tool\n');

  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('📋 MIGRATION SQL');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
  console.log('Please copy the following SQL and run it in your Supabase SQL Editor:\n');
  console.log(sql);
  console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  // Write to a temporary file for easy access
  const tempFile = path.join(__dirname, '..', 'temp-migration.sql');
  fs.writeFileSync(tempFile, sql);
  console.log(`✅ Migration SQL also saved to: temp-migration.sql\n`);
  console.log('You can now:');
  console.log('  1. Open your Supabase Dashboard');
  console.log('  2. Go to SQL Editor');
  console.log('  3. Copy the contents of temp-migration.sql');
  console.log('  4. Paste and run it\n');
}

main().catch(error => {
  console.error('❌ Unexpected error:', error);
  process.exit(1);
});
