'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useFarcasterAuth } from '@/components/providers/FarcasterAuthProvider';
import { Navigation } from '@/components/shared/Navigation';
import Image from 'next/image';
import { apiClient } from '@/lib/api-client';
import { Trait } from '@/lib/constants/traits';

interface MatchRationale {
  traitOverlap: Trait[];
  bioKeywords: string[];
  score: number;
  traitSimilarity?: number;
  bioSimilarity?: number;
  manualMatch?: boolean;
}

interface Match {
  id: string;
  user_a_fid: number;
  user_a_username: string;
  user_a_display_name: string;
  user_a_avatar_url: string;
  user_a_traits: Trait[];
  user_b_fid: number;
  user_b_username: string;
  user_b_display_name: string;
  user_b_avatar_url: string;
  user_b_traits: Trait[];
  created_by_fid: number;
  created_by: string;
  creator_username: string;
  creator_display_name: string;
  creator_avatar_url: string;
  status: 'proposed' | 'pending' | 'accepted_by_a' | 'accepted_by_b' | 'accepted' | 'declined' | 'cancelled' | 'completed';
  message?: string;
  rationale?: MatchRationale;
  a_accepted: boolean;
  b_accepted: boolean;
  a_completed: boolean;
  b_completed: boolean;
  meeting_link?: string;
  scheduled_at?: string;
  completed_at?: string;
  meeting_state?: 'scheduled' | 'in_progress' | 'closed';
  meeting_started_at?: string;
  meeting_expires_at?: string;
  meeting_closed_at?: string;
  created_at: string;
  updated_at: string;
}

type InboxTab = 'pending' | 'awaiting' | 'accepted' | 'declined' | 'completed';

export default function Inbox() {
  const router = useRouter();
  const { user, isAuthenticated, loading: authLoading } = useFarcasterAuth();
  const [activeTab, setActiveTab] = useState<InboxTab>('pending');
  const [matches, setMatches] = useState<Match[]>([]);
  const [selectedMatch, setSelectedMatch] = useState<Match | null>(null);
  const [loading, setLoading] = useState(true);
  const [actionLoading, setActionLoading] = useState(false);
  const [currentTime, setCurrentTime] = useState(Date.now());

  useEffect(() => {
    if (!authLoading && !isAuthenticated) {
      router.push('/');
    }
  }, [isAuthenticated, authLoading, router]);

  useEffect(() => {
    if (isAuthenticated) {
      fetchMatches();
    }
  }, [isAuthenticated, activeTab]);

  // Update timer every second for countdown
  useEffect(() => {
    const interval = setInterval(() => {
      setCurrentTime(Date.now());
    }, 1000);
    return () => clearInterval(interval);
  }, []);

  const fetchMatches = async () => {
    setLoading(true);
    try {
      const data = await apiClient.get<{ matches: Match[] }>(
        `/api/matches?scope=${activeTab}`
      );

      if (data.matches) {
        setMatches(data.matches);
      }
    } catch (error) {
      console.error('Error fetching matches:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleRespond = async (matchId: string, response: 'accept' | 'decline', reason?: string) => {
    setActionLoading(true);
    try {
      const data = await apiClient.post<{ match: Match; meetingLink?: string }>(
        `/api/matches/${matchId}/respond`,
        { response, reason }
      );

      // Refresh matches list
      await fetchMatches();

      // Update selected match
      if (selectedMatch?.id === matchId) {
        setSelectedMatch(data.match);
      }

      // Show meeting link if both accepted
      if (data.meetingLink) {
        alert(`Meeting scheduled! Link: ${data.meetingLink}`);
      }
    } catch (error: any) {
      console.error('Error responding to match:', error);
      alert(error.message || 'Failed to respond to match');
    } finally {
      setActionLoading(false);
    }
  };

  const handleComplete = async (matchId: string) => {
    setActionLoading(true);
    try {
      const data = await apiClient.post<{ match: Match; bothCompleted: boolean; message: string }>(
        `/api/matches/${matchId}/complete`,
        {}
      );

      // Refresh matches list
      await fetchMatches();

      // Update selected match
      if (selectedMatch?.id === matchId) {
        setSelectedMatch(data.match);
      }

      // Show success message
      alert(data.message || 'Meeting marked as completed');
    } catch (error: any) {
      console.error('Error completing match:', error);
      alert(error.message || 'Failed to mark meeting as completed');
    } finally {
      setActionLoading(false);
    }
  };

  const getMatchDisplayInfo = (match: Match) => {
    if (!user) return null;

    const isUserA = match.user_a_fid === user.fid;
    const isUserB = match.user_b_fid === user.fid;

    if (isUserA) {
      return {
        title: match.user_b_display_name,
        subtitle: `@${match.user_b_username}`,
        avatar: match.user_b_avatar_url,
        otherUser: {
          fid: match.user_b_fid,
          username: match.user_b_username,
          displayName: match.user_b_display_name,
          traits: match.user_b_traits || [],
        },
      };
    } else if (isUserB) {
      return {
        title: match.user_a_display_name,
        subtitle: `@${match.user_a_username}`,
        avatar: match.user_a_avatar_url,
        otherUser: {
          fid: match.user_a_fid,
          username: match.user_a_username,
          displayName: match.user_a_display_name,
          traits: match.user_a_traits || [],
        },
      };
    }

    return null;
  };

  const needsMyAction = (match: Match): boolean => {
    if (!user) return false;
    const isUserA = match.user_a_fid === user.fid;
    const isUserB = match.user_b_fid === user.fid;

    if (isUserA && !match.a_accepted) return true;
    if (isUserB && !match.b_accepted) return true;

    return false;
  };

  const getRationaleMessage = (rationale?: MatchRationale): string | null => {
    if (!rationale) return null;
    if (rationale.manualMatch) return 'Manual match by admin';

    const parts: string[] = [];

    if (rationale.traitOverlap && rationale.traitOverlap.length > 0) {
      const traits = rationale.traitOverlap.slice(0, 4).join(', ');
      const remaining = rationale.traitOverlap.length - 4;
      parts.push(
        `You share ${rationale.traitOverlap.length} common trait${rationale.traitOverlap.length > 1 ? 's' : ''}: ${traits}${remaining > 0 ? ` +${remaining} more` : ''}`
      );
    }

    if (rationale.bioKeywords && rationale.bioKeywords.length > 0) {
      const keywords = rationale.bioKeywords.slice(0, 3).join(', ');
      parts.push(`Both mention: ${keywords}`);
    }

    if (rationale.score) {
      const percentage = Math.round(rationale.score * 100);
      parts.push(`Match score: ${percentage}%`);
    }

    return parts.join('. ');
  };

  const getStatusBadgeColor = (status: string): string => {
    switch (status) {
      case 'accepted':
        return 'bg-green-100 text-green-800 border-green-200';
      case 'proposed':
      case 'pending':
        return 'bg-yellow-100 text-yellow-800 border-yellow-200';
      case 'accepted_by_a':
      case 'accepted_by_b':
        return 'bg-blue-100 text-blue-800 border-blue-200';
      case 'declined':
        return 'bg-red-100 text-red-800 border-red-200';
      default:
        return 'bg-gray-100 text-gray-800 border-gray-200';
    }
  };

  const getStatusLabel = (match: Match): string => {
    if (match.status === 'accepted_by_a' || match.status === 'accepted_by_b') {
      const isUserA = match.user_a_fid === user?.fid;
      const myAccepted = isUserA ? match.a_accepted : match.b_accepted;
      return myAccepted ? 'Awaiting other party' : 'Needs your response';
    }
    return match.status.replace(/_/g, ' ');
  };

  const getPendingMatches = () => matches.filter(needsMyAction);
  const getAwaitingMatches = () => {
    if (!user) return [];
    return matches.filter(m => {
      const isUserA = m.user_a_fid === user.fid;
      const isUserB = m.user_b_fid === user.fid;
      return (isUserA && m.a_accepted && !m.b_accepted) ||
             (isUserB && m.b_accepted && !m.a_accepted);
    });
  };

  const getMeetingTimeInfo = (match: Match): {
    status: 'scheduled' | 'in_progress' | 'expired' | 'closed';
    timeRemaining?: string;
    expiresAt?: Date;
  } => {
    if (match.meeting_state === 'closed') {
      return { status: 'closed' };
    }

    if (!match.meeting_expires_at) {
      return { status: 'scheduled' };
    }

    const expiresAt = new Date(match.meeting_expires_at);
    const now = new Date(currentTime);
    const msRemaining = expiresAt.getTime() - now.getTime();

    if (msRemaining <= 0) {
      return { status: 'expired', expiresAt };
    }

    // Calculate hours and minutes remaining
    const hoursRemaining = Math.floor(msRemaining / (1000 * 60 * 60));
    const minutesRemaining = Math.floor((msRemaining % (1000 * 60 * 60)) / (1000 * 60));

    return {
      status: 'in_progress',
      timeRemaining: `${hoursRemaining}h ${minutesRemaining}m`,
      expiresAt,
    };
  };

  if (authLoading || !user) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-purple-600 mx-auto"></div>
          <p className="mt-4 text-gray-600">Loading...</p>
        </div>
      </div>
    );
  }

  const pendingCount = getPendingMatches().length;
  const awaitingCount = getAwaitingMatches().length;

  return (
    <div className="min-h-screen bg-gray-50">
      <Navigation />

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="flex items-center justify-between mb-6">
          <h1 className="text-3xl font-bold text-gray-900">Inbox</h1>
          <button
            onClick={() => router.push('/mini/create')}
            className="px-4 py-2 bg-purple-600 text-white rounded-md hover:bg-purple-700 text-sm font-medium"
          >
            Create Match
          </button>
        </div>

        {/* Tabs */}
        <div className="bg-white rounded-lg shadow-md mb-6">
          <div className="border-b border-gray-200">
            <nav className="flex -mb-px">
              <button
                onClick={() => setActiveTab('pending')}
                className={`py-4 px-6 text-sm font-medium border-b-2 ${
                  activeTab === 'pending'
                    ? 'border-purple-500 text-purple-600'
                    : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                }`}
              >
                Pending
                {pendingCount > 0 && (
                  <span className="ml-2 px-2 py-1 rounded-full bg-red-100 text-red-600 text-xs font-bold">
                    {pendingCount}
                  </span>
                )}
              </button>
              <button
                onClick={() => setActiveTab('awaiting')}
                className={`py-4 px-6 text-sm font-medium border-b-2 ${
                  activeTab === 'awaiting'
                    ? 'border-purple-500 text-purple-600'
                    : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                }`}
              >
                Awaiting Other Party
                {awaitingCount > 0 && (
                  <span className="ml-2 px-2 py-1 rounded-full bg-blue-100 text-blue-600 text-xs font-bold">
                    {awaitingCount}
                  </span>
                )}
              </button>
              <button
                onClick={() => setActiveTab('accepted')}
                className={`py-4 px-6 text-sm font-medium border-b-2 ${
                  activeTab === 'accepted'
                    ? 'border-purple-500 text-purple-600'
                    : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                }`}
              >
                Accepted
              </button>
              <button
                onClick={() => setActiveTab('declined')}
                className={`py-4 px-6 text-sm font-medium border-b-2 ${
                  activeTab === 'declined'
                    ? 'border-purple-500 text-purple-600'
                    : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                }`}
              >
                Declined
              </button>
              <button
                onClick={() => setActiveTab('completed')}
                className={`py-4 px-6 text-sm font-medium border-b-2 ${
                  activeTab === 'completed'
                    ? 'border-purple-500 text-purple-600'
                    : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                }`}
              >
                Completed
              </button>
            </nav>
          </div>
        </div>

        {/* Content */}
        {loading ? (
          <div className="flex items-center justify-center py-12">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-purple-600"></div>
          </div>
        ) : matches.length === 0 ? (
          <div className="bg-white rounded-lg shadow-md p-8 text-center">
            <p className="text-gray-600 mb-4">
              {activeTab === 'pending' && 'No pending matches'}
              {activeTab === 'awaiting' && 'No matches awaiting response'}
              {activeTab === 'accepted' && 'No accepted matches yet'}
              {activeTab === 'declined' && 'No declined matches'}
              {activeTab === 'completed' && 'No completed meetings yet'}
            </p>
          </div>
        ) : (
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            {/* Matches List */}
            <div className="lg:col-span-1 space-y-4">
              {matches.map((match) => {
                const displayInfo = getMatchDisplayInfo(match);
                if (!displayInfo) return null;

                return (
                  <button
                    key={match.id}
                    onClick={() => setSelectedMatch(match)}
                    className={`w-full p-4 bg-white rounded-lg shadow-md hover:shadow-lg transition-shadow text-left ${
                      selectedMatch?.id === match.id ? 'ring-2 ring-purple-500' : ''
                    }`}
                  >
                    <div className="flex items-start space-x-3">
                      <Image
                        src={displayInfo.avatar}
                        alt={displayInfo.title}
                        width={48}
                        height={48}
                        className="rounded-full"
                      />
                      <div className="flex-1 min-w-0">
                        <p className="font-medium text-gray-900 truncate">
                          {displayInfo.title}
                        </p>
                        <p className="text-sm text-gray-600 truncate">
                          {displayInfo.subtitle}
                        </p>
                        <div className="mt-2">
                          <span className={`inline-block px-2 py-1 rounded text-xs font-medium border ${getStatusBadgeColor(match.status)}`}>
                            {getStatusLabel(match)}
                          </span>
                        </div>
                        {needsMyAction(match) && (
                          <div className="mt-2">
                            <span className="inline-block px-2 py-1 rounded text-xs font-bold bg-red-100 text-red-700 border border-red-200">
                              Action needed
                            </span>
                          </div>
                        )}
                      </div>
                    </div>
                  </button>
                );
              })}
            </div>

            {/* Match Details */}
            <div className="lg:col-span-2 bg-white rounded-lg shadow-md p-6">
              {!selectedMatch ? (
                <div className="flex items-center justify-center h-64">
                  <p className="text-gray-600">Select a match to view details</p>
                </div>
              ) : (
                <>
                  {/* Header */}
                  <div className="border-b border-gray-200 pb-4 mb-4">
                    <div className="flex items-start justify-between">
                      <div className="flex items-center space-x-3">
                        <Image
                          src={getMatchDisplayInfo(selectedMatch)?.avatar || ''}
                          alt={getMatchDisplayInfo(selectedMatch)?.title || ''}
                          width={64}
                          height={64}
                          className="rounded-full"
                        />
                        <div>
                          <h3 className="text-xl font-bold text-gray-900">
                            {getMatchDisplayInfo(selectedMatch)?.title}
                          </h3>
                          <p className="text-sm text-gray-600">
                            {getMatchDisplayInfo(selectedMatch)?.subtitle}
                          </p>
                        </div>
                      </div>
                      <span className={`px-3 py-1 rounded-full text-sm font-medium border ${getStatusBadgeColor(selectedMatch.status)}`}>
                        {getStatusLabel(selectedMatch)}
                      </span>
                    </div>
                  </div>

                  {/* Rationale */}
                  {selectedMatch.rationale && (
                    <div className="bg-purple-50 border border-purple-200 rounded-lg p-4 mb-4">
                      <h4 className="font-semibold text-purple-900 mb-2">Why you matched:</h4>
                      <p className="text-sm text-purple-800">
                        {getRationaleMessage(selectedMatch.rationale)}
                      </p>
                      {selectedMatch.rationale.traitOverlap && selectedMatch.rationale.traitOverlap.length > 0 && (
                        <div className="mt-3 flex flex-wrap gap-2">
                          {selectedMatch.rationale.traitOverlap.slice(0, 6).map((trait) => (
                            <span
                              key={trait}
                              className="px-2 py-1 bg-white border border-purple-300 rounded text-xs font-medium text-purple-700"
                            >
                              {trait}
                            </span>
                          ))}
                        </div>
                      )}
                    </div>
                  )}

                  {/* Message from creator */}
                  {selectedMatch.message && (
                    <div className="bg-gray-50 border border-gray-200 rounded-lg p-4 mb-4">
                      <h4 className="font-semibold text-gray-900 mb-2">
                        Message from @{selectedMatch.creator_username}:
                      </h4>
                      <p className="text-sm text-gray-700">"{selectedMatch.message}"</p>
                    </div>
                  )}

                  {/* Action Buttons */}
                  {needsMyAction(selectedMatch) && (
                    <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4 mb-4">
                      <p className="text-sm text-gray-700 mb-3 font-medium">
                        Do you want to connect with this person?
                      </p>
                      <div className="flex space-x-3">
                        <button
                          onClick={() => handleRespond(selectedMatch.id, 'accept')}
                          disabled={actionLoading}
                          className="flex-1 bg-green-600 text-white px-4 py-2 rounded-md hover:bg-green-700 disabled:bg-gray-300 font-medium"
                        >
                          {actionLoading ? 'Processing...' : 'Accept'}
                        </button>
                        <button
                          onClick={() => handleRespond(selectedMatch.id, 'decline')}
                          disabled={actionLoading}
                          className="flex-1 bg-red-600 text-white px-4 py-2 rounded-md hover:bg-red-700 disabled:bg-gray-300 font-medium"
                        >
                          Decline
                        </button>
                      </div>
                    </div>
                  )}

                  {/* Meeting Link & Completion */}
                  {selectedMatch.status === 'accepted' && selectedMatch.meeting_link && (() => {
                    const timeInfo = getMeetingTimeInfo(selectedMatch);
                    const isRoomClosed = timeInfo.status === 'closed' || timeInfo.status === 'expired';

                    return (
                      <div className="bg-green-50 border border-green-200 rounded-lg p-4">
                        <h4 className="font-semibold text-green-900 mb-2">Meeting Scheduled!</h4>
                        <p className="text-sm text-green-800 mb-3">
                          Both parties have accepted. Your meeting is ready!
                        </p>

                        {/* 2-Hour Rule Message */}
                        {timeInfo.status === 'scheduled' && (
                          <div className="bg-blue-50 border border-blue-300 rounded-md p-3 mb-3">
                            <p className="text-sm text-blue-800">
                              ⏱️ <strong>Important:</strong> After someone joins the meeting, you'll have 2 hours before the room automatically closes.
                            </p>
                          </div>
                        )}

                        {/* Countdown Timer */}
                        {timeInfo.status === 'in_progress' && timeInfo.timeRemaining && (
                          <div className="bg-yellow-50 border border-yellow-300 rounded-md p-3 mb-3">
                            <p className="text-sm text-yellow-800">
                              ⏳ <strong>Time remaining:</strong> {timeInfo.timeRemaining}
                            </p>
                            <p className="text-xs text-yellow-700 mt-1">
                              Room will automatically close when time expires.
                            </p>
                          </div>
                        )}

                        {/* Room Closed Message */}
                        {isRoomClosed && (
                          <div className="bg-red-50 border border-red-300 rounded-md p-3 mb-3">
                            <p className="text-sm text-red-800">
                              🔒 <strong>Meeting room closed.</strong> The 2-hour window has expired.
                            </p>
                          </div>
                        )}

                        <div className="flex space-x-3">
                          <a
                            href={selectedMatch.meeting_link}
                            target="_blank"
                            rel="noopener noreferrer"
                            className={`inline-block px-6 py-2 rounded-md font-medium ${
                              isRoomClosed
                                ? 'bg-gray-300 text-gray-500 cursor-not-allowed pointer-events-none'
                                : 'bg-green-600 text-white hover:bg-green-700'
                            }`}
                          >
                            {isRoomClosed ? 'Room Closed' : 'Join Meeting'}
                          </a>
                          {!selectedMatch.a_completed || !selectedMatch.b_completed ? (
                            <button
                              onClick={() => handleComplete(selectedMatch.id)}
                              disabled={actionLoading || (user && ((selectedMatch.user_a_fid === user.fid && selectedMatch.a_completed) || (selectedMatch.user_b_fid === user.fid && selectedMatch.b_completed)))}
                              className="bg-yellow-500 text-white px-6 py-2 rounded-md hover:bg-yellow-600 disabled:bg-gray-300 disabled:cursor-not-allowed font-medium"
                            >
                              {actionLoading ? 'Processing...' :
                               (user && ((selectedMatch.user_a_fid === user.fid && selectedMatch.a_completed) || (selectedMatch.user_b_fid === user.fid && selectedMatch.b_completed)))
                               ? 'Marked as Completed'
                               : 'Meeting Completed'}
                            </button>
                          ) : null}
                        </div>
                      </div>
                    );
                  })()}

                  {/* Completed Meeting Message */}
                  {selectedMatch.status === 'completed' && (
                    <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
                      <h4 className="font-semibold text-blue-900 mb-2">✅ Meeting Completed!</h4>
                      <p className="text-sm text-blue-800">
                        Both parties have confirmed that the meeting took place.
                      </p>
                      {selectedMatch.completed_at && (
                        <p className="text-xs text-blue-600 mt-2">
                          Completed on {new Date(selectedMatch.completed_at).toLocaleDateString()} at {new Date(selectedMatch.completed_at).toLocaleTimeString()}
                        </p>
                      )}
                    </div>
                  )}

                  {/* Created by system */}
                  {selectedMatch.created_by === 'system' && (
                    <div className="mt-4 text-center">
                      <p className="text-xs text-gray-500">
                        This match was automatically generated by the system
                      </p>
                    </div>
                  )}
                </>
              )}
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
