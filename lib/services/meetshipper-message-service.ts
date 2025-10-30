/**
 * MeetShipper Message Service
 * Handles real-time chat messages within conversation rooms
 */

import { getServerSupabase } from '../supabase';

export interface MeetshipperMessage {
  id: string;
  room_id: string;
  sender_fid: number;
  content: string;
  created_at: string;
}

export interface MeetshipperMessageWithSender extends MeetshipperMessage {
  sender_username: string;
  sender_display_name: string;
  sender_avatar_url: string;
}

/**
 * Send a message to a conversation room
 */
export async function sendMessage(
  roomId: string,
  senderFid: number,
  content: string
): Promise<MeetshipperMessage> {
  const supabase = getServerSupabase();

  // Verify room exists and is not closed
  const { data: room, error: roomError } = await supabase
    .from('meetshipper_rooms')
    .select('id, is_closed')
    .eq('id', roomId)
    .single();

  if (roomError || !room) {
    throw new Error('Room not found');
  }

  if (room.is_closed) {
    throw new Error('Cannot send messages to a closed room');
  }

  // Insert message
  const { data: message, error: messageError } = await supabase
    .from('meetshipper_messages')
    .insert({
      room_id: roomId,
      sender_fid: senderFid,
      content: content.trim(),
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
 * Get messages for a conversation room
 */
export async function getRoomMessages(
  roomId: string,
  limit: number = 100
): Promise<MeetshipperMessageWithSender[]> {
  const supabase = getServerSupabase();

  const { data: messages, error } = await supabase
    .from('meetshipper_message_details')
    .select('*')
    .eq('room_id', roomId)
    .order('created_at', { ascending: true })
    .limit(limit);

  if (error) {
    console.error('Error fetching messages:', error);
    return [];
  }

  return messages || [];
}

/**
 * Get recent messages for a room (last N messages)
 */
export async function getRecentMessages(
  roomId: string,
  limit: number = 50
): Promise<MeetshipperMessageWithSender[]> {
  const supabase = getServerSupabase();

  const { data: messages, error } = await supabase
    .from('meetshipper_message_details')
    .select('*')
    .eq('room_id', roomId)
    .order('created_at', { ascending: false })
    .limit(limit);

  if (error) {
    console.error('Error fetching recent messages:', error);
    return [];
  }

  // Reverse to show oldest first
  return (messages || []).reverse();
}

/**
 * Get message count for a room
 */
export async function getRoomMessageCount(
  roomId: string
): Promise<number> {
  const supabase = getServerSupabase();

  const { data, error } = await supabase
    .rpc('get_room_message_count', { p_room_id: roomId });

  if (error) {
    console.error('Error getting message count:', error);
    return 0;
  }

  return data || 0;
}

/**
 * Delete all messages in a room (used when room is closed, optional)
 */
export async function deleteRoomMessages(
  roomId: string
): Promise<boolean> {
  const supabase = getServerSupabase();

  const { error } = await supabase
    .from('meetshipper_messages')
    .delete()
    .eq('room_id', roomId);

  if (error) {
    console.error('Error deleting room messages:', error);
    return false;
  }

  return true;
}
