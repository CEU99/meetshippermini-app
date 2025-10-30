'use client';

import { useEffect, useState, useRef, use } from 'react';
import { useRouter } from 'next/navigation';
import { supabase } from '@/lib/supabase';

interface ChatMessage {
  id: string;
  room_id: string;
  sender_fid: number;
  body: string;
  created_at: string;
}

interface ChatParticipant {
  room_id: string;
  fid: number;
  joined_at: string;
  completed_at: string | null;
}

interface User {
  fid: number;
  username: string;
  display_name: string;
  avatar_url: string;
}

interface ChatRoomData {
  id: string;
  match_id: string;
  opened_at: string;
  first_join_at: string | null;
  closed_at: string | null;
  ttl_seconds: number;
  is_closed: boolean;
  participants: ChatParticipant[];
  messages: ChatMessage[];
  remaining_seconds: number;
}

export default function ChatRoomPage({
  params,
}: {
  params: Promise<{ roomId: string }>;
}) {
  const resolvedParams = use(params);
  const roomId = resolvedParams.roomId;
  const router = useRouter();

  const [room, setRoom] = useState<ChatRoomData | null>(null);
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [newMessage, setNewMessage] = useState('');
  const [loading, setLoading] = useState(true);
  const [sending, setSending] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [participants, setParticipants] = useState<Map<number, User>>(new Map());
  const [currentUserFid, setCurrentUserFid] = useState<number | null>(null);
  const [remainingSeconds, setRemainingSeconds] = useState<number>(0);
  const [isCompleting, setIsCompleting] = useState(false);

  const messagesEndRef = useRef<HTMLDivElement>(null);

  // Scroll to bottom when messages change
  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  // Fetch room data
  const fetchRoom = async () => {
    try {
      const response = await fetch(`/api/chat/rooms/${roomId}`);
      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.error || 'Failed to fetch room');
      }

      setRoom(data.data);
      setMessages(data.data.messages);
      setRemainingSeconds(data.data.remaining_seconds);

      // Fetch participant details
      const participantFids = data.data.participants.map((p: ChatParticipant) => p.fid);
      const { data: users, error: usersError } = await supabase
        .from('users')
        .select('fid, username, display_name, avatar_url')
        .in('fid', participantFids);

      if (!usersError && users) {
        const userMap = new Map<number, User>();
        users.forEach((user: User) => {
          userMap.set(user.fid, user);
        });
        setParticipants(userMap);
      }

      // Get current user FID from session
      const sessionResponse = await fetch(
        process.env.NODE_ENV === 'development' ? '/api/dev/session' : '/api/auth/me',
        { credentials: 'include' }
      );
      if (sessionResponse.ok) {
        const sessionData = await sessionResponse.json();
        setCurrentUserFid(
          process.env.NODE_ENV === 'development' ? sessionData.fid : sessionData.user?.fid
        );
      }

      setLoading(false);
    } catch (err: any) {
      console.error('Error fetching room:', err);
      setError(err.message || 'Failed to load chat room');
      setLoading(false);
    }
  };

  // Initial room fetch
  useEffect(() => {
    fetchRoom();
  }, [roomId]);

  // Polling mechanism for messages (fallback since Realtime not available)
  useEffect(() => {
    if (!room || !currentUserFid) return;

    console.log('[Chat] 🔄 Setting up message polling for room:', roomId);
    console.log('[Chat] Polling interval: 2 seconds');
    console.log('[Chat] Note: Using polling because Supabase Realtime is not available in this region');

    let pollInterval: NodeJS.Timeout;
    let isPolling = true;

    const pollMessages = async () => {
      if (!isPolling) return;

      try {
        const response = await fetch(`/api/chat/rooms/${roomId}`);
        const data = await response.json();

        if (data && data.data && data.data.messages) {
          setMessages((prev) => {
            // Only update if we have new messages
            const newMessages = data.data.messages.filter(
              (newMsg: ChatMessage) => !prev.some((existingMsg) => existingMsg.id === newMsg.id)
            );

            if (newMessages.length > 0) {
              console.log('[Chat] 📨 Polled and found', newMessages.length, 'new message(s)');
              return data.data.messages; // Use complete list from server
            }

            return prev; // No changes
          });

          // Update room data and remaining seconds
          setRoom(data.data);
          setRemainingSeconds(data.data.remaining_seconds);
        }
      } catch (error) {
        console.error('[Chat] Error polling messages:', error);
      }
    };

    // Initial poll
    pollMessages();

    // Set up polling interval
    pollInterval = setInterval(pollMessages, 2000);
    console.log('[Chat] ✅ Polling started - checking for new messages every 2 seconds');

    // Cleanup function
    return () => {
      console.log('[Chat] 🧹 Stopping message polling');
      isPolling = false;
      if (pollInterval) {
        clearInterval(pollInterval);
      }
      console.log('[Chat] ✅ Polling cleanup complete');
    };
  }, [room, currentUserFid, roomId]);

  // Countdown timer
  useEffect(() => {
    if (remainingSeconds <= 0 || !room || room.is_closed) return;

    const interval = setInterval(() => {
      setRemainingSeconds((prev) => {
        if (prev <= 1) {
          // Room expired, refetch to get updated status
          fetchRoom();
          return 0;
        }
        return prev - 1;
      });
    }, 1000);

    return () => clearInterval(interval);
  }, [remainingSeconds, room]);

  // Send message
  const handleSendMessage = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newMessage.trim() || sending || !currentUserFid) return;

    const messageBody = newMessage.trim();
    setSending(true);
    setNewMessage('');

    // Optimistic UI: Add message immediately to local state
    const optimisticMessage: ChatMessage = {
      id: `temp-${Date.now()}`,
      room_id: roomId,
      sender_fid: currentUserFid,
      body: messageBody,
      created_at: new Date().toISOString(),
    };
    setMessages((prev) => [...prev, optimisticMessage]);

    try {
      const response = await fetch(`/api/chat/rooms/${roomId}/message`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ body: messageBody }),
      });

      const data = await response.json();

      if (!response.ok) {
        // Remove optimistic message on error
        setMessages((prev) => prev.filter((msg) => msg.id !== optimisticMessage.id));
        throw new Error(data.error || 'Failed to send message');
      }

      // Replace optimistic message with real message from server
      setMessages((prev) =>
        prev.map((msg) => (msg.id === optimisticMessage.id ? data.data : msg))
      );
    } catch (err: any) {
      console.error('Error sending message:', err);
      alert(err.message || 'Failed to send message');
      // Restore message text so user can retry
      setNewMessage(messageBody);
    } finally {
      setSending(false);
    }
  };

  // Mark meeting completed
  const handleMarkCompleted = async () => {
    if (isCompleting) return;

    setIsCompleting(true);
    try {
      const response = await fetch(`/api/chat/rooms/${roomId}/complete`, {
        method: 'POST',
      });

      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.error || 'Failed to mark as complete');
      }

      // Show success message
      alert(data.data.message);

      // Navigate back to inbox (don't touch session or auth state)
      router.push('/mini/inbox');
    } catch (err: any) {
      console.error('Error marking complete:', err);
      alert(err.message || 'Failed to mark as complete');
      setIsCompleting(false);
    }
  };

  // Format time remaining
  const formatTimeRemaining = (seconds: number): string => {
    if (seconds <= 0) return '00:00';
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  };

  // Get status badge
  const getStatusBadge = () => {
    if (!room) return null;

    if (room.is_closed) {
      return (
        <span className="px-3 py-1 bg-gray-200 text-gray-700 rounded-full text-sm font-medium">
          Read-only (Closed)
        </span>
      );
    }

    if (remainingSeconds > 0) {
      const isExpiring = remainingSeconds < 600; // Less than 10 minutes
      return (
        <span
          className={`px-3 py-1 rounded-full text-sm font-medium ${
            isExpiring ? 'bg-orange-100 text-orange-700' : 'bg-green-100 text-green-700'
          }`}
        >
          Open · {formatTimeRemaining(remainingSeconds)}
        </span>
      );
    }

    return (
      <span className="px-3 py-1 bg-blue-100 text-blue-700 rounded-full text-sm font-medium">
        Open (No timer yet)
      </span>
    );
  };

  // Get closure reason
  const getClosureReason = () => {
    if (!room || !room.is_closed) return null;

    const allCompleted = room.participants.every((p) => p.completed_at !== null);
    if (allCompleted) {
      return 'Both participants marked the meeting as completed';
    }

    return 'Chat room timed out (2-hour limit)';
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto mb-4"></div>
          <p className="text-gray-600">Loading chat room...</p>
        </div>
      </div>
    );
  }

  if (error || !room) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-center max-w-md p-6">
          <div className="text-red-600 text-5xl mb-4">⚠️</div>
          <h2 className="text-xl font-bold text-gray-800 mb-2">Error Loading Chat</h2>
          <p className="text-gray-600 mb-4">{error || 'Chat room not found'}</p>
          <button
            onClick={() => router.push('/mini/inbox')}
            className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
          >
            Back to Inbox
          </button>
        </div>
      </div>
    );
  }

  const otherParticipant = room.participants.find((p) => p.fid !== currentUserFid);
  const otherUser = otherParticipant ? participants.get(otherParticipant.fid) : null;

  return (
    <div className="flex flex-col h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white border-b border-gray-200 px-4 py-3 shadow-sm">
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-3">
            <button
              onClick={() => router.push('/mini/inbox')}
              className="text-gray-600 hover:text-gray-800"
            >
              ← Back
            </button>
            {otherUser && (
              <div className="flex items-center space-x-2">
                <img
                  src={otherUser.avatar_url || '/default-avatar.png'}
                  alt={otherUser.display_name}
                  className="w-8 h-8 rounded-full"
                />
                <div>
                  <p className="font-semibold text-gray-800">{otherUser.display_name}</p>
                  <p className="text-xs text-gray-500">@{otherUser.username}</p>
                </div>
              </div>
            )}
          </div>
          <div className="flex items-center space-x-3">
            {getStatusBadge()}
          </div>
        </div>
      </div>

      {/* Closure banner */}
      {room.is_closed && (
        <div className="bg-yellow-50 border-b border-yellow-200 px-4 py-3">
          <p className="text-sm text-yellow-800">
            <strong>Chat closed:</strong> {getClosureReason()}
          </p>
        </div>
      )}

      {/* Timer info banner (only show before first join) */}
      {!room.first_join_at && !room.is_closed && (
        <div className="bg-blue-50 border-b border-blue-200 px-4 py-3">
          <p className="text-sm text-blue-800">
            ℹ️ The 2-hour countdown will start as soon as either participant enters or sends the first message.
          </p>
        </div>
      )}

      {/* Messages area */}
      <div className="flex-1 overflow-y-auto px-4 py-4 space-y-4">
        {messages.length === 0 ? (
          <div className="text-center text-gray-500 mt-8">
            <p>No messages yet. Start the conversation!</p>
          </div>
        ) : (
          messages.map((msg) => {
            const sender = participants.get(msg.sender_fid);
            const isCurrentUser = msg.sender_fid === currentUserFid;

            return (
              <div
                key={msg.id}
                className={`flex ${isCurrentUser ? 'justify-end' : 'justify-start'}`}
              >
                <div
                  className={`max-w-xs lg:max-w-md px-4 py-2 rounded-lg ${
                    isCurrentUser
                      ? 'bg-blue-600 text-white'
                      : 'bg-white text-gray-800 border border-gray-200'
                  }`}
                >
                  {!isCurrentUser && sender && (
                    <p className="text-xs font-semibold mb-1">{sender.display_name}</p>
                  )}
                  <p className="text-sm whitespace-pre-wrap break-words">{msg.body}</p>
                  <p
                    className={`text-xs mt-1 ${
                      isCurrentUser ? 'text-blue-100' : 'text-gray-500'
                    }`}
                  >
                    {new Date(msg.created_at).toLocaleTimeString([], {
                      hour: '2-digit',
                      minute: '2-digit',
                    })}
                  </p>
                </div>
              </div>
            );
          })
        )}
        <div ref={messagesEndRef} />
      </div>

      {/* Actions bar */}
      <div className="bg-white border-t border-gray-200 px-4 py-3">
        <div className="flex items-center space-x-2 mb-2">
          <button
            onClick={handleMarkCompleted}
            disabled={room.is_closed || isCompleting}
            className="px-4 py-2 bg-green-600 text-white text-sm rounded-lg hover:bg-green-700 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {isCompleting ? 'Marking...' : 'Mark Meeting Completed'}
          </button>
        </div>

        {/* Message input */}
        <form onSubmit={handleSendMessage} className="flex items-center space-x-2">
          <input
            type="text"
            value={newMessage}
            onChange={(e) => setNewMessage(e.target.value)}
            placeholder={room.is_closed ? 'Chat is closed' : 'Type your message...'}
            disabled={room.is_closed || sending}
            maxLength={2000}
            className="flex-1 px-4 py-2 border border-gray-300 rounded-lg text-gray-900 placeholder:text-gray-500 bg-white focus:outline-none focus:ring-2 focus:ring-purple-400 disabled:bg-gray-100 disabled:cursor-not-allowed"
          />
          <button
            type="submit"
            disabled={room.is_closed || sending || !newMessage.trim()}
            className="px-6 py-2 bg-gradient-to-r from-purple-600 to-pink-600 text-white rounded-lg hover:from-purple-700 hover:to-pink-700 disabled:opacity-50 disabled:cursor-not-allowed transition-all"
          >
            {sending ? 'Sending...' : 'Send'}
          </button>
        </form>
      </div>
    </div>
  );
}
