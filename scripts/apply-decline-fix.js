#!/usr/bin/env node
/**
 * Script to apply the decline button fix directly to the database
 * This updates the add_match_cooldown() function to handle duplicates
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

const fixSQL = `
CREATE OR REPLACE FUNCTION public.add_match_cooldown()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_min_fid BIGINT;
  v_max_fid BIGINT;
  v_existing_id UUID;
BEGIN
  IF NEW.status = 'declined' AND (OLD.status IS NULL OR OLD.status IS DISTINCT FROM 'declined') THEN
    v_min_fid := LEAST(NEW.user_a_fid, NEW.user_b_fid);
    v_max_fid := GREATEST(NEW.user_a_fid, NEW.user_b_fid);

    SELECT id INTO v_existing_id
    FROM public.match_cooldowns
    WHERE LEAST(user_a_fid, user_b_fid) = v_min_fid
      AND GREATEST(user_a_fid, user_b_fid) = v_max_fid;

    IF v_existing_id IS NOT NULL THEN
      UPDATE public.match_cooldowns
      SET declined_at = NOW(), cooldown_until = NOW() + INTERVAL '7 days'
      WHERE id = v_existing_id;
    ELSE
      INSERT INTO public.match_cooldowns (user_a_fid, user_b_fid, declined_at, cooldown_until)
      VALUES (v_min_fid, v_max_fid, NOW(), NOW() + INTERVAL '7 days');
    END IF;
  END IF;
  RETURN NEW;
END;
$$;
`;

async function main() {
  console.log('🔧 Applying decline button fix...\n');

  if (!process.env.NEXT_PUBLIC_SUPABASE_URL || !process.env.SUPABASE_SERVICE_ROLE_KEY) {
    console.error('❌ Missing Supabase credentials in .env.local');
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

  console.log('✅ Connected to Supabase\n');

  // Unfortunately, Supabase JS client doesn't support raw SQL execution
  // We need to use the REST API directly
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('⚠️  MANUAL ACTION REQUIRED');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  console.log('The Supabase JS client cannot execute DDL statements directly.');
  console.log('You need to apply the fix manually via the Supabase Dashboard.\n');

  console.log('📋 Steps to Fix:\n');
  console.log('1. Open your Supabase Dashboard:');
  console.log('   https://mpsnsxmznxvoqcslcaom.supabase.co\n');
  console.log('2. Navigate to: SQL Editor → New Query\n');
  console.log('3. Copy this SQL (also saved to fix-decline-MINIMAL.sql):\n');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log(fixSQL);
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
  console.log('4. Paste it into the SQL editor and click RUN\n');
  console.log('5. You should see: "Success. No rows returned"\n');
  console.log('6. Test declining a match - it should work now!\n');

  // Test if we can at least verify the current state
  console.log('🔍 Checking current database state...\n');

  const { data: cooldowns, error: cooldownError } = await supabase
    .from('match_cooldowns')
    .select('*')
    .limit(5);

  if (cooldownError) {
    console.log('⚠️  Could not check cooldowns table:', cooldownError.message);
  } else {
    console.log(`✅ Cooldowns table exists (${cooldowns?.length || 0} entries found)`);
  }

  const { data: matches, error: matchError } = await supabase
    .from('matches')
    .select('id, status')
    .in('status', ['proposed', 'pending'])
    .limit(1);

  if (matchError) {
    console.log('⚠️  Could not check matches table:', matchError.message);
  } else {
    console.log(`✅ Found ${matches?.length || 0} pending match(es) to test with\n`);
  }

  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('Next: Apply the SQL fix in Supabase Dashboard');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
}

main().catch(error => {
  console.error('❌ Error:', error);
  process.exit(1);
});
