'use client';

import { useEffect, useState, useRef } from 'react';
import { useRouter, useParams } from 'next/navigation';
import { useFarcasterAuth } from '@/components/providers/FarcasterAuthProvider';
import { Navigation } from '@/components/shared/Navigation';
import Image from 'next/image';
import { apiClient, closeMeetshipperRoom } from '@/lib/api-client';

interface RoomParticipant {
  fid: number;
  username: string;
  displayName: string;
  avatarUrl: string;
}

interface MeetshipperRoom {
  id: string;
  match_id: string;
  user_a_fid: number;
  user_b_fid: number;
  is_closed: boolean;
  closed_by_fid: number | null;
  created_at: string;
  closed_at: string | null;
  userA: RoomParticipant;
  userB: RoomParticipant;
}

interface Message {
  id: string;
  room_id: string;
  sender_fid: number;
  content: string;
  created_at: string;
  sender_username: string;
  sender_display_name: string;
  sender_avatar_url: string;
}

export default function MeetshipperConversationRoom() {
  const router = useRouter();
  const params = useParams();
  const roomId = params.id as string;
  const { user, isAuthenticated, loading: authLoading } = useFarcasterAuth();
  const [room, setRoom] = useState<MeetshipperRoom | null>(null);
  const [loading, setLoading] = useState(true);
  const [actionLoading, setActionLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Chat state
  const [messages, setMessages] = useState<Message[]>([]);
  const [newMessage, setNewMessage] = useState('');
  const [sendingMessage, setSendingMessage] = useState(false);
  const [otherUserOnline, setOtherUserOnline] = useState(false); // Disabled - Realtime not available
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const messagesContainerRef = useRef<HTMLDivElement>(null);
  const lastMessageCountRef = useRef(0);

  useEffect(() => {
    if (!authLoading && !isAuthenticated) {
      router.push('/');
    }
  }, [isAuthenticated, authLoading, router]);

  useEffect(() => {
    if (isAuthenticated && roomId) {
      fetchRoom();
      fetchMessages();
    }
  }, [isAuthenticated, roomId]);

  // Polling mechanism for messages (fallback since Realtime not available)
  useEffect(() => {
    if (!isAuthenticated || !roomId) {
      console.log('[Chat] Waiting for authentication and room data...');
      return;
    }

    console.log('[Chat] 🔄 Setting up message polling for room:', roomId);
    console.log('[Chat] Polling interval: 2 seconds');
    console.log('[Chat] Note: Using polling because Supabase Realtime is not available in this region');

    let pollInterval: NodeJS.Timeout;
    let isPolling = true;

    const pollMessages = async () => {
      if (!isPolling) return;

      try {
        const data = await apiClient.get<{ success: boolean; messages: Message[] }>(
          `/api/meetshipper-rooms/${roomId}/messages`
        );

        if (data && data.success && data.messages) {
          setMessages((prev) => {
            // Only update if we have new messages
            const newMessages = data.messages.filter(
              (newMsg) => !prev.some((existingMsg) => existingMsg.id === newMsg.id)
            );

            if (newMessages.length > 0) {
              console.log('[Chat] 📨 Polled and found', newMessages.length, 'new message(s)');
              newMessages.forEach(msg => {
                console.log('[Chat] New message from:', msg.sender_display_name);
                console.log('[Chat] Content:', msg.content.substring(0, 50));
              });
              return data.messages; // Use complete list from server
            }

            // Log polling activity periodically (every 10th poll)
            if (data.messages.length !== lastMessageCountRef.current) {
              lastMessageCountRef.current = data.messages.length;
              console.log('[Chat] 📊 Total messages:', data.messages.length);
            }

            return prev; // No changes
          });
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
  }, [isAuthenticated, roomId]);

  // Auto-scroll to bottom when new messages arrive
  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const fetchRoom = async () => {
    setLoading(true);
    try {
      const data = await apiClient.get<{ success: boolean; room: MeetshipperRoom }>(
        `/api/meetshipper-rooms/${roomId}`
      );

      if (data && data.success && data.room) {
        setRoom(data.room);
      } else {
        setError('Room not found');
      }
    } catch (error) {
      console.error('Error fetching room:', error);
      setError('Failed to load conversation room');
    } finally {
      setLoading(false);
    }
  };

  const fetchMessages = async () => {
    try {
      const data = await apiClient.get<{ success: boolean; messages: Message[] }>(
        `/api/meetshipper-rooms/${roomId}/messages`
      );

      if (data && data.success && data.messages) {
        setMessages(data.messages);
      }
    } catch (error) {
      console.error('Error fetching messages:', error);
    }
  };

  const sendMessageHandler = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!newMessage.trim() || sendingMessage || room?.is_closed) {
      return;
    }

    setSendingMessage(true);
    try {
      const data = await apiClient.post<{ success: boolean; message: Message }>(
        `/api/meetshipper-rooms/${roomId}/messages`,
        { content: newMessage.trim() }
      );

      if (data && data.success) {
        setNewMessage('');
        // Message will be added via real-time subscription
      }
    } catch (error) {
      console.error('Error sending message:', error);
      alert('Failed to send message. Please try again.');
    } finally {
      setSendingMessage(false);
    }
  };

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  const handleLeaveRoom = () => {
    router.push('/mini/inbox');
  };

  const handleCompleteConversation = async () => {
    if (!confirm('Are you sure you want to mark this conversation as completed? This action cannot be undone and will permanently close the room for both participants.')) {
      return;
    }

    setActionLoading(true);
    try {
      const result = await closeMeetshipperRoom(roomId);

      if (result.success) {
        alert('Conversation marked as completed! Redirecting to inbox...');
        router.push('/mini/inbox');
      } else {
        alert(result.error || 'Failed to close conversation room');
      }
    } catch (error) {
      console.error('Error closing room:', error);
      alert('Failed to close conversation room');
    } finally {
      setActionLoading(false);
    }
  };

  const getOtherParticipant = (): RoomParticipant | null => {
    if (!room || !user) return null;
    return room.user_a_fid === user.fid ? room.userB : room.userA;
  };

  const getMyInfo = (): RoomParticipant | null => {
    if (!room || !user) return null;
    return room.user_a_fid === user.fid ? room.userA : room.userB;
  };

  if (authLoading || loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-purple-600 mx-auto"></div>
          <p className="mt-4 text-gray-600">Loading conversation room...</p>
        </div>
      </div>
    );
  }

  if (error || !room) {
    return (
      <div className="min-h-screen bg-gray-50">
        <Navigation />
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
          <div className="backdrop-blur-xl bg-gradient-to-br from-white/80 via-red-50/60 to-rose-50/60 rounded-2xl border border-red-200/60 shadow-lg p-8 text-center">
            <p className="text-red-600 mb-4">{error || 'Conversation room not found'}</p>
            <button
              onClick={handleLeaveRoom}
              className="px-6 py-2.5 bg-gradient-to-r from-purple-500 to-purple-600 text-white rounded-xl hover:from-purple-600 hover:to-purple-700 font-medium transition-all duration-200"
            >
              ← Back to Inbox
            </button>
          </div>
        </div>
      </div>
    );
  }

  const otherParticipant = getOtherParticipant();
  const myInfo = getMyInfo();

  return (
    <div className="min-h-screen bg-gray-50">
      <Navigation />

      <div className="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Header */}
        <div className="mb-6">
          <button
            onClick={handleLeaveRoom}
            className="mb-4 text-purple-600 hover:text-purple-700 font-medium flex items-center gap-2"
          >
            <span>←</span> Back to Inbox
          </button>
          <h1 className="text-3xl font-bold text-gray-900">MeetShipper Conversation Room</h1>
          <p className="text-gray-600 mt-1">Connect and coordinate your meeting</p>
        </div>

        {/* Room Closed Banner */}
        {room.is_closed && (
          <div className="backdrop-blur-xl bg-gradient-to-r from-gray-50/80 to-slate-50/80 border border-gray-300/60 rounded-2xl p-6 mb-6 shadow-lg">
            <div className="flex items-center gap-3 mb-2">
              <span className="text-3xl">🔒</span>
              <h2 className="text-xl font-bold text-gray-800">This conversation is closed</h2>
            </div>
            <p className="text-sm text-gray-700">
              This conversation room has been marked as completed{room.closed_at && ` on ${new Date(room.closed_at).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })} at ${new Date(room.closed_at).toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' })}`}. No further actions can be taken.
            </p>
          </div>
        )}

        {/* Participants Card */}
        <div className="backdrop-blur-xl bg-gradient-to-br from-white/80 via-purple-50/60 to-blue-50/60 rounded-2xl border border-white/60 shadow-lg p-6 mb-6">
          <h2 className="text-lg font-bold text-gray-900 mb-4 flex items-center gap-2">
            <span>👥</span> Participants
          </h2>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {/* My Info */}
            {myInfo && (
              <div className="backdrop-blur-xl bg-gradient-to-r from-purple-50/80 to-indigo-50/80 border border-purple-200/60 rounded-xl p-4">
                <p className="text-xs font-semibold text-purple-700 mb-2">You</p>
                <div className="flex items-center gap-3">
                  <Image
                    src={myInfo.avatarUrl || '/default-avatar.png'}
                    alt={myInfo.displayName}
                    width={48}
                    height={48}
                    className="rounded-full border-2 border-purple-200"
                  />
                  <div>
                    <p className="font-semibold text-gray-900">{myInfo.displayName}</p>
                    <p className="text-sm text-gray-600">@{myInfo.username}</p>
                  </div>
                </div>
              </div>
            )}

            {/* Other Participant */}
            {otherParticipant && (
              <div className="backdrop-blur-xl bg-gradient-to-r from-blue-50/80 to-cyan-50/80 border border-blue-200/60 rounded-xl p-4">
                <p className="text-xs font-semibold text-blue-700 mb-2">Match Partner</p>
                <div className="flex items-center gap-3">
                  <Image
                    src={otherParticipant.avatarUrl || '/default-avatar.png'}
                    alt={otherParticipant.displayName}
                    width={48}
                    height={48}
                    className="rounded-full border-2 border-blue-200"
                  />
                  <div>
                    <p className="font-semibold text-gray-900">{otherParticipant.displayName}</p>
                    <p className="text-sm text-gray-600">@{otherParticipant.username}</p>
                  </div>
                </div>
              </div>
            )}
          </div>
        </div>

        {/* Conversation Area */}
        <div className="backdrop-blur-xl bg-gradient-to-br from-white/80 via-purple-50/60 to-blue-50/60 rounded-2xl border border-white/60 shadow-lg overflow-hidden mb-6">
          <div className="p-6 border-b border-purple-100">
            <div className="flex items-center justify-between">
              <h2 className="text-lg font-bold text-gray-900 flex items-center gap-2">
                <span>💬</span> Conversation
              </h2>
              <div className="text-xs text-gray-500">
                Messages update every 2 seconds
              </div>
            </div>
          </div>

          {/* Messages Area */}
          <div
            ref={messagesContainerRef}
            className="bg-white/40 backdrop-blur-sm p-4 h-[400px] overflow-y-auto"
          >
            {messages.length === 0 ? (
              <div className="flex flex-col items-center justify-center h-full text-center">
                <div className="backdrop-blur-xl bg-gradient-to-r from-blue-50/80 to-indigo-50/80 border border-blue-200/60 rounded-xl p-6 max-w-md">
                  <p className="text-sm text-blue-900 mb-3">
                    <span className="font-semibold">👋 Welcome to your MeetShipper Conversation Room!</span>
                  </p>
                  <p className="text-sm text-blue-800 mb-3">
                    This is your dedicated space to coordinate meeting details with {otherParticipant?.displayName}.
                  </p>
                  <div className="backdrop-blur-xl bg-white/60 rounded-lg p-4 border border-blue-300/40">
                    <p className="text-xs font-semibold text-gray-700 mb-2">💡 Suggested topics to discuss:</p>
                    <ul className="text-xs text-gray-700 space-y-1 ml-4 list-disc text-left">
                      <li>Exchange contact information (email, phone, social media)</li>
                      <li>Decide on a meeting time and location</li>
                      <li>Share what you'd like to discuss or learn about</li>
                      <li>Set expectations for the meeting</li>
                    </ul>
                  </div>
                </div>
              </div>
            ) : (
              <div className="space-y-4">
                {messages.map((message) => {
                  const isMyMessage = message.sender_fid === user?.fid;

                  return (
                    <div
                      key={message.id}
                      className={`flex items-start gap-3 ${
                        isMyMessage ? 'flex-row-reverse' : 'flex-row'
                      }`}
                    >
                      {/* Avatar */}
                      <Image
                        src={message.sender_avatar_url || '/default-avatar.png'}
                        alt={message.sender_display_name}
                        width={32}
                        height={32}
                        className="rounded-full border border-purple-200 flex-shrink-0"
                      />

                      {/* Message Content */}
                      <div
                        className={`flex flex-col max-w-[70%] ${
                          isMyMessage ? 'items-end' : 'items-start'
                        }`}
                      >
                        {/* Sender Info */}
                        <div
                          className={`flex items-center gap-2 mb-1 ${
                            isMyMessage ? 'flex-row-reverse' : 'flex-row'
                          }`}
                        >
                          <span className="text-xs font-semibold text-gray-700">
                            {isMyMessage ? 'You' : message.sender_display_name}
                          </span>
                          <span className="text-[10px] text-gray-500">
                            {new Date(message.created_at).toLocaleTimeString('en-US', {
                              hour: '2-digit',
                              minute: '2-digit',
                            })}
                          </span>
                        </div>

                        {/* Message Bubble */}
                        <div
                          className={`px-4 py-2.5 rounded-2xl ${
                            isMyMessage
                              ? 'bg-gradient-to-r from-purple-500 to-indigo-500 text-white'
                              : 'bg-white/80 backdrop-blur-sm border border-gray-200 text-gray-900'
                          }`}
                        >
                          <p className="text-sm whitespace-pre-wrap break-words">
                            {message.content}
                          </p>
                        </div>
                      </div>
                    </div>
                  );
                })}
                <div ref={messagesEndRef} />
              </div>
            )}
          </div>

          {/* Message Input */}
          {!room.is_closed && (
            <div className="p-4 border-t border-purple-100 bg-gradient-to-r from-gray-50/80 to-gray-100/80 backdrop-blur-sm">
              <form onSubmit={sendMessageHandler} className="flex gap-3">
                <input
                  type="text"
                  value={newMessage}
                  onChange={(e) => setNewMessage(e.target.value)}
                  placeholder={`Message ${otherParticipant?.displayName}...`}
                  disabled={sendingMessage}
                  className="flex-1 px-4 py-2.5 rounded-xl bg-[#1E1E1E] text-white placeholder:text-gray-400 border border-gray-700 focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-purple-500 disabled:bg-gray-800 disabled:cursor-not-allowed disabled:opacity-50 text-sm transition-all duration-200"
                  maxLength={2000}
                  autoComplete="off"
                />
                <button
                  type="submit"
                  disabled={!newMessage.trim() || sendingMessage}
                  className="px-6 py-2.5 bg-gradient-to-r from-purple-500 to-indigo-500 text-white rounded-xl hover:from-purple-600 hover:to-indigo-600 disabled:from-gray-300 disabled:to-gray-400 font-medium shadow-md hover:shadow-lg transition-all duration-200 disabled:cursor-not-allowed"
                >
                  {sendingMessage ? '⏳' : '📤'}
                </button>
              </form>
              <p className="text-[10px] text-gray-500 mt-2 text-center">
                Messages are visible to both participants
              </p>
            </div>
          )}

          {room.is_closed && (
            <div className="p-4 bg-gray-100/80 border-t border-gray-200">
              <p className="text-sm text-gray-600 text-center">
                🔒 This conversation has been closed. No new messages can be sent.
              </p>
            </div>
          )}
        </div>

        {/* Instructions Card */}
        {!room.is_closed && (
          <div className="backdrop-blur-xl bg-gradient-to-r from-green-50/80 to-emerald-50/80 border border-green-200/60 rounded-2xl p-6 mb-6 shadow-lg">
            <h3 className="font-bold text-green-900 mb-2 flex items-center gap-2">
              <span>💡</span> How It Works
            </h3>
            <ul className="text-sm text-green-800 space-y-1 ml-6 list-disc">
              <li>You can leave and return to this room anytime</li>
              <li>Use this space to coordinate your meeting outside of MeetShipper</li>
              <li>When you've completed your coordination, click "Conversation Completed"</li>
              <li>Once completed, the room will be permanently closed for both participants</li>
            </ul>
          </div>
        )}

        {/* Action Buttons */}
        <div className="flex gap-3">
          <button
            onClick={handleLeaveRoom}
            className="flex-1 px-6 py-3 bg-gradient-to-r from-gray-500 to-slate-500 text-white rounded-xl hover:from-gray-600 hover:to-slate-600 font-semibold shadow-md hover:shadow-lg transition-all duration-200"
          >
            ← Leave Room
          </button>

          {!room.is_closed && (
            <button
              onClick={handleCompleteConversation}
              disabled={actionLoading}
              className="flex-1 px-6 py-3 bg-gradient-to-r from-purple-500 to-indigo-500 text-white rounded-xl hover:from-purple-600 hover:to-indigo-600 disabled:from-gray-300 disabled:to-gray-400 font-semibold shadow-md hover:shadow-lg transition-all duration-200 disabled:cursor-not-allowed"
            >
              {actionLoading ? '⏳ Processing...' : '✅ Conversation Completed'}
            </button>
          )}
        </div>

        {/* Room Info Footer */}
        <div className="mt-6 text-center text-xs text-gray-500">
          <p>Room created: {new Date(room.created_at).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })} at {new Date(room.created_at).toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' })}</p>
        </div>
      </div>
    </div>
  );
}
