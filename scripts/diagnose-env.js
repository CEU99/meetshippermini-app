#!/usr/bin/env node

/**
 * Diagnostic Script for Environment Variable Issues
 *
 * This script checks your .env.local file and identifies common issues
 * that can cause "fetch failed" errors in local development.
 *
 * Usage: node scripts/diagnose-env.js
 */

const fs = require('fs');
const path = require('path');

console.log('🔍 Diagnosing environment configuration...\n');

// Check if .env.local exists
const envPath = path.join(process.cwd(), '.env.local');
if (!fs.existsSync(envPath)) {
  console.error('❌ ERROR: .env.local file not found!');
  console.log('\n💡 Solution:');
  console.log('   1. Copy .env.example to .env.local');
  console.log('   2. Fill in your Supabase credentials');
  console.log('   3. Restart dev server\n');
  process.exit(1);
}

console.log('✅ .env.local file exists\n');

// Read and parse .env.local
const envContent = fs.readFileSync(envPath, 'utf-8');
const envLines = envContent.split('\n');
const envVars = {};

envLines.forEach((line) => {
  const trimmed = line.trim();
  if (!trimmed || trimmed.startsWith('#')) return;

  const [key, ...valueParts] = trimmed.split('=');
  if (key && valueParts.length > 0) {
    envVars[key.trim()] = valueParts.join('=').trim();
  }
});

console.log('📋 Checking required environment variables:\n');

// Check required vars
const requiredVars = {
  'NEXT_PUBLIC_SUPABASE_URL': {
    required: true,
    placeholder: ['your-project-id', 'supabase.co/your-project'],
    example: 'https://abcdefghijk.supabase.co'
  },
  'NEXT_PUBLIC_SUPABASE_ANON_KEY': {
    required: true,
    placeholder: ['your-anon-key-here', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.example'],
    example: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
    minLength: 100
  },
  'SUPABASE_SERVICE_ROLE_KEY': {
    required: true,
    placeholder: ['your-service-role-key-here', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.example'],
    example: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
    minLength: 100
  },
  'JWT_SECRET': {
    required: false,
    placeholder: ['your-secret-here'],
    default: 'dev-jwt-secret-change-in-production'
  }
};

let hasErrors = false;
let hasWarnings = false;

Object.entries(requiredVars).forEach(([key, config]) => {
  const value = envVars[key];

  if (!value) {
    if (config.required) {
      console.log(`❌ ${key}: MISSING`);
      console.log(`   Add this to .env.local: ${key}=${config.example}\n`);
      hasErrors = true;
    } else {
      console.log(`⚠️  ${key}: Not set (optional)`);
      if (config.default) {
        console.log(`   Using default: ${config.default}\n`);
      }
      hasWarnings = true;
    }
    return;
  }

  // Check for placeholder values
  const isPlaceholder = config.placeholder?.some(ph => value.includes(ph));
  if (isPlaceholder) {
    console.log(`❌ ${key}: PLACEHOLDER VALUE DETECTED`);
    console.log(`   Current: ${value.substring(0, 50)}...`);
    console.log(`   This is not a real credential!`);
    console.log(`   Get your real key from: https://supabase.com/dashboard\n`);
    hasErrors = true;
    return;
  }

  // Check minimum length (for keys)
  if (config.minLength && value.length < config.minLength) {
    console.log(`⚠️  ${key}: TOO SHORT (${value.length} chars, expected ${config.minLength}+)`);
    console.log(`   This might be invalid. Double-check your Supabase dashboard.\n`);
    hasWarnings = true;
    return;
  }

  // Check URL format
  if (key.includes('URL')) {
    try {
      const url = new URL(value);
      if (!url.hostname.includes('supabase.co')) {
        console.log(`⚠️  ${key}: URL doesn't look like a Supabase URL`);
        console.log(`   Expected format: https://your-project-id.supabase.co\n`);
        hasWarnings = true;
      } else {
        console.log(`✅ ${key}: Valid (${url.hostname})\n`);
      }
    } catch (e) {
      console.log(`❌ ${key}: INVALID URL FORMAT`);
      console.log(`   Current: ${value}`);
      console.log(`   Expected format: https://your-project-id.supabase.co\n`);
      hasErrors = true;
    }
    return;
  }

  // JWT tokens should start with eyJ
  if (key.includes('KEY') || key.includes('SECRET')) {
    if (key.includes('SUPABASE') && !value.startsWith('eyJ')) {
      console.log(`⚠️  ${key}: Doesn't look like a JWT token`);
      console.log(`   Supabase keys usually start with "eyJ..."\n`);
      hasWarnings = true;
    } else {
      const displayValue = value.substring(0, 30) + '...' + value.substring(value.length - 10);
      console.log(`✅ ${key}: Set (${displayValue})\n`);
    }
    return;
  }

  console.log(`✅ ${key}: ${value}\n`);
});

console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

// Summary
if (hasErrors) {
  console.log('❌ ERRORS FOUND - Your app will not work locally!\n');
  console.log('📝 How to fix:');
  console.log('   1. Go to https://supabase.com/dashboard');
  console.log('   2. Select your project');
  console.log('   3. Go to Settings → API');
  console.log('   4. Copy the "Project URL" and paste it as NEXT_PUBLIC_SUPABASE_URL');
  console.log('   5. Copy the "anon public" key and paste it as NEXT_PUBLIC_SUPABASE_ANON_KEY');
  console.log('   6. Copy the "service_role" key and paste it as SUPABASE_SERVICE_ROLE_KEY');
  console.log('   7. Restart your dev server (Ctrl+C, then npm run dev)\n');
  console.log('📖 See FIX_LOCAL_FETCH_ERROR.md for detailed instructions.\n');
  process.exit(1);
} else if (hasWarnings) {
  console.log('⚠️  WARNINGS FOUND - Your app might work, but double-check these values.\n');
  console.log('💡 If you experience errors, verify your Supabase credentials at:');
  console.log('   https://supabase.com/dashboard → Settings → API\n');
  process.exit(0);
} else {
  console.log('✅ ALL CHECKS PASSED - Environment looks good!\n');
  console.log('🚀 Your local dev environment should work correctly.\n');
  console.log('💡 If you still see errors:');
  console.log('   1. Restart your dev server (Ctrl+C, then npm run dev)');
  console.log('   2. Check database migrations are applied');
  console.log('   3. See FIX_LOCAL_FETCH_ERROR.md for more troubleshooting\n');
  process.exit(0);
}
