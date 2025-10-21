# MeetShipper Mini-App Setup Guide

## Quick Start

### 1. Install Dependencies

```bash
pnpm install
```

### 2. Set Up Environment Variables

The application requires Supabase credentials to run. Follow these steps:

#### Get Your Supabase Credentials

1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your project (or create a new one)
3. Go to **Settings** → **API**
4. Copy the following values:
   - **Project URL** → use for `NEXT_PUBLIC_SUPABASE_URL`
   - **anon/public key** → use for `NEXT_PUBLIC_SUPABASE_ANON_KEY`
   - **service_role key** → use for `SUPABASE_SERVICE_ROLE_KEY` ⚠️ Keep this secret!

#### Configure Your Environment

1. Open `.env.local` in your project root
2. Replace the placeholder values with your actual Supabase credentials:

```env
# Replace these with your actual values
NEXT_PUBLIC_SUPABASE_URL=https://xxxxxxxxxxxxx.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# Generate a random JWT secret (or use any random string)
JWT_SECRET=your-random-secret-at-least-32-characters-long
```

⚠️ **Security Warning**:
- Never commit `.env.local` to git
- Never share your `SUPABASE_SERVICE_ROLE_KEY` publicly
- The service role key has full database access

### 3. Run the Development Server

```bash
pnpm dev
```

Open [http://localhost:3000](http://localhost:3000) to see your app.

## Environment Variables Reference

### Required Variables

| Variable | Description | Where to Get It |
|----------|-------------|-----------------|
| `NEXT_PUBLIC_SUPABASE_URL` | Your Supabase project URL | Supabase Dashboard → Settings → API |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Public anon key (safe for browser) | Supabase Dashboard → Settings → API |
| `SUPABASE_SERVICE_ROLE_KEY` | Service role key (server-only, secret!) | Supabase Dashboard → Settings → API |
| `JWT_SECRET` | Secret for signing JWT tokens | Generate a random 32+ character string |

### Optional Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `NEXT_PUBLIC_RPC_URL` | Optimism RPC URL for Farcaster | `https://mainnet.optimism.io` |
| `WHEREBY_API_KEY` | Whereby API key for video meetings | Falls back to Google Meet |
| `HUDDLE01_API_KEY` | Huddle01 API key for video meetings | Falls back to Google Meet |
| `CRON_SECRET` | Secret for protecting cron endpoints | None (allows all in dev) |

## Database Setup

After configuring your environment variables, you'll need to set up your Supabase database:

1. Go to your Supabase project
2. Navigate to **SQL Editor**
3. Run the migration files in the `supabase/` directory (if they exist)
4. Or create the necessary tables as per your schema

## Troubleshooting

### Error: Missing env.NEXT_PUBLIC_SUPABASE_URL

**Solution**: Make sure you've created `.env.local` and added your Supabase credentials.

### Error: Invalid API key

**Solution**:
- Double-check you copied the correct keys from Supabase
- Make sure there are no extra spaces or line breaks
- Verify you're using the right project's keys

### Development Login Not Working

If you're in development mode, you can use the dev login endpoint:

```
http://localhost:3000/api/dev/login?fid=1111&username=testuser&displayName=Test%20User
```

This bypasses Farcaster authentication for local development.

## Building for Production

```bash
pnpm build
pnpm start
```

### Before Deploying to Vercel

1. Add all environment variables in the Vercel dashboard
2. Make sure to set `NODE_ENV=production`
3. Never expose your `SUPABASE_SERVICE_ROLE_KEY` in client-side code

## Additional Resources

- [Supabase Documentation](https://supabase.com/docs)
- [Next.js Documentation](https://nextjs.org/docs)
- [Farcaster Auth Kit](https://docs.farcaster.xyz/auth-kit/introduction)

## Support

If you encounter issues:
1. Check that all environment variables are set correctly
2. Verify your Supabase project is active
3. Check the browser console and server logs for specific errors
4. Review the error stack trace for more details
