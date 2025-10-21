/**
 * Meeting Service
 * Handles meeting link generation, scheduling, and auto-close
 */

import { getServerSupabase } from '@/lib/supabase';
import { randomBytes } from 'crypto';

export interface MeetingLink {
  url: string;
  meetingId: string;
  platform: 'huddle01' | 'whereby' | 'custom';
}

export type MeetingState = 'scheduled' | 'in_progress' | 'closed';

/**
 * Generate a unique meeting ID
 */
function generateMeetingId(): string {
  return randomBytes(16).toString('hex');
}

/**
 * Generate meeting link using configured providers (Whereby, Huddle01, or fallback)
 * Priority: Whereby > Huddle01 > Google Meet fallback
 */
export async function generateMeetingLink(
  matchId: string,
  _userAFid: number,
  _userBFid: number
): Promise<MeetingLink> {
  const meetingId = generateMeetingId();

  // Try Whereby first (if API key is configured)
  if (process.env.WHEREBY_API_KEY) {
    try {
      console.log('[Meeting] Attempting to create Whereby room...');
      const wherebyUrl = await createWherebyRoom(meetingId);
      console.log('[Meeting] ✓ Whereby room created:', wherebyUrl);
      return {
        url: wherebyUrl,
        meetingId,
        platform: 'whereby',
      };
    } catch (error) {
      console.error('[Meeting] Whereby failed:', error);
      // Fall through to next option
    }
  }

  // Try Huddle01 second (if API key is configured)
  if (process.env.HUDDLE01_API_KEY) {
    try {
      console.log('[Meeting] Attempting to create Huddle01 room...');
      const huddle01Url = await createHuddle01Room(meetingId);
      console.log('[Meeting] ✓ Huddle01 room created:', huddle01Url);
      return {
        url: huddle01Url,
        meetingId,
        platform: 'custom',
      };
    } catch (error) {
      console.error('[Meeting] Huddle01 failed:', error);
      // Fall through to fallback
    }
  }

  // Fallback: Use Google Meet link (no API needed, users create their own)
  console.log('[Meeting] Using Google Meet fallback');
  const googleMeetUrl = `https://meet.google.com/new`;

  return {
    url: googleMeetUrl,
    meetingId,
    platform: 'custom',
  };
}

/**
 * Schedule meeting and generate link after both users accept
 */
export async function scheduleMatch(matchId: string): Promise<{
  success: boolean;
  meetingLink?: string;
  error?: string;
}> {
  const supabase = getServerSupabase();

  // Get match details
  const { data: match, error: fetchError } = await supabase
    .from('matches')
    .select('*')
    .eq('id', matchId)
    .single();

  if (fetchError || !match) {
    return { success: false, error: 'Match not found' };
  }

  // Check if both users have accepted
  if (!match.a_accepted || !match.b_accepted) {
    return { success: false, error: 'Both users must accept before scheduling' };
  }

  // Check if already scheduled
  if (match.meeting_link) {
    return { success: true, meetingLink: match.meeting_link };
  }

  // Generate meeting link
  const meeting = await generateMeetingLink(
    matchId,
    match.user_a_fid,
    match.user_b_fid
  );

  // Update match with meeting link and set initial state
  const { error: updateError } = await supabase
    .from('matches')
    .update({
      meeting_link: meeting.url,
      scheduled_at: new Date().toISOString(),
      status: 'accepted',
      meeting_state: 'scheduled', // Room created but not started yet
    })
    .eq('id', matchId);

  if (updateError) {
    console.error('Error updating match with meeting link:', updateError);
    return { success: false, error: 'Failed to schedule meeting' };
  }

  // Create system message in messages table
  await supabase.from('messages').insert({
    match_id: matchId,
    sender_fid: match.user_a_fid,
    content: `Meeting scheduled! Join here: ${meeting.url}`,
    is_system_message: true,
  });

  return { success: true, meetingLink: meeting.url };
}

/**
 * Whereby Integration (uses appear.in API)
 * API Documentation: https://docs.whereby.com/
 */
async function createWherebyRoom(meetingId: string): Promise<string> {
  const WHEREBY_API_KEY = process.env.WHEREBY_API_KEY;

  if (!WHEREBY_API_KEY) {
    throw new Error('Whereby API key not configured');
  }

  // Whereby API endpoint
  const response = await fetch('https://api.whereby.dev/v1/meetings', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${WHEREBY_API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      endDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(), // 7 days
      fields: ['hostRoomUrl'],
      roomNamePrefix: 'meetshipper-',
      roomMode: 'normal', // or 'group' for larger meetings
    }),
  });

  if (!response.ok) {
    const errorText = await response.text();
    console.error('[Whereby] API Error:', response.status, errorText);
    throw new Error(`Whereby API failed: ${response.status} ${errorText}`);
  }

  const data = await response.json();
  console.log('[Whereby] Response:', data);

  // Return the meeting room URL (can be hostRoomUrl or roomUrl)
  return data.roomUrl || data.hostRoomUrl;
}

/**
 * Huddle01 Integration
 * API Documentation: https://docs.huddle01.com/
 */
async function createHuddle01Room(meetingId: string): Promise<string> {
  const HUDDLE01_API_KEY = process.env.HUDDLE01_API_KEY;

  if (!HUDDLE01_API_KEY) {
    throw new Error('Huddle01 API key not configured');
  }

  // Huddle01 API v2 endpoint (updated)
  const response = await fetch('https://api.huddle01.com/api/v2/create-room', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': HUDDLE01_API_KEY,
    },
    body: JSON.stringify({
      title: `MeetShipper Match ${meetingId.substring(0, 8)}`,
      roomLocked: false,
    }),
  });

  if (!response.ok) {
    const errorText = await response.text();
    console.error('[Huddle01] API Error:', response.status, errorText);
    throw new Error(`Huddle01 API failed: ${response.status} ${errorText}`);
  }

  const data = await response.json();
  console.log('[Huddle01] Response:', data);

  // Huddle01 returns: { data: { roomId, meetingLink } }
  return data.data?.meetingLink || data.data?.roomUrl || `https://app.huddle01.com/${data.data?.roomId}`;
}

/**
 * Get meeting details for a match
 */
export async function getMeetingDetails(matchId: string): Promise<{
  meetingLink: string | null;
  scheduledAt: string | null;
  isScheduled: boolean;
}> {
  const supabase = getServerSupabase();

  const { data: match, error } = await supabase
    .from('matches')
    .select('meeting_link, scheduled_at')
    .eq('id', matchId)
    .single();

  if (error || !match) {
    return {
      meetingLink: null,
      scheduledAt: null,
      isScheduled: false,
    };
  }

  return {
    meetingLink: match.meeting_link,
    scheduledAt: match.scheduled_at,
    isScheduled: !!match.meeting_link,
  };
}

/**
 * Mark meeting as completed
 */
export async function completeMeeting(matchId: string): Promise<boolean> {
  const supabase = getServerSupabase();

  const { error } = await supabase
    .from('matches')
    .update({
      status: 'completed',
      completed_at: new Date().toISOString(),
    })
    .eq('id', matchId);

  if (error) {
    console.error('Error completing meeting:', error);
    return false;
  }

  return true;
}

/**
 * Close Whereby meeting room via API
 */
export async function closeWherebyRoom(roomUrl: string): Promise<{
  success: boolean;
  error?: string;
}> {
  const WHEREBY_API_KEY = process.env.WHEREBY_API_KEY;

  if (!WHEREBY_API_KEY) {
    console.warn('[Whereby] API key not configured, cannot close room');
    return { success: false, error: 'Whereby API key not configured' };
  }

  try {
    // Extract meeting ID from Whereby URL
    // Format: https://meetshipper.whereby.com/room-name or https://whereby.com/room-name
    const urlParts = roomUrl.split('/');
    const meetingId = urlParts[urlParts.length - 1];

    if (!meetingId) {
      throw new Error('Could not extract meeting ID from URL');
    }

    console.log('[Whereby] Closing room:', meetingId);

    // Whereby API endpoint to delete/end a meeting
    const response = await fetch(`https://api.whereby.dev/v1/meetings/${meetingId}`, {
      method: 'DELETE',
      headers: {
        'Authorization': `Bearer ${WHEREBY_API_KEY}`,
      },
    });

    if (!response.ok && response.status !== 404) {
      // 404 means room already deleted/doesn't exist - that's ok
      const errorText = await response.text();
      console.error('[Whereby] Delete API Error:', response.status, errorText);
      throw new Error(`Whereby delete failed: ${response.status}`);
    }

    console.log('[Whereby] ✓ Room closed successfully');
    return { success: true };
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
    console.error('[Whereby] Error closing room:', error);
    return { success: false, error: errorMessage };
  }
}

/**
 * Close meeting room and update database
 */
export async function closeMeetingRoom(
  matchId: string,
  reason: 'manual' | 'auto_expired' = 'manual'
): Promise<{
  success: boolean;
  error?: string;
}> {
  const supabase = getServerSupabase();

  // Get match details
  const { data: match, error: fetchError } = await supabase
    .from('matches')
    .select('*')
    .eq('id', matchId)
    .single();

  if (fetchError || !match) {
    return { success: false, error: 'Match not found' };
  }

  // Check if already closed
  if (match.meeting_state === 'closed') {
    console.log('[Meeting] Room already closed');
    return { success: true };
  }

  // Close the Whereby room if it exists
  if (match.meeting_link && match.meeting_link.includes('whereby')) {
    await closeWherebyRoom(match.meeting_link);
  }

  // Update database to mark room as closed
  const { error: updateError } = await supabase
    .from('matches')
    .update({
      meeting_state: 'closed',
      meeting_closed_at: new Date().toISOString(),
    })
    .eq('id', matchId);

  if (updateError) {
    console.error('[Meeting] Error updating room state:', updateError);
    return { success: false, error: 'Failed to update room state' };
  }

  // If both users completed and status isn't already completed, update it
  if (match.a_completed && match.b_completed && match.status !== 'completed') {
    await supabase
      .from('matches')
      .update({ status: 'completed' })
      .eq('id', matchId);
  }

  console.log(`[Meeting] ✓ Room closed (reason: ${reason})`);
  return { success: true };
}

/**
 * Start meeting timer when first participant joins
 */
export async function startMeetingTimer(matchId: string): Promise<{
  success: boolean;
  startedAt?: string;
  expiresAt?: string;
  error?: string;
}> {
  const supabase = getServerSupabase();

  // Get match details
  const { data: match, error: fetchError } = await supabase
    .from('matches')
    .select('*')
    .eq('id', matchId)
    .single();

  if (fetchError || !match) {
    return { success: false, error: 'Match not found' };
  }

  // Check if timer already started
  if (match.meeting_started_at) {
    console.log('[Meeting] Timer already started');
    return {
      success: true,
      startedAt: match.meeting_started_at,
      expiresAt: match.meeting_expires_at,
    };
  }

  // Set meeting as started, calculate expiry (2 hours from now)
  const startedAt = new Date();
  const expiresAt = new Date(startedAt.getTime() + 2 * 60 * 60 * 1000); // 2 hours

  const { error: updateError } = await supabase
    .from('matches')
    .update({
      meeting_started_at: startedAt.toISOString(),
      meeting_expires_at: expiresAt.toISOString(),
      meeting_state: 'in_progress',
    })
    .eq('id', matchId);

  if (updateError) {
    console.error('[Meeting] Error starting timer:', updateError);
    return { success: false, error: 'Failed to start timer' };
  }

  console.log(`[Meeting] ✓ Timer started, expires at ${expiresAt.toISOString()}`);
  return {
    success: true,
    startedAt: startedAt.toISOString(),
    expiresAt: expiresAt.toISOString(),
  };
}

/**
 * Get expired meeting rooms that need to be closed
 */
export async function getExpiredMeetingRooms(): Promise<
  Array<{
    matchId: string;
    meetingLink: string;
    expiresAt: string;
    minutesOverdue: number;
  }>
> {
  const supabase = getServerSupabase();

  const { data: matches, error } = await supabase
    .from('matches')
    .select('id, meeting_link, meeting_expires_at')
    .in('meeting_state', ['scheduled', 'in_progress'])
    .not('meeting_expires_at', 'is', null)
    .not('meeting_link', 'is', null)
    .lt('meeting_expires_at', new Date().toISOString());

  if (error) {
    console.error('[Meeting] Error fetching expired rooms:', error);
    return [];
  }

  return (matches || []).map((match) => {
    const expiresAt = new Date(match.meeting_expires_at);
    const now = new Date();
    const minutesOverdue = Math.floor((now.getTime() - expiresAt.getTime()) / 60000);

    return {
      matchId: match.id,
      meetingLink: match.meeting_link,
      expiresAt: match.meeting_expires_at,
      minutesOverdue,
    };
  });
}

/**
 * Auto-close all expired meeting rooms (called by cron)
 */
export async function autoCloseExpiredRooms(): Promise<{
  expiredCount: number;
  closedCount: number;
  errors: string[];
}> {
  const expiredRooms = await getExpiredMeetingRooms();

  if (expiredRooms.length === 0) {
    console.log('[Meeting] No expired rooms to close');
    return { expiredCount: 0, closedCount: 0, errors: [] };
  }

  console.log(`[Meeting] Found ${expiredRooms.length} expired room(s) to close`);

  let closedCount = 0;
  const errors: string[] = [];

  for (const room of expiredRooms) {
    const result = await closeMeetingRoom(room.matchId, 'auto_expired');
    if (result.success) {
      closedCount++;
      console.log(`[Meeting] ✓ Closed expired room ${room.matchId} (${room.minutesOverdue}min overdue)`);
    } else {
      errors.push(`${room.matchId}: ${result.error}`);
      console.error(`[Meeting] ✗ Failed to close room ${room.matchId}:`, result.error);
    }
  }

  console.log(`[Meeting] Auto-close complete: ${closedCount}/${expiredRooms.length} closed`);

  return {
    expiredCount: expiredRooms.length,
    closedCount,
    errors,
  };
}
