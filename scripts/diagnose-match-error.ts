#!/usr/bin/env node
/**
 * Diagnostic script to test match creation and database connectivity
 */

import { config } from 'dotenv';
import { resolve } from 'path';

// Load environment variables
config({ path: resolve(process.cwd(), '.env.local') });

import { getServerSupabase } from '../lib/supabase';

async function diagnose() {
  console.log('\n=== Match Creation Diagnostic ===\n');

  try {
    // 1. Check database connection
    console.log('1. Testing database connection...');
    const supabase = getServerSupabase();

    const { data: testQuery, error: testError } = await supabase
      .from('users')
      .select('count')
      .limit(1);

    if (testError) {
      console.error('❌ Database connection failed:', testError.message);
      console.error('   Details:', testError);
      return;
    }
    console.log('✅ Database connection successful');

    // 2. Check matches table
    console.log('\n2. Testing matches table access...');
    const { data: matchTest, error: matchError } = await supabase
      .from('matches')
      .select('id')
      .limit(1);

    if (matchError) {
      console.error('❌ Matches table access failed:', matchError.message);
      console.error('   Details:', matchError);
      return;
    }
    console.log('✅ Matches table accessible');

    // 3. Check messages table
    console.log('\n3. Testing messages table access...');
    const { data: msgTest, error: msgError } = await supabase
      .from('messages')
      .select('id')
      .limit(1);

    if (msgError) {
      console.error('❌ Messages table access failed:', msgError.message);
      console.error('   Details:', msgError);
      return;
    }
    console.log('✅ Messages table accessible');

    // 4. Check match_details view
    console.log('\n4. Testing match_details view access...');
    const { data: viewTest, error: viewError } = await supabase
      .from('match_details')
      .select('id')
      .limit(1);

    if (viewError) {
      console.error('❌ Match_details view access failed:', viewError.message);
      console.error('   Details:', viewError);
      return;
    }
    console.log('✅ Match_details view accessible');

    // 5. Check environment variables
    console.log('\n5. Checking environment variables...');
    const requiredEnvVars = [
      'DATABASE_URL',
      'SUPABASE_URL',
      'SUPABASE_SERVICE_ROLE_KEY',
      'NEYNAR_API_KEY'
    ];

    const missingVars = requiredEnvVars.filter(varName => !process.env[varName]);

    if (missingVars.length > 0) {
      console.error('❌ Missing environment variables:', missingVars.join(', '));
    } else {
      console.log('✅ All required environment variables present');
    }

    console.log('\n=== Diagnostic Complete ===\n');
    console.log('If all checks passed, the issue may be with:');
    console.log('  - Session/authentication');
    console.log('  - Specific validation rules (cooldown, pending limits, etc.)');
    console.log('  - Check browser console and network tab for specific error messages');

  } catch (error) {
    console.error('\n❌ Unexpected error during diagnostic:');
    console.error(error);
  }
}

diagnose().catch(console.error);
