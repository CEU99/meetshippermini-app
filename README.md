# Meet Shipper - Farcaster Mini App

A Farcaster mini-app that helps you connect friends from your network by creating meaningful introductions and matches.

## Features

- **Farcaster Authentication**: Sign in with your Farcaster account using AuthKit
- **Create Matches**: Introduce two friends from your Farcaster network
- **Real-time Inbox**: View and manage all your matches in one place
- **Built-in Messaging**: Chat with matched users after both parties accept
- **Match Management**: Accept or decline incoming match requests
- **Dashboard**: Track your match statistics and activity

## Tech Stack

- **Frontend**: Next.js 15 (App Router), React, TypeScript, Tailwind CSS
- **Authentication**: Farcaster AuthKit
- **Backend**: Next.js API Routes, Supabase (PostgreSQL)
- **Data Fetching**: Neynar API (for Farcaster social graph data)
- **Deployment**: Vercel

## Prerequisites

Before you begin, make sure you have:

1. Node.js 18+ installed
2. A Supabase account (free tier works)
3. A Neynar API key (sign up at https://neynar.com)
4. A Farcaster account (for testing)

## Setup Instructions

### 1. Clone and Install Dependencies

\`\`\`bash
npm install
\`\`\`

### 2. Set Up Supabase

1. Go to https://supabase.com and create a new project
2. Wait for the project to be provisioned (this may take a few minutes)
3. Once ready, go to **Project Settings > API** to find your:
   - Project URL
   - `anon` public key
   - `service_role` key (keep this secret!)

4. Go to the **SQL Editor** in your Supabase dashboard
5. Open the `supabase-schema.sql` file from this project
6. Copy all the SQL and run it in the Supabase SQL Editor
7. This will create all necessary tables, functions, triggers, and views

### 3. Get Neynar API Key

1. Sign up at https://neynar.com
2. Create a new API key from the dashboard
3. Copy your API key

### 4. Configure Environment Variables

Create a `.env.local` file in the root directory:

\`\`\`bash
cp .env.local.example .env.local
\`\`\`

Edit `.env.local` and fill in your credentials:

\`\`\`env
# Supabase Configuration
NEXT_PUBLIC_SUPABASE_URL=your_supabase_project_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key

# Neynar API Configuration
NEYNAR_API_KEY=your_neynar_api_key

# JWT Secret (generate a random string)
JWT_SECRET=your_random_jwt_secret_here

# Next.js Configuration
NEXT_PUBLIC_APP_URL=http://localhost:3000
\`\`\`

**Important**: Generate a secure random string for `JWT_SECRET`. You can use:

\`\`\`bash
openssl rand -base64 32
\`\`\`

### 5. Run the Development Server

\`\`\`bash
npm run dev
\`\`\`

Open [http://localhost:3000](http://localhost:3000) in your browser.

### 6. Test the Application

1. Click "Sign in with Farcaster"
2. Scan the QR code with your Warpcast mobile app
3. Approve the sign-in request
4. You should be redirected to the dashboard
5. Try creating a match by selecting two users from your following list
6. Check the inbox to see your matches

## Project Structure

\`\`\`
meetshippermini-app/
├── app/
│   ├── api/
│   │   ├── auth/          # Authentication endpoints
│   │   ├── matches/       # Match CRUD operations
│   │   ├── messages/      # Message endpoints
│   │   └── farcaster/     # Farcaster data fetching
│   ├── dashboard/         # User dashboard page
│   ├── mini/
│   │   ├── create/        # Create match page
│   │   └── inbox/         # Inbox/messaging page
│   ├── layout.tsx         # Root layout with auth provider
│   └── page.tsx           # Landing page
├── components/
│   ├── providers/         # React context providers
│   └── shared/            # Shared UI components
├── lib/
│   ├── auth.ts            # JWT session management
│   ├── neynar.ts          # Neynar API client
│   ├── supabase.ts        # Supabase client setup
│   └── types.ts           # TypeScript type definitions
├── supabase-schema.sql    # Database schema
└── README.md
\`\`\`

## Database Schema

The app uses the following main tables in Supabase:

- **users**: Stores Farcaster user profile information
- **matches**: Stores match/introduction records
- **messages**: Stores chat messages between matched users
- **user_friends**: (Optional) Caches Farcaster follow relationships

See `supabase-schema.sql` for the complete schema with triggers, functions, and views.

## API Endpoints

### Authentication
- `POST /api/auth/session` - Create user session after Farcaster login
- `POST /api/auth/logout` - Clear user session
- `GET /api/auth/me` - Get current user session

### Matches
- `GET /api/matches` - Get all matches for authenticated user
- `POST /api/matches` - Create a new match
- `GET /api/matches/[id]` - Get specific match details
- `PATCH /api/matches/[id]` - Accept/decline a match
- `DELETE /api/matches/[id]` - Cancel a match (creator only)

### Messages
- `GET /api/messages?matchId=xxx` - Get messages for a match
- `POST /api/messages` - Send a new message

### Farcaster
- `GET /api/farcaster/following` - Get user's following list from Farcaster

## Deploying to Vercel

### 1. Push to GitHub

Make sure your code is in a GitHub repository.

### 2. Import to Vercel

1. Go to https://vercel.com
2. Click "Import Project"
3. Select your GitHub repository
4. Vercel will auto-detect Next.js

### 3. Configure Environment Variables

In the Vercel project settings, add all the environment variables from your `.env.local`:

- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`
- `NEYNAR_API_KEY`
- `JWT_SECRET`
- `NEXT_PUBLIC_APP_URL` (set to your Vercel domain, e.g., `https://your-app.vercel.app`)

### 4. Deploy

Click "Deploy" and wait for the build to complete.

### 5. Update Farcaster AuthKit Configuration

If needed, update the domain in the `FarcasterAuthProvider.tsx` to match your production domain.

## Troubleshooting

### "Can't reach database server" Error

This was a common issue with Prisma + Neon on Vercel. We've solved it by using Supabase, which uses HTTP requests instead of persistent connections.

### Neynar API Errors

- Make sure your `NEYNAR_API_KEY` is correctly set
- Check that you haven't exceeded the rate limits
- Verify the API key is valid in the Neynar dashboard

### Farcaster Login Not Working

- Ensure you're using a valid Farcaster account
- Check that the Warpcast mobile app is up to date
- Try clearing your browser cache and cookies

### Messages Not Appearing

- Make sure both users have accepted the match
- Check the browser console for API errors
- Verify the Supabase connection is working

## Key Improvements from Previous Implementation

1. **Supabase Instead of Prisma/Neon**: Solves serverless connection issues
2. **Proper Session Management**: JWT-based sessions with httpOnly cookies
3. **Neynar Integration**: Reliable Farcaster data fetching
4. **Real-time Capabilities**: Built-in support for Supabase real-time (can be enabled)
5. **Better Error Handling**: Comprehensive error states and user feedback
6. **Responsive Design**: Works on mobile and desktop
7. **Type Safety**: Full TypeScript support throughout

## Future Enhancements

- [ ] Real-time message updates using Supabase subscriptions
- [ ] Notifications for new matches and messages
- [ ] Search functionality for users
- [ ] Match recommendations based on mutual connections
- [ ] Profile customization
- [ ] Match history and analytics
- [ ] Export/import functionality

## Support

If you encounter any issues or have questions:

1. Check the troubleshooting section above
2. Review the Supabase logs in the dashboard
3. Check Vercel deployment logs
4. Verify all environment variables are set correctly

## License

MIT

## Credits

Built with:
- [Next.js](https://nextjs.org/)
- [Supabase](https://supabase.com/)
- [Farcaster](https://www.farcaster.xyz/)
- [Neynar](https://neynar.com/)
- [Tailwind CSS](https://tailwindcss.com/)
