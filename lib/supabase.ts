import { createClient } from '@supabase/supabase-js';

if (!process.env.NEXT_PUBLIC_SUPABASE_URL) {
  throw new Error('Missing env.NEXT_PUBLIC_SUPABASE_URL');
}
if (!process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY) {
  throw new Error('Missing env.NEXT_PUBLIC_SUPABASE_ANON_KEY');
}

// Client for use in browser/client components
export const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY
);

// Server client with service role key for API routes
export function getServerSupabase() {
  if (!process.env.SUPABASE_SERVICE_ROLE_KEY) {
    throw new Error('Missing env.SUPABASE_SERVICE_ROLE_KEY');
  }

  return createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY,
    {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    }
  );
}

// Database type definitions
export interface User {
  fid: number;
  username: string;
  display_name?: string;
  avatar_url?: string;
  bio?: string;
  user_code?: string;
  traits?: string[]; // JSON array of trait tags
  created_at?: string;
  updated_at?: string;
}

export interface Match {
  id: string;
  user_a_fid: number;
  user_b_fid: number;
  created_by_fid: number;
  status: 'pending' | 'accepted' | 'declined' | 'cancelled';
  message?: string;
  a_accepted: boolean;
  b_accepted: boolean;
  created_at: string;
  updated_at: string;
}

export interface Message {
  id: string;
  match_id: string;
  sender_fid: number;
  content: string;
  is_system_message: boolean;
  created_at: string;
}

export interface UserFriend {
  user_fid: number;
  friend_fid: number;
  friend_username: string;
  friend_display_name?: string;
  friend_avatar_url?: string;
  cached_at: string;
}

export interface MatchDetail {
  id: string;
  user_a_fid: number;
  user_a_username: string;
  user_a_display_name?: string;
  user_a_avatar_url?: string;
  user_b_fid: number;
  user_b_username: string;
  user_b_display_name?: string;
  user_b_avatar_url?: string;
  created_by_fid: number;
  creator_username: string;
  creator_display_name?: string;
  creator_avatar_url?: string;
  status: string;
  message?: string;
  a_accepted: boolean;
  b_accepted: boolean;
  created_at: string;
  updated_at: string;
}

export interface MessageDetail {
  id: string;
  match_id: string;
  sender_fid: number;
  sender_username: string;
  sender_display_name?: string;
  sender_avatar_url?: string;
  content: string;
  is_system_message: boolean;
  created_at: string;
}
