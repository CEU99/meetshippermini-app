#!/usr/bin/env node

/**
 * Interactive Environment Variable Updater
 *
 * This script helps you update your .env.local file with real Supabase credentials.
 *
 * Usage: node scripts/update-env.js
 */

const fs = require('fs');
const path = require('path');
const readline = require('readline');

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

const question = (query) => new Promise((resolve) => rl.question(query, resolve));

console.log('🔧 Environment Variable Updater\n');
console.log('This script will help you update your .env.local file with real Supabase credentials.\n');
console.log('📋 Before starting, open: https://supabase.com/dashboard');
console.log('   → Select your project');
console.log('   → Go to Settings → API\n');

const envPath = path.join(process.cwd(), '.env.local');

async function main() {
  try {
    // Check if .env.local exists
    if (!fs.existsSync(envPath)) {
      console.error('❌ .env.local file not found!');
      console.log('💡 Creating from .env.example...\n');

      const examplePath = path.join(process.cwd(), '.env.example');
      if (fs.existsSync(examplePath)) {
        fs.copyFileSync(examplePath, envPath);
        console.log('✅ Created .env.local from .env.example\n');
      } else {
        console.error('❌ .env.example not found either. Creating new file...\n');
        fs.writeFileSync(envPath, '# Supabase Configuration\n');
      }
    }

    // Read current env file
    let envContent = fs.readFileSync(envPath, 'utf-8');

    console.log('📝 Please paste your Supabase credentials:\n');

    // Get Supabase URL
    const url = await question('1. Project URL (e.g., https://abcdefg.supabase.co): ');
    if (url && url.trim()) {
      const urlTrimmed = url.trim();
      if (urlTrimmed.includes('supabase.co')) {
        envContent = updateEnvVar(envContent, 'NEXT_PUBLIC_SUPABASE_URL', urlTrimmed);
        console.log('   ✅ URL updated\n');
      } else {
        console.log('   ⚠️  Warning: URL doesn\'t look like a Supabase URL\n');
      }
    }

    // Get anon key
    const anonKey = await question('2. Anon public key (starts with eyJ...): ');
    if (anonKey && anonKey.trim()) {
      const anonKeyTrimmed = anonKey.trim();
      if (anonKeyTrimmed.startsWith('eyJ')) {
        envContent = updateEnvVar(envContent, 'NEXT_PUBLIC_SUPABASE_ANON_KEY', anonKeyTrimmed);
        console.log('   ✅ Anon key updated\n');
      } else {
        console.log('   ⚠️  Warning: Key doesn\'t start with "eyJ" (might be invalid)\n');
      }
    }

    // Get service role key
    const serviceKey = await question('3. Service role key (starts with eyJ...): ');
    if (serviceKey && serviceKey.trim()) {
      const serviceKeyTrimmed = serviceKey.trim();
      if (serviceKeyTrimmed.startsWith('eyJ')) {
        envContent = updateEnvVar(envContent, 'SUPABASE_SERVICE_ROLE_KEY', serviceKeyTrimmed);
        console.log('   ✅ Service role key updated\n');
      } else {
        console.log('   ⚠️  Warning: Key doesn\'t start with "eyJ" (might be invalid)\n');
      }
    }

    // Write back to file
    fs.writeFileSync(envPath, envContent);

    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    console.log('✅ .env.local file updated successfully!\n');
    console.log('🚀 Next steps:');
    console.log('   1. Restart your dev server (Ctrl+C, then npm run dev)');
    console.log('   2. Visit http://localhost:3000/users');
    console.log('   3. Run: node scripts/diagnose-env.js (to verify)\n');

  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  } finally {
    rl.close();
  }
}

function updateEnvVar(content, key, value) {
  const regex = new RegExp(`^${key}=.*$`, 'm');

  if (regex.test(content)) {
    // Update existing line
    return content.replace(regex, `${key}=${value}`);
  } else {
    // Add new line
    return content + `\n${key}=${value}`;
  }
}

main();
