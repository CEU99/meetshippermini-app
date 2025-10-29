'use client';

import { useEffect, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import Image from 'next/image';

interface User {
  fid: number;
  username: string;
  display_name: string;
  avatar_url: string;
  bio: string;
}

interface Match {
  id: string;
  message: string;
  status: string;
  a_accepted: boolean;
  b_accepted: boolean;
  chat_room_id: string | null;
  created_at: string;
  rationale?: any;
  creator: User;
  user_a: User;
  user_b: User;
}

export default function MatchPage() {
  const params = useParams();
  const router = useRouter();
  const id = params?.id as string;

  const [match, setMatch] = useState<Match | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [actionLoading, setActionLoading] = useState(false);

  useEffect(() => {
    if (!id) return;

    const fetchMatch = async () => {
      try {
        setLoading(true);
        const response = await fetch(`/api/matches/${id}`);

        if (!response.ok) {
          if (response.status === 404) {
            setError('Match not found');
          } else {
            const data = await response.json();
            setError(data.error || 'Failed to load match');
          }
          return;
        }

        const data = await response.json();
        if (data.success) {
          setMatch(data.match);
        } else {
          setError('Failed to load match');
        }
      } catch (err) {
        console.error('Error fetching match:', err);
        setError('Failed to load match');
      } finally {
        setLoading(false);
      }
    };

    fetchMatch();
  }, [id]);

  const handleAccept = async () => {
    if (!match) return;

    try {
      setActionLoading(true);
      const response = await fetch(`/api/matches/${match.id}/respond`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ response: 'accept' }),
      });

      if (!response.ok) {
        const data = await response.json();
        alert(data.error || 'Failed to accept match');
        return;
      }

      const data = await response.json();

      if (data.bothAccepted && data.chatRoomId) {
        alert('Both parties accepted! Chat room is ready.');
        // Optionally redirect to chat room
        // router.push(`/chat/${data.chatRoomId}`);
      } else {
        alert('Match accepted! Waiting for the other party.');
      }

      // Refresh the match data
      window.location.reload();
    } catch (err) {
      console.error('Error accepting match:', err);
      alert('Failed to accept match');
    } finally {
      setActionLoading(false);
    }
  };

  const handleDecline = async () => {
    if (!match) return;

    if (!confirm('Are you sure you want to decline this match?')) {
      return;
    }

    try {
      setActionLoading(true);
      const response = await fetch(`/api/matches/${match.id}/respond`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ response: 'decline' }),
      });

      if (!response.ok) {
        const data = await response.json();
        alert(data.error || 'Failed to decline match');
        return;
      }

      alert('Match declined');
      window.location.reload();
    } catch (err) {
      console.error('Error declining match:', err);
      alert('Failed to decline match');
    } finally {
      setActionLoading(false);
    }
  };

  const getStatusBadge = (status: string) => {
    const statusColors: { [key: string]: string } = {
      pending_external: 'bg-yellow-100 text-yellow-800',
      proposed: 'bg-blue-100 text-blue-800',
      pending: 'bg-blue-100 text-blue-800',
      accepted: 'bg-green-100 text-green-800',
      declined: 'bg-red-100 text-red-800',
      cancelled: 'bg-gray-100 text-gray-800',
    };

    const color = statusColors[status] || 'bg-gray-100 text-gray-800';

    return (
      <span className={`inline-flex items-center px-3 py-1 rounded-full text-sm font-medium ${color}`}>
        {status.replace('_', ' ').toUpperCase()}
      </span>
    );
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-purple-50 to-blue-50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-purple-600 mx-auto mb-4"></div>
          <p className="text-gray-600">Loading match...</p>
        </div>
      </div>
    );
  }

  if (error || !match) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-purple-50 to-blue-50 flex items-center justify-center p-4">
        <div className="bg-white rounded-lg shadow-xl p-8 max-w-md w-full text-center">
          <div className="text-red-500 text-5xl mb-4">⚠️</div>
          <h1 className="text-2xl font-bold text-gray-900 mb-2">Oops!</h1>
          <p className="text-gray-600 mb-6">{error || 'Match not found'}</p>
          <button
            onClick={() => router.push('/')}
            className="bg-purple-600 text-white px-6 py-2 rounded-lg hover:bg-purple-700 transition-colors"
          >
            Go to Home
          </button>
        </div>
      </div>
    );
  }

  const isExternal = match.status === 'pending_external';
  const isActive = ['pending_external', 'proposed', 'pending'].includes(match.status);
  const bothAccepted = match.a_accepted && match.b_accepted;

  return (
    <div className="min-h-screen bg-gradient-to-br from-purple-50 to-blue-50 py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-3xl mx-auto">
        <div className="bg-white rounded-2xl shadow-xl overflow-hidden">
          {/* Header */}
          <div className="bg-gradient-to-r from-purple-600 to-blue-600 px-8 py-6 text-white">
            <h1 className="text-3xl font-bold mb-2">MeetShipper Match</h1>
            <p className="text-purple-100">Someone connected you via MeetShipper!</p>
          </div>

          {/* Content */}
          <div className="p-8">
            {/* Status Badge */}
            <div className="mb-6">
              {getStatusBadge(match.status)}
            </div>

            {/* Creator Info */}
            <div className="mb-8 p-4 bg-gray-50 rounded-lg">
              <p className="text-sm text-gray-600 mb-2">Connected by</p>
              <div className="flex items-center gap-3">
                {match.creator.avatar_url && (
                  <Image
                    src={match.creator.avatar_url}
                    alt={match.creator.username}
                    width={40}
                    height={40}
                    className="rounded-full"
                  />
                )}
                <div>
                  <p className="font-semibold text-gray-900">
                    {match.creator.display_name}
                  </p>
                  <p className="text-sm text-gray-600">@{match.creator.username}</p>
                </div>
              </div>
            </div>

            {/* Message */}
            <div className="mb-8">
              <h2 className="text-lg font-semibold text-gray-900 mb-2">Message</h2>
              <p className="text-gray-700 bg-blue-50 p-4 rounded-lg italic">
                "{match.message}"
              </p>
            </div>

            {/* Users */}
            <div className="mb-8">
              <h2 className="text-lg font-semibold text-gray-900 mb-4">Match Participants</h2>
              <div className="grid md:grid-cols-2 gap-6">
                {/* User A */}
                <div className="border border-gray-200 rounded-lg p-4 hover:border-purple-300 transition-colors">
                  <div className="flex items-start gap-3 mb-3">
                    {match.user_a.avatar_url && (
                      <Image
                        src={match.user_a.avatar_url}
                        alt={match.user_a.username}
                        width={60}
                        height={60}
                        className="rounded-full"
                      />
                    )}
                    <div className="flex-1">
                      <p className="font-semibold text-gray-900">
                        {match.user_a.display_name}
                      </p>
                      <p className="text-sm text-gray-600">@{match.user_a.username}</p>
                    </div>
                  </div>
                  {match.user_a.bio && (
                    <p className="text-sm text-gray-600 line-clamp-3">{match.user_a.bio}</p>
                  )}
                  {match.a_accepted && (
                    <div className="mt-3 flex items-center gap-1 text-green-600 text-sm font-medium">
                      <span>✓</span> Accepted
                    </div>
                  )}
                </div>

                {/* User B */}
                <div className="border border-gray-200 rounded-lg p-4 hover:border-purple-300 transition-colors">
                  <div className="flex items-start gap-3 mb-3">
                    {match.user_b.avatar_url && (
                      <Image
                        src={match.user_b.avatar_url}
                        alt={match.user_b.username}
                        width={60}
                        height={60}
                        className="rounded-full"
                      />
                    )}
                    <div className="flex-1">
                      <p className="font-semibold text-gray-900">
                        {match.user_b.display_name}
                      </p>
                      <p className="text-sm text-gray-600">@{match.user_b.username}</p>
                    </div>
                  </div>
                  {match.user_b.bio && (
                    <p className="text-sm text-gray-600 line-clamp-3">{match.user_b.bio}</p>
                  )}
                  {match.b_accepted && (
                    <div className="mt-3 flex items-center gap-1 text-green-600 text-sm font-medium">
                      <span>✓</span> Accepted
                    </div>
                  )}
                </div>
              </div>
            </div>

            {/* Action Buttons */}
            {isActive && !bothAccepted && (
              <>
                {isExternal ? (
                  // External matches - show join button
                  <div className="text-center">
                    <button
                      onClick={() => {
                        const baseUrl = process.env.NEXT_PUBLIC_BASE_URL ||
                                       process.env.NEXT_PUBLIC_APP_URL ||
                                       'https://www.meetshipper.com';
                        window.location.href = baseUrl;
                      }}
                      className="inline-flex items-center justify-center bg-gradient-to-r from-purple-600 to-blue-600 text-white px-8 py-4 rounded-lg font-semibold text-lg hover:from-purple-700 hover:to-blue-700 transition-all shadow-lg hover:shadow-xl"
                    >
                      Join MeetShipper to Accept or Decline
                    </button>
                    <p className="mt-4 text-gray-600 text-sm max-w-md mx-auto">
                      You need to join MeetShipper to respond to this match.<br />
                      Scan the QR or visit MeetShipper.com to get started.
                    </p>
                  </div>
                ) : (
                  // Internal matches - show accept/decline buttons
                  <div className="flex gap-4">
                    <button
                      onClick={handleAccept}
                      disabled={actionLoading}
                      className="flex-1 bg-green-600 text-white px-6 py-3 rounded-lg font-semibold hover:bg-green-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                    >
                      {actionLoading ? 'Processing...' : 'Accept Match'}
                    </button>
                    <button
                      onClick={handleDecline}
                      disabled={actionLoading}
                      className="flex-1 bg-gray-200 text-gray-700 px-6 py-3 rounded-lg font-semibold hover:bg-gray-300 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                    >
                      {actionLoading ? 'Processing...' : 'Decline'}
                    </button>
                  </div>
                )}
              </>
            )}

            {bothAccepted && match.chat_room_id && (
              <div className="bg-green-50 border border-green-200 rounded-lg p-6 text-center">
                <div className="text-green-600 text-5xl mb-3">🎉</div>
                <h3 className="text-xl font-bold text-gray-900 mb-2">
                  Both parties accepted!
                </h3>
                <p className="text-gray-600 mb-4">The chat room is ready for your conversation.</p>
                <button
                  onClick={() => router.push(`/chat/${match.chat_room_id}`)}
                  className="bg-green-600 text-white px-6 py-3 rounded-lg font-semibold hover:bg-green-700 transition-colors"
                >
                  Go to Chat Room
                </button>
              </div>
            )}

            {!isActive && !bothAccepted && (
              <div className="bg-gray-50 border border-gray-200 rounded-lg p-6 text-center">
                <p className="text-gray-600">
                  This match is no longer active.
                </p>
              </div>
            )}
          </div>

          {/* Footer */}
          <div className="bg-gray-50 px-8 py-4 border-t border-gray-200">
            <p className="text-sm text-gray-500 text-center">
              Created on {new Date(match.created_at).toLocaleDateString()} at{' '}
              {new Date(match.created_at).toLocaleTimeString()}
            </p>
          </div>
        </div>

        {/* Back Button */}
        <div className="mt-6 text-center">
          <button
            onClick={() => router.push('/')}
            className="text-purple-600 hover:text-purple-700 font-medium"
          >
            ← Back to Home
          </button>
        </div>
      </div>
    </div>
  );
}
