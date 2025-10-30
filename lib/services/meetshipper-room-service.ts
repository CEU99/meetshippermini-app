/**
 * MeetShipper Conversation Room Service
 * Handles conversation room lifecycle for accepted matches
 */

import { getServerSupabase } from '../supabase';

export interface MeetshipperRoom {
  id: string;
  match_id: string;
  user_a_fid: number;
  user_b_fid: number;
  is_closed: boolean;
  closed_by_fid: number | null;
  created_at: string;
  closed_at: string | null;
  userA?: {
    fid: number;
    username: string;
    displayName: string;
    avatarUrl: string;
  };
  userB?: {
    fid: number;
    username: string;
    displayName: string;
    avatarUrl: string;
  };
}

/**
 * Ensures a conversation room exists for a match
 * Creates room if it doesn't exist
 */
export async function ensureMeetshipperRoom(
  matchId: string,
  userAFid: number,
  userBFid: number
): Promise<MeetshipperRoom> {
  const supabase = getServerSupabase();

  // Check if room already exists
  const { data: existingRoom } = await supabase
    .from('meetshipper_rooms')
    .select('*')
    .eq('match_id', matchId)
    .single();

  if (existingRoom) {
    return existingRoom;
  }

  // Create new room
  const { data: newRoom, error: roomError } = await supabase
    .from('meetshipper_rooms')
    .insert({
      match_id: matchId,
      user_a_fid: userAFid,
      user_b_fid: userBFid,
    })
    .select()
    .single();

  if (roomError) {
    console.error('Error creating meetshipper room:', roomError);
    throw new Error('Failed to create conversation room');
  }

  return newRoom;
}

/**
 * Gets a conversation room by match ID
 */
export async function getMeetshipperRoomByMatchId(
  matchId: string
): Promise<MeetshipperRoom | null> {
  const supabase = getServerSupabase();

  const { data: room, error } = await supabase
    .from('meetshipper_rooms')
    .select('*')
    .eq('match_id', matchId)
    .single();

  if (error || !room) {
    return null;
  }

  return room;
}

/**
 * Gets a conversation room by ID with user details
 */
export async function getMeetshipperRoomById(
  roomId: string
): Promise<MeetshipperRoom | null> {
  const supabase = getServerSupabase();

  // Fetch room data
  const { data: room, error } = await supabase
    .from('meetshipper_rooms')
    .select('*')
    .eq('id', roomId)
    .single();

  if (error || !room) {
    return null;
  }

  // Fetch user details for both participants
  const { data: users, error: usersError } = await supabase
    .from('users')
    .select('fid, username, display_name, avatar_url')
    .in('fid', [room.user_a_fid, room.user_b_fid]);

  if (usersError || !users) {
    console.error('Error fetching room users:', usersError);
    return room; // Return room without user details
  }

  // Map user data
  const userA = users.find(u => u.fid === room.user_a_fid);
  const userB = users.find(u => u.fid === room.user_b_fid);

  return {
    ...room,
    userA: userA ? {
      fid: userA.fid,
      username: userA.username,
      displayName: userA.display_name,
      avatarUrl: userA.avatar_url,
    } : undefined,
    userB: userB ? {
      fid: userB.fid,
      username: userB.username,
      displayName: userB.display_name,
      avatarUrl: userB.avatar_url,
    } : undefined,
  };
}

/**
 * Closes a conversation room
 */
export async function closeMeetshipperRoom(
  roomId: string,
  closedByFid: number
): Promise<MeetshipperRoom> {
  const supabase = getServerSupabase();

  const { data: room, error } = await supabase
    .from('meetshipper_rooms')
    .update({
      is_closed: true,
      closed_by_fid: closedByFid,
      closed_at: new Date().toISOString(),
    })
    .eq('id', roomId)
    .select()
    .single();

  if (error) {
    console.error('Error closing meetshipper room:', error);
    throw new Error('Failed to close conversation room');
  }

  return room;
}

/**
 * Gets rooms for multiple matches (bulk fetch)
 */
export async function getMeetshipperRoomsByMatchIds(
  matchIds: string[]
): Promise<Map<string, string>> {
  if (matchIds.length === 0) {
    return new Map();
  }

  const supabase = getServerSupabase();

  const { data: rooms, error } = await supabase
    .from('meetshipper_rooms')
    .select('id, match_id')
    .in('match_id', matchIds);

  if (error) {
    console.error('Error fetching meetshipper rooms:', error);
    return new Map();
  }

  const roomMap = new Map<string, string>();
  rooms?.forEach(room => {
    roomMap.set(room.match_id, room.id);
  });

  return roomMap;
}
