/**
 * Chat Room Service
 * Handles chat room lifecycle, TTL management, and closure logic
 */

import { getServerSupabase } from '../supabase';

export interface ChatRoom {
  id: string;
  match_id: string;
  opened_at: string;
  first_join_at: string | null;
  closed_at: string | null;
  ttl_seconds: number;
  is_closed: boolean;
  created_at: string;
  updated_at: string;
}

export interface ChatParticipant {
  room_id: string;
  fid: number;
  joined_at: string;
  completed_at: string | null;
  created_at: string;
  updated_at: string;
}

export interface ChatMessage {
  id: string;
  room_id: string;
  sender_fid: number;
  body: string;
  created_at: string;
}

export interface ChatRoomWithDetails extends ChatRoom {
  participants: ChatParticipant[];
  messages: ChatMessage[];
  remaining_seconds: number;
}

/**
 * Ensures a chat room exists for a match
 * Creates room and participants if they don't exist
 */
export async function ensureChatRoom(
  matchId: string,
  userAFid: number,
  userBFid: number
): Promise<ChatRoom> {
  const supabase = getServerSupabase();

  // Check if room already exists
  const { data: existingRoom } = await supabase
    .from('chat_rooms')
    .select('*')
    .eq('match_id', matchId)
    .single();

  if (existingRoom) {
    return existingRoom;
  }

  // Create new room
  const { data: newRoom, error: roomError } = await supabase
    .from('chat_rooms')
    .insert({
      match_id: matchId,
      opened_at: new Date().toISOString(),
    })
    .select()
    .single();

  if (roomError) {
    console.error('Error creating chat room:', roomError);
    throw new Error('Failed to create chat room');
  }

  // Create participants
  const { error: participantsError } = await supabase
    .from('chat_participants')
    .insert([
      { room_id: newRoom.id, fid: userAFid },
      { room_id: newRoom.id, fid: userBFid },
    ]);

  if (participantsError) {
    console.error('Error creating chat participants:', participantsError);
    throw new Error('Failed to create chat participants');
  }

  return newRoom;
}

/**
 * Gets a chat room by ID with participants and messages
 */
export async function getChatRoom(
  roomId: string,
  limit: number = 100
): Promise<ChatRoomWithDetails | null> {
  const supabase = getServerSupabase();

  // Fetch room
  const { data: room, error: roomError } = await supabase
    .from('chat_rooms')
    .select('*')
    .eq('id', roomId)
    .single();

  if (roomError || !room) {
    console.error('Error fetching chat room:', roomError);
    return null;
  }

  // Check if room should be closed due to TTL expiration
  if (!room.is_closed && room.first_join_at) {
    const shouldClose = await checkAndCloseIfExpired(roomId);
    if (shouldClose) {
      room.is_closed = true;
      room.closed_at = new Date().toISOString();
    }
  }

  // Fetch participants
  const { data: participants, error: participantsError } = await supabase
    .from('chat_participants')
    .select('*')
    .eq('room_id', roomId);

  if (participantsError) {
    console.error('Error fetching chat participants:', participantsError);
    throw new Error('Failed to fetch chat participants');
  }

  // Fetch messages
  const { data: messages, error: messagesError } = await supabase
    .from('chat_messages')
    .select('*')
    .eq('room_id', roomId)
    .order('created_at', { ascending: true })
    .limit(limit);

  if (messagesError) {
    console.error('Error fetching chat messages:', messagesError);
    throw new Error('Failed to fetch chat messages');
  }

  // Calculate remaining seconds
  let remaining_seconds = 0;
  if (!room.is_closed && room.first_join_at) {
    const firstJoinTime = new Date(room.first_join_at).getTime();
    const expiryTime = firstJoinTime + room.ttl_seconds * 1000;
    const now = Date.now();
    remaining_seconds = Math.max(0, Math.floor((expiryTime - now) / 1000));
  }

  return {
    ...room,
    participants: participants || [],
    messages: messages || [],
    remaining_seconds,
  };
}

/**
 * Gets a chat room by match ID
 */
export async function getChatRoomByMatchId(matchId: string): Promise<ChatRoom | null> {
  const supabase = getServerSupabase();

  const { data: room, error } = await supabase
    .from('chat_rooms')
    .select('*')
    .eq('match_id', matchId)
    .single();

  if (error || !room) {
    return null;
  }

  return room;
}

/**
 * Marks the first join timestamp if not already set
 * This starts the 2-hour countdown
 */
export async function markFirstJoin(roomId: string): Promise<void> {
  const supabase = getServerSupabase();

  const { error } = await supabase
    .from('chat_rooms')
    .update({
      first_join_at: new Date().toISOString(),
    })
    .eq('id', roomId)
    .is('first_join_at', null);

  if (error) {
    console.error('Error marking first join:', error);
  }
}

/**
 * Checks if a room is expired and closes it if so
 * Returns true if room was closed
 */
export async function checkAndCloseIfExpired(roomId: string): Promise<boolean> {
  const supabase = getServerSupabase();

  // Fetch room
  const { data: room, error: roomError } = await supabase
    .from('chat_rooms')
    .select('*')
    .eq('id', roomId)
    .single();

  if (roomError || !room) {
    return false;
  }

  // Already closed
  if (room.is_closed) {
    return false;
  }

  // No first join yet, not expired
  if (!room.first_join_at) {
    return false;
  }

  // Check expiration
  const firstJoinTime = new Date(room.first_join_at).getTime();
  const expiryTime = firstJoinTime + room.ttl_seconds * 1000;
  const now = Date.now();

  if (now > expiryTime) {
    await closeRoom(roomId, 'timeout');
    return true;
  }

  return false;
}

/**
 * Marks a participant as completed
 * If both participants are completed, closes the room
 */
export async function markParticipantCompleted(
  roomId: string,
  fid: number
): Promise<{ roomClosed: boolean }> {
  const supabase = getServerSupabase();

  // Mark participant as completed
  const { error: updateError } = await supabase
    .from('chat_participants')
    .update({
      completed_at: new Date().toISOString(),
    })
    .eq('room_id', roomId)
    .eq('fid', fid)
    .is('completed_at', null);

  if (updateError) {
    console.error('Error marking participant completed:', updateError);
    throw new Error('Failed to mark participant completed');
  }

  // Check if both participants are completed
  const { data: participants, error: fetchError } = await supabase
    .from('chat_participants')
    .select('completed_at')
    .eq('room_id', roomId);

  if (fetchError) {
    console.error('Error fetching participants:', fetchError);
    return { roomClosed: false };
  }

  const allCompleted = participants?.every((p) => p.completed_at !== null);

  if (allCompleted) {
    await closeRoom(roomId, 'both_completed');
    return { roomClosed: true };
  }

  return { roomClosed: false };
}

/**
 * Closes a chat room
 * Also updates the associated match to 'completed' status
 */
export async function closeRoom(
  roomId: string,
  reason: 'timeout' | 'both_completed' | 'manual'
): Promise<void> {
  const supabase = getServerSupabase();

  // Get room to find match_id
  const { data: room, error: roomError } = await supabase
    .from('chat_rooms')
    .select('match_id, is_closed')
    .eq('id', roomId)
    .single();

  if (roomError || !room) {
    console.error('Error fetching room for closure:', roomError);
    return;
  }

  // Already closed
  if (room.is_closed) {
    return;
  }

  // Close room
  const { error: closeError } = await supabase
    .from('chat_rooms')
    .update({
      is_closed: true,
      closed_at: new Date().toISOString(),
    })
    .eq('id', roomId);

  if (closeError) {
    console.error('Error closing room:', closeError);
    throw new Error('Failed to close room');
  }

  // Update match status to completed
  const { error: matchError } = await supabase
    .from('matches')
    .update({
      status: 'completed',
      completed_at: new Date().toISOString(),
    })
    .eq('id', room.match_id)
    .neq('status', 'completed');

  if (matchError) {
    console.error('Error updating match status:', matchError);
  }

  console.log(`Chat room ${roomId} closed. Reason: ${reason}`);
}

/**
 * Sends a message in a chat room
 * Checks room status and TTL before allowing send
 */
export async function sendMessage(
  roomId: string,
  senderFid: number,
  body: string
): Promise<ChatMessage | null> {
  const supabase = getServerSupabase();

  // Check room status
  const { data: room, error: roomError } = await supabase
    .from('chat_rooms')
    .select('*')
    .eq('id', roomId)
    .single();

  if (roomError || !room) {
    throw new Error('Chat room not found');
  }

  // Check if room is closed
  if (room.is_closed) {
    throw new Error('Chat room is closed');
  }

  // Check TTL expiration
  if (room.first_join_at) {
    const firstJoinTime = new Date(room.first_join_at).getTime();
    const expiryTime = firstJoinTime + room.ttl_seconds * 1000;
    const now = Date.now();

    if (now > expiryTime) {
      // Close the room
      await closeRoom(roomId, 'timeout');
      throw new Error('Chat room has expired');
    }
  }

  // Verify participant
  const { data: participant, error: participantError } = await supabase
    .from('chat_participants')
    .select('*')
    .eq('room_id', roomId)
    .eq('fid', senderFid)
    .single();

  if (participantError || !participant) {
    throw new Error('You are not a participant of this chat room');
  }

  // Insert message
  const { data: message, error: messageError } = await supabase
    .from('chat_messages')
    .insert({
      room_id: roomId,
      sender_fid: senderFid,
      body,
    })
    .select()
    .single();

  if (messageError) {
    console.error('Error sending message:', messageError);
    throw new Error('Failed to send message');
  }

  return message;
}

/**
 * Closes all expired chat rooms (for cron job)
 */
export async function closeExpiredRooms(): Promise<number> {
  const supabase = getServerSupabase();

  try {
    const { data, error } = await supabase.rpc('close_expired_chat_rooms');

    if (error) {
      console.error('Error closing expired rooms:', error);
      return 0;
    }

    return data || 0;
  } catch (error) {
    console.error('Error in closeExpiredRooms:', error);
    return 0;
  }
}
