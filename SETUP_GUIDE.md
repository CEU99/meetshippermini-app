# Meet Shipper - Complete Setup Guide

This guide will walk you through setting up the Meet Shipper app from scratch.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Step 1: Install Dependencies](#step-1-install-dependencies)
3. [Step 2: Set Up Supabase](#step-2-set-up-supabase)
4. [Step 3: Get Neynar API Key](#step-3-get-neynar-api-key)
5. [Step 4: Configure Environment Variables](#step-4-configure-environment-variables)
6. [Step 5: Test Locally](#step-5-test-locally)
7. [Step 6: Deploy to Vercel](#step-6-deploy-to-vercel)
8. [Troubleshooting](#troubleshooting)

## Prerequisites

Make sure you have:

- [x] Node.js 18+ installed ([Download here](https://nodejs.org/))
- [x] A Farcaster/Warpcast account ([Sign up here](https://warpcast.com/))
- [x] A code editor (VS Code recommended)
- [x] Git installed (optional, for deployment)

## Step 1: Install Dependencies

Open your terminal in the project directory and run:

\`\`\`bash
npm install
\`\`\`

This will install all required packages including:
- Next.js 15
- React
- TypeScript
- Supabase client
- Farcaster AuthKit
- Tailwind CSS

**Expected output**: You should see packages being installed. This may take 1-2 minutes.

## Step 2: Set Up Supabase

### 2.1 Create Supabase Project

1. Go to [https://supabase.com](https://supabase.com)
2. Click "Start your project" or "Sign Up" (free tier is fine)
3. Sign in with GitHub (recommended) or email
4. Click "New Project"
5. Fill in the form:
   - **Name**: meetshipper (or any name you prefer)
   - **Database Password**: Create a strong password (save this!)
   - **Region**: Choose closest to you
   - **Pricing Plan**: Free
6. Click "Create new project"
7. Wait 2-3 minutes for provisioning

### 2.2 Get Supabase Credentials

Once your project is ready:

1. Go to **Project Settings** (gear icon in sidebar)
2. Click **API** in the left menu
3. You'll see:
   - **Project URL**: Copy this (starts with `https://`)
   - **anon public key**: Copy this (starts with `eyJ...`)
   - **service_role key**: Click "Reveal" and copy this (starts with `eyJ...`)

**Important**: Keep the service_role key secret! Never commit it to public repositories.

### 2.3 Create Database Schema

1. In your Supabase dashboard, click **SQL Editor** (in the left sidebar)
2. Click "New Query"
3. Open the `supabase-schema.sql` file from this project in your code editor
4. Copy ALL the SQL code (Ctrl/Cmd + A, then Ctrl/Cmd + C)
5. Paste it into the Supabase SQL Editor
6. Click "Run" or press Ctrl/Cmd + Enter
7. You should see "Success. No rows returned"

**What this does**: Creates 4 tables (users, matches, messages, user_friends), triggers, functions, and views.

### 2.4 Verify Tables Created

1. In Supabase dashboard, click **Table Editor**
2. You should see these tables in the dropdown:
   - users
   - matches
   - messages
   - user_friends

If you see all 4 tables, you're good to go!

## Step 3: Get Neynar API Key

Neynar provides API access to Farcaster data (user profiles, follows, etc.)

### 3.1 Sign Up for Neynar

1. Go to [https://neynar.com](https://neynar.com)
2. Click "Get Started" or "Sign Up"
3. Sign up with your email
4. Verify your email

### 3.2 Create API Key

1. Once logged in, go to the [Dashboard](https://neynar.com/dashboard)
2. Click "API Keys" or "Create API Key"
3. Give it a name like "meetshipper-dev"
4. Click "Create"
5. Copy the API key (starts with something like `NEYNAR-...`)

**Important**: Save this key! You won't be able to see it again.

**Free Tier**: Neynar's free tier should be sufficient for development and small-scale use.

## Step 4: Configure Environment Variables

### 4.1 Create .env.local File

1. In the project root, copy the example file:
   \`\`\`bash
   cp .env.local.example .env.local
   \`\`\`

2. Open `.env.local` in your code editor

### 4.2 Fill in the Variables

Replace the placeholder values with your actual credentials:

\`\`\`env
# Supabase Configuration (from Step 2.2)
NEXT_PUBLIC_SUPABASE_URL=https://your-project-id.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGc...your_anon_key_here
SUPABASE_SERVICE_ROLE_KEY=eyJhbGc...your_service_role_key_here

# Neynar API Configuration (from Step 3.2)
NEYNAR_API_KEY=NEYNAR-your-api-key-here

# JWT Secret (generate a new one)
JWT_SECRET=your_random_jwt_secret_here

# Next.js Configuration
NEXT_PUBLIC_APP_URL=http://localhost:3000
\`\`\`

### 4.3 Generate JWT Secret

For the `JWT_SECRET`, generate a random string:

**On Mac/Linux:**
\`\`\`bash
openssl rand -base64 32
\`\`\`

**On Windows (PowerShell):**
\`\`\`powershell
$randomBytes = New-Object Byte[] 32
[System.Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($randomBytes)
[Convert]::ToBase64String($randomBytes)
\`\`\`

**Or use an online generator**: [https://generate-secret.vercel.app/32](https://generate-secret.vercel.app/32)

Copy the output and paste it as your `JWT_SECRET`.

### 4.4 Verify .env.local

Double-check that:
- [ ] No placeholder text remains (like `your_project_id`)
- [ ] No spaces around the `=` signs
- [ ] The file is named exactly `.env.local` (not `.env.local.txt`)
- [ ] All 6 variables are filled in

## Step 5: Test Locally

### 5.1 Start Development Server

\`\`\`bash
npm run dev
\`\`\`

**Expected output**:
\`\`\`
  ▲ Next.js 15.x.x
  - Local:        http://localhost:3000
  - Ready in X.Xs
\`\`\`

### 5.2 Open the App

1. Open your browser
2. Go to [http://localhost:3000](http://localhost:3000)
3. You should see the "Meet Shipper" landing page

### 5.3 Test Farcaster Login

1. Click **"Sign in with Farcaster"** button
2. A QR code should appear
3. Open **Warpcast** app on your phone
4. Scan the QR code
5. Approve the sign-in request in Warpcast
6. You should be redirected to the dashboard

**Troubleshooting**: If QR code doesn't appear, check the browser console (F12) for errors.

### 5.4 Test Creating a Match

1. On the dashboard, click **"Create New Match"**
2. You should see your following list from Farcaster
3. Select two users (if you don't have friends on Farcaster, you won't be able to test this fully)
4. Add an optional message
5. Click **"Create Match"**
6. You should be redirected to the inbox

### 5.5 Test Inbox

1. Go to **Inbox** from the navigation
2. You should see the match you just created
3. Click on it to see details
4. If you matched yourself with someone, you can test messaging (in a real scenario, both parties need to accept first)

## Step 6: Deploy to Vercel

### 6.1 Prerequisites

- [ ] Code is in a Git repository (GitHub, GitLab, or Bitbucket)
- [ ] You have a Vercel account ([sign up here](https://vercel.com/signup))

### 6.2 Push to GitHub

If you haven't already:

\`\`\`bash
git init
git add .
git commit -m "Initial commit - Meet Shipper app"
git remote add origin https://github.com/your-username/meetshipper.git
git push -u origin main
\`\`\`

### 6.3 Import to Vercel

1. Go to [https://vercel.com](https://vercel.com)
2. Click "Add New..." > "Project"
3. Import your GitHub repository
4. Vercel will auto-detect Next.js
5. Click "Deploy" (don't add env vars yet)
6. Wait for the initial build (it will fail, but that's okay)

### 6.4 Add Environment Variables

1. Go to your Vercel project dashboard
2. Click "Settings" tab
3. Click "Environment Variables" in sidebar
4. Add each variable from your `.env.local`:
   - Name: `NEXT_PUBLIC_SUPABASE_URL`
   - Value: Your Supabase URL
   - Environments: Check all (Production, Preview, Development)
   - Click "Save"

5. Repeat for all 6 variables:
   - `NEXT_PUBLIC_SUPABASE_URL`
   - `NEXT_PUBLIC_SUPABASE_ANON_KEY`
   - `SUPABASE_SERVICE_ROLE_KEY`
   - `NEYNAR_API_KEY`
   - `JWT_SECRET`
   - `NEXT_PUBLIC_APP_URL` (set to your Vercel URL, e.g., `https://meetshipper.vercel.app`)

### 6.5 Redeploy

1. Go to "Deployments" tab
2. Click the three dots (•••) on the latest deployment
3. Click "Redeploy"
4. Wait for the build to complete (2-3 minutes)
5. Click "Visit" to see your live app!

### 6.6 Test Production

1. Visit your Vercel URL
2. Test the Farcaster login flow
3. Create a test match
4. Verify everything works

## Troubleshooting

### Database Connection Error

**Error**: "Failed to connect to database"

**Solution**:
1. Verify your Supabase credentials in `.env.local`
2. Check that the Supabase project is active (not paused)
3. Ensure the SQL schema was run successfully

### Farcaster Login Not Working

**Error**: QR code doesn't appear or scan fails

**Solutions**:
1. Clear browser cache and cookies
2. Try a different browser
3. Ensure you're using the latest Warpcast app
4. Check browser console for CORS errors

### Neynar API Error

**Error**: "Failed to fetch following list"

**Solutions**:
1. Verify `NEYNAR_API_KEY` in `.env.local`
2. Check you haven't exceeded rate limits
3. Verify API key is valid in Neynar dashboard
4. Ensure there are no extra spaces in the env variable

### Build Errors on Vercel

**Error**: Build fails on Vercel

**Solutions**:
1. Check that ALL environment variables are set in Vercel
2. Ensure variable names match exactly (case-sensitive)
3. Check Vercel build logs for specific errors
4. Try redeploying after fixing env vars

### TypeScript Errors

**Error**: Type errors during development

**Solutions**:
1. Restart your editor/TypeScript server
2. Run `npm run build` locally to check for errors
3. Ensure all packages are installed (`npm install`)

## Next Steps

Now that your app is set up:

1. **Customize**: Edit the landing page text, colors, etc.
2. **Add Features**: Check the README for ideas
3. **Share**: Invite friends to test the app
4. **Monitor**: Check Supabase dashboard for usage stats

## Getting Help

If you're stuck:

1. Check the main README.md for additional info
2. Review Vercel deployment logs
3. Check Supabase project logs
4. Look at browser console errors (F12)

## Security Checklist

Before going to production:

- [ ] Changed `JWT_SECRET` from any default value
- [ ] Verified `.env.local` is in `.gitignore`
- [ ] Confirmed Supabase service key is not in any public files
- [ ] Set up Supabase RLS policies (optional, for added security)
- [ ] Updated `NEXT_PUBLIC_APP_URL` to production domain

## Success!

You should now have a fully functional Meet Shipper app! 🎉

Start matching friends and building your Farcaster community!
