'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useFarcasterAuth } from '@/components/providers/FarcasterAuthProvider';
import { Navigation } from '@/components/shared/Navigation';
import Image from 'next/image';
import { apiClient, declineAllMatch } from '@/lib/api-client';
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
  status: 'proposed' | 'pending' | 'pending_external' | 'accepted_by_a' | 'accepted_by_b' | 'accepted' | 'declined' | 'cancelled' | 'completed';
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

type InboxTab = 'pending' | 'awaiting' | 'accepted' | 'declined' | 'completed' | 'suggestions' | 'your-suggestions';

interface Suggestion {
  id: string;
  message: string;
  status: string;
  myAcceptance: boolean;
  otherAcceptance: boolean;
  otherUser: {
    fid: number;
    username: string;
    displayName: string;
    avatarUrl: string;
  };
  chatRoomId: string | null;
  createdAt: string;
  updatedAt: string;
}

interface UserSuggestion {
  id: string;
  userA: {
    fid: number;
    username: string;
    displayName: string;
    avatarUrl: string;
  };
  userB: {
    fid: number;
    username: string;
    displayName: string;
    avatarUrl: string;
  };
  message: string;
  status: string;
  aAccepted: boolean;
  bAccepted: boolean;
  chatRoomId: string | null;
  createdAt: string;
  updatedAt: string;
}

export default function Inbox() {
  const router = useRouter();
  const { user, isAuthenticated, loading: authLoading } = useFarcasterAuth();
  const [activeTab, setActiveTab] = useState<InboxTab>('pending');
  const [matches, setMatches] = useState<Match[]>([]);
  const [selectedMatch, setSelectedMatch] = useState<Match | null>(null);
  const [loading, setLoading] = useState(true);
  const [actionLoading, setActionLoading] = useState(false);
  const [currentTime, setCurrentTime] = useState(Date.now());
  const [chatRoomMap, setChatRoomMap] = useState<Map<string, string>>(new Map()); // matchId -> roomId
  const [suggestions, setSuggestions] = useState<Suggestion[]>([]);
  const [userSuggestions, setUserSuggestions] = useState<UserSuggestion[]>([]);
  const [selectedUserSuggestion, setSelectedUserSuggestion] = useState<UserSuggestion | null>(null);
  const [showSuggestionSidebar, setShowSuggestionSidebar] = useState(true);
  const [showMatchSidebar, setShowMatchSidebar] = useState(true);
  const [selectedSuggestion, setSelectedSuggestion] = useState<Suggestion | null>(null);
  const [showIncomingSuggestionSidebar, setShowIncomingSuggestionSidebar] = useState(true);

  useEffect(() => {
    if (!authLoading && !isAuthenticated) {
      router.push('/');
    }
  }, [isAuthenticated, authLoading, router]);

  useEffect(() => {
    if (isAuthenticated) {
      if (activeTab === 'suggestions') {
        fetchSuggestions();
      } else if (activeTab === 'your-suggestions') {
        fetchUserSuggestions();
      } else {
        fetchMatches();
      }
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

        // Fetch chat room IDs for accepted matches
        const acceptedMatches = data.matches.filter(m => m.status === 'accepted' || m.status === 'completed');
        if (acceptedMatches.length > 0) {
          fetchChatRooms(acceptedMatches);
        }
      }
    } catch (error) {
      console.error('Error fetching matches:', error);
    } finally {
      setLoading(false);
    }
  };

  const fetchChatRooms = async (matches: Match[]) => {
    try {
      // Fetch chat rooms via Supabase client
      const { data: chatRooms, error } = await apiClient.get<any>('/api/chat/rooms/by-matches', {
        matchIds: matches.map(m => m.id)
      }).catch(async () => {
        // Fallback: use supabase directly
        const { supabase: sb } = await import('@/lib/supabase');
        return sb
          .from('chat_rooms')
          .select('id, match_id')
          .in('match_id', matches.map(m => m.id));
      });

      if (chatRooms) {
        const newMap = new Map<string, string>();
        const rooms = Array.isArray(chatRooms) ? chatRooms : chatRooms.data || [];
        rooms.forEach((room: any) => {
          newMap.set(room.match_id, room.id);
        });
        setChatRoomMap(newMap);
      }
    } catch (error) {
      console.error('Error fetching chat rooms:', error);
    }
  };

  const fetchSuggestions = async () => {
    setLoading(true);
    try {
      const data = await apiClient.get<{ success: boolean; suggestions: Suggestion[]; total: number }>(
        '/api/inbox/suggestions'
      );
      if (data.success && data.suggestions) {
        setSuggestions(data.suggestions);
        // Auto-select first suggestion if none selected
        if (data.suggestions.length > 0 && !selectedSuggestion) {
          setSelectedSuggestion(data.suggestions[0]);
        }
      }
    } catch (error) {
      console.error('Error fetching suggestions:', error);
    } finally {
      setLoading(false);
    }
  };

  const fetchUserSuggestions = async () => {
    setLoading(true);
    try {
      const data = await apiClient.get<{ success: boolean; data: UserSuggestion[]; total: number }>(
        '/api/matches/my-suggestions'
      );
      if (data.success && data.data) {
        setUserSuggestions(data.data);
        // Auto-select first suggestion if none selected
        if (data.data.length > 0 && !selectedUserSuggestion) {
          setSelectedUserSuggestion(data.data[0]);
        }
      }
    } catch (error) {
      console.error('Error fetching your suggestions:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleAcceptSuggestion = async (suggestionId: string) => {
    setActionLoading(true);
    try {
      await apiClient.post(`/api/matches/suggestions/${suggestionId}/accept`, {});
      await fetchSuggestions();
    } catch (error) {
      console.error('Error accepting suggestion:', error);
      alert('Failed to accept suggestion');
    } finally {
      setActionLoading(false);
    }
  };

  const handleDeclineSuggestion = async (suggestionId: string) => {
    if (!confirm('Are you sure you want to decline this suggestion? A 7-day cooldown will be applied.')) {
      return;
    }

    setActionLoading(true);
    try {
      await apiClient.post(`/api/matches/suggestions/${suggestionId}/decline`, {});
      await fetchSuggestions();
    } catch (error) {
      console.error('Error declining suggestion:', error);
      alert('Failed to decline suggestion');
    } finally {
      setActionLoading(false);
    }
  };

  const handleRespond = async (matchId: string, response: 'accept' | 'decline', reason?: string) => {
    setActionLoading(true);
    try {
      // Use the new decline-all endpoint for decline actions
      // This provides a permanent fix for the cooldown conflict issue
      if (response === 'decline') {
        const result = await declineAllMatch(matchId);

        if (!result.success) {
          // Handle specific error cases
          if (result.reason === 'already_terminal') {
            alert(result.message || 'This match is already closed.');
          } else {
            alert(result.message || 'Failed to decline match. Please try again.');
          }
          return;
        }

        // Optimistically update UI - move to declined
        setMatches(prev => prev.map(m =>
          m.id === matchId
            ? { ...m, status: 'declined' as const, a_accepted: false, b_accepted: false }
            : m
        ));

        if (selectedMatch?.id === matchId) {
          setSelectedMatch(prev => prev ? {
            ...prev,
            status: 'declined',
            a_accepted: false,
            b_accepted: false
          } : null);
        }

        // Show success message
        alert('Match declined for both participants.');

        // Refresh matches list to get updated state
        await fetchMatches();
      } else {
        // Accept uses the original respond endpoint
        const data = await apiClient.post<{ match: Match; chatRoomId?: string }>(
          `/api/matches/${matchId}/respond`,
          { response, reason }
        );

        // Refresh matches list
        await fetchMatches();

        // Update selected match
        if (selectedMatch?.id === matchId) {
          setSelectedMatch(data.match);
        }

        // Store chat room ID if both accepted
        if (data.chatRoomId) {
          setChatRoomMap(prev => new Map(prev).set(matchId, data.chatRoomId!));
        }
      }
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      console.error('Error responding to match:', error);
      alert(errorMessage || 'Failed to respond to match');
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
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      console.error('Error completing match:', error);
      alert(errorMessage || 'Failed to mark meeting as completed');
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

  // Helper to check if a match is in a terminal state
  const isTerminalStatus = (status: string): boolean => {
    return status === 'declined' || status === 'cancelled' || status === 'completed';
  };

  const needsMyAction = (match: Match): boolean => {
    if (!user) return false;

    // Terminal matches never need action
    if (isTerminalStatus(match.status)) return false;

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
        return 'bg-gradient-to-r from-green-50/90 to-emerald-50/90 text-green-800 border-green-200';
      case 'proposed':
      case 'pending':
      case 'pending_external':
        return 'bg-gradient-to-r from-yellow-50/90 to-amber-50/90 text-yellow-800 border-yellow-200';
      case 'accepted_by_a':
      case 'accepted_by_b':
        return 'bg-gradient-to-r from-blue-50/90 to-cyan-50/90 text-blue-800 border-blue-200';
      case 'declined':
        return 'bg-gradient-to-r from-red-50/90 to-rose-50/90 text-red-800 border-red-200';
      case 'completed':
        return 'bg-gradient-to-r from-purple-50/90 to-violet-50/90 text-purple-800 border-purple-200';
      default:
        return 'bg-gradient-to-r from-gray-50/90 to-slate-50/90 text-gray-800 border-gray-200';
    }
  };

  const getStatusEmoji = (status: string): string => {
    switch (status) {
      case 'accepted':
        return '✅';
      case 'proposed':
      case 'pending':
      case 'pending_external':
        return '⏳';
      case 'accepted_by_a':
      case 'accepted_by_b':
        return '💬';
      case 'declined':
        return '❌';
      case 'completed':
        return '🟣';
      default:
        return '○';
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

  const getUserSuggestionStatus = (suggestion: UserSuggestion): { label: string; emoji: string; color: string } => {
    if (suggestion.status === 'accepted' && suggestion.aAccepted && suggestion.bAccepted) {
      return { label: 'Accepted', emoji: '✅', color: 'bg-green-100 text-green-800 border-green-200' };
    }
    if (suggestion.status === 'declined') {
      return { label: 'Declined', emoji: '❌', color: 'bg-red-100 text-red-800 border-red-200' };
    }
    if (suggestion.status === 'accepted_by_a' || suggestion.status === 'accepted_by_b' || suggestion.aAccepted || suggestion.bAccepted) {
      return { label: 'Pending', emoji: '⏳', color: 'bg-yellow-100 text-yellow-800 border-yellow-200' };
    }
    return { label: 'Pending', emoji: '⏳', color: 'bg-yellow-100 text-yellow-800 border-yellow-200' };
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
        <div className="backdrop-blur-xl bg-gradient-to-br from-white/80 via-purple-50/60 to-blue-50/60 rounded-2xl border border-white/60 shadow-lg mb-6">
          <div className="border-b border-purple-100">
            <nav className="flex -mb-px overflow-x-auto">
              <button
                onClick={() => setActiveTab('pending')}
                className={`py-4 px-6 text-sm font-medium border-b-2 transition-all duration-200 whitespace-nowrap ${
                  activeTab === 'pending'
                    ? 'border-purple-500 text-purple-700 bg-gradient-to-b from-purple-50/50 to-transparent'
                    : 'border-transparent text-gray-600 hover:text-purple-600 hover:border-purple-200'
                }`}
              >
                <span className="flex items-center gap-2">
                  <span>🕓</span>
                  <span>Pending</span>
                  {pendingCount > 0 && (
                    <span className="px-2 py-0.5 rounded-full bg-red-100 text-red-600 text-xs font-bold">
                      {pendingCount}
                    </span>
                  )}
                </span>
              </button>
              <button
                onClick={() => setActiveTab('awaiting')}
                className={`py-4 px-6 text-sm font-medium border-b-2 transition-all duration-200 whitespace-nowrap ${
                  activeTab === 'awaiting'
                    ? 'border-purple-500 text-purple-700 bg-gradient-to-b from-purple-50/50 to-transparent'
                    : 'border-transparent text-gray-600 hover:text-purple-600 hover:border-purple-200'
                }`}
              >
                <span className="flex items-center gap-2">
                  <span>💬</span>
                  <span>Awaiting</span>
                  {awaitingCount > 0 && (
                    <span className="px-2 py-0.5 rounded-full bg-blue-100 text-blue-600 text-xs font-bold">
                      {awaitingCount}
                    </span>
                  )}
                </span>
              </button>
              <button
                onClick={() => setActiveTab('accepted')}
                className={`py-4 px-6 text-sm font-medium border-b-2 transition-all duration-200 whitespace-nowrap ${
                  activeTab === 'accepted'
                    ? 'border-purple-500 text-purple-700 bg-gradient-to-b from-purple-50/50 to-transparent'
                    : 'border-transparent text-gray-600 hover:text-purple-600 hover:border-purple-200'
                }`}
              >
                <span className="flex items-center gap-2">
                  <span>✅</span>
                  <span>Accepted</span>
                </span>
              </button>
              <button
                onClick={() => setActiveTab('declined')}
                className={`py-4 px-6 text-sm font-medium border-b-2 transition-all duration-200 whitespace-nowrap ${
                  activeTab === 'declined'
                    ? 'border-purple-500 text-purple-700 bg-gradient-to-b from-purple-50/50 to-transparent'
                    : 'border-transparent text-gray-600 hover:text-purple-600 hover:border-purple-200'
                }`}
              >
                <span className="flex items-center gap-2">
                  <span>❌</span>
                  <span>Declined</span>
                </span>
              </button>
              <button
                onClick={() => setActiveTab('completed')}
                className={`py-4 px-6 text-sm font-medium border-b-2 transition-all duration-200 whitespace-nowrap ${
                  activeTab === 'completed'
                    ? 'border-purple-500 text-purple-700 bg-gradient-to-b from-purple-50/50 to-transparent'
                    : 'border-transparent text-gray-600 hover:text-purple-600 hover:border-purple-200'
                }`}
              >
                <span className="flex items-center gap-2">
                  <span>🟣</span>
                  <span>Completed</span>
                </span>
              </button>
              <button
                onClick={() => setActiveTab('suggestions')}
                className={`py-4 px-6 text-sm font-medium border-b-2 transition-all duration-200 whitespace-nowrap ${
                  activeTab === 'suggestions'
                    ? 'border-purple-500 text-purple-700 bg-gradient-to-b from-purple-50/50 to-transparent'
                    : 'border-transparent text-gray-600 hover:text-purple-600 hover:border-purple-200'
                }`}
              >
                <span className="flex items-center gap-2">
                  <span>💡</span>
                  <span>Suggestions</span>
                  {suggestions.length > 0 && (
                    <span className="px-2 py-0.5 rounded-full bg-green-100 text-green-600 text-xs font-bold">
                      {suggestions.length}
                    </span>
                  )}
                </span>
              </button>
              <button
                onClick={() => setActiveTab('your-suggestions')}
                className={`py-4 px-6 text-sm font-medium border-b-2 transition-all duration-200 whitespace-nowrap ${
                  activeTab === 'your-suggestions'
                    ? 'border-purple-500 text-purple-700 bg-gradient-to-b from-purple-50/50 to-transparent'
                    : 'border-transparent text-gray-600 hover:text-purple-600 hover:border-purple-200'
                }`}
              >
                <span className="flex items-center gap-2">
                  <span>🎯</span>
                  <span>Your Suggestions</span>
                  {userSuggestions.length > 0 && (
                    <span className="px-2 py-0.5 rounded-full bg-purple-100 text-purple-600 text-xs font-bold">
                      {userSuggestions.length}
                    </span>
                  )}
                </span>
              </button>
            </nav>
          </div>
        </div>

        {/* Content */}
        {loading ? (
          <div className="flex items-center justify-center py-12">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-purple-600"></div>
          </div>
        ) : activeTab === 'your-suggestions' ? (
          // Your Suggestions Tab Content - Master-Detail Layout
          <div className="space-y-6">
            {/* Header */}
            <div className="backdrop-blur-xl bg-gradient-to-r from-purple-50/80 to-indigo-50/80 border border-purple-200/60 rounded-2xl p-6 shadow-lg">
              <div className="flex items-center justify-between">
                <div>
                  <h2 className="text-lg font-bold text-purple-800 mb-2 flex items-center gap-2">
                    <span>💡</span> Your Suggested Matches
                  </h2>
                  <p className="text-sm text-purple-700">
                    Track how your introductions are progressing! See the status of matches you've suggested between other users.
                  </p>
                </div>
                {/* Mobile sidebar toggle */}
                <button
                  onClick={() => setShowSuggestionSidebar(!showSuggestionSidebar)}
                  className="lg:hidden px-3 py-2 bg-purple-500 text-white rounded-lg hover:bg-purple-600 transition-all duration-200"
                >
                  {showSuggestionSidebar ? '✕' : '☰'}
                </button>
              </div>
            </div>

            {userSuggestions.length === 0 ? (
              <div className="backdrop-blur-xl bg-gradient-to-br from-white/80 via-purple-50/60 to-blue-50/60 rounded-2xl border border-white/60 shadow-lg p-8 text-center">
                <p className="text-gray-600">You haven't suggested any matches yet</p>
                <button
                  onClick={() => router.push('/mini/suggest')}
                  className="mt-4 px-6 py-2.5 bg-gradient-to-r from-purple-500 to-purple-600 text-white rounded-xl hover:from-purple-600 hover:to-purple-700 font-medium transition-all duration-200"
                >
                  Suggest a Match
                </button>
              </div>
            ) : (
              <div className="flex flex-col lg:flex-row gap-6 items-start">
                {/* Left Panel - Suggestion List */}
                <div className={`${showSuggestionSidebar ? 'block' : 'hidden lg:block'} w-full lg:w-80 flex-shrink-0`}>
                  <div className="backdrop-blur-lg bg-white/50 rounded-2xl border border-purple-200/40 shadow-lg overflow-hidden">
                    <div className="p-4 border-b border-purple-100">
                      <p className="text-sm font-semibold text-purple-800">
                        {userSuggestions.length} Suggestion{userSuggestions.length !== 1 ? 's' : ''}
                      </p>
                    </div>
                    <div className="overflow-y-auto max-h-[600px]">
                      {userSuggestions.map((suggestion) => {
                        const statusInfo = getUserSuggestionStatus(suggestion);
                        const isSelected = selectedUserSuggestion?.id === suggestion.id;

                        return (
                          <button
                            key={suggestion.id}
                            onClick={() => setSelectedUserSuggestion(suggestion)}
                            className={`w-full p-4 border-b border-purple-100/40 hover:bg-purple-50/40 transition-all duration-200 text-left ${
                              isSelected ? 'bg-purple-50/60 border-l-4 border-l-purple-400 shadow-md' : ''
                            }`}
                          >
                            {/* Avatars side by side */}
                            <div className="flex items-center gap-2 mb-3">
                              <Image
                                src={suggestion.userA.avatarUrl || '/default-avatar.png'}
                                alt={suggestion.userA.displayName}
                                width={32}
                                height={32}
                                className="rounded-full border border-purple-200 shadow-sm"
                              />
                              <span className="text-purple-500 text-sm">↔</span>
                              <Image
                                src={suggestion.userB.avatarUrl || '/default-avatar.png'}
                                alt={suggestion.userB.displayName}
                                width={32}
                                height={32}
                                className="rounded-full border border-purple-200 shadow-sm"
                              />
                            </div>

                            {/* Usernames */}
                            <div className="flex items-center justify-between gap-2 mb-2">
                              <div className="flex-1 min-w-0">
                                <p className="text-xs text-gray-700 truncate">{suggestion.userA.displayName} & {suggestion.userB.displayName}</p>
                                <p className="text-[10px] text-gray-500 truncate">@{suggestion.userA.username} ↔ @{suggestion.userB.username}</p>
                              </div>
                            </div>

                            {/* Status badge */}
                            <div className="flex items-center justify-between">
                              <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-medium border ${statusInfo.color}`}>
                                <span>{statusInfo.emoji}</span>
                                <span>{statusInfo.label}</span>
                              </span>
                              <span className="text-[10px] text-gray-500">
                                {new Date(suggestion.createdAt).toLocaleDateString('en-US', { month: 'short', day: 'numeric' })}
                              </span>
                            </div>
                          </button>
                        );
                      })}
                    </div>
                  </div>
                </div>

                {/* Right Panel - Detailed View */}
                <div className="flex-1 w-full min-w-0">
                  {!selectedUserSuggestion ? (
                    <div className="backdrop-blur-xl bg-gradient-to-br from-white/80 via-purple-50/60 to-blue-50/60 rounded-2xl border border-white/60 shadow-lg p-12 text-center">
                      <p className="text-gray-600">Select a suggestion to view details</p>
                    </div>
                  ) : (
                    <div className="backdrop-blur-xl bg-gradient-to-br from-white/80 via-purple-50/60 to-blue-50/60 rounded-2xl border border-white/60 shadow-lg hover:shadow-2xl transition-all duration-300 p-6">
                      <div className="flex items-start justify-between mb-4">
                        <div className="flex items-center gap-4">
                          {/* User A */}
                          <div className="flex items-center gap-3">
                            <Image
                              src={selectedUserSuggestion.userA.avatarUrl || '/default-avatar.png'}
                              alt={selectedUserSuggestion.userA.displayName}
                              width={48}
                              height={48}
                              className="rounded-full border-2 border-purple-200"
                            />
                            <div>
                              <p className="font-semibold text-gray-900">{selectedUserSuggestion.userA.displayName}</p>
                              <p className="text-sm text-gray-600">@{selectedUserSuggestion.userA.username}</p>
                            </div>
                          </div>

                          {/* Arrow */}
                          <div className="text-2xl text-purple-500">↔</div>

                          {/* User B */}
                          <div className="flex items-center gap-3">
                            <Image
                              src={selectedUserSuggestion.userB.avatarUrl || '/default-avatar.png'}
                              alt={selectedUserSuggestion.userB.displayName}
                              width={48}
                              height={48}
                              className="rounded-full border-2 border-purple-200"
                            />
                            <div>
                              <p className="font-semibold text-gray-900">{selectedUserSuggestion.userB.displayName}</p>
                              <p className="text-sm text-gray-600">@{selectedUserSuggestion.userB.username}</p>
                            </div>
                          </div>
                        </div>

                        {/* Status Badge */}
                        <span className={`inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-sm font-medium border ${getUserSuggestionStatus(selectedUserSuggestion).color}`}>
                          <span>{getUserSuggestionStatus(selectedUserSuggestion).emoji}</span>
                          <span>{getUserSuggestionStatus(selectedUserSuggestion).label}</span>
                        </span>
                      </div>

                      {/* Message */}
                      <div className="backdrop-blur-xl bg-gradient-to-r from-blue-50/80 to-indigo-50/80 border border-blue-200/60 rounded-xl p-4 mb-3">
                        <p className="text-sm font-medium text-blue-900 mb-1">Your introduction message:</p>
                        <p className="text-sm text-blue-800">&quot;{selectedUserSuggestion.message}&quot;</p>
                      </div>

                      {/* Status Details */}
                      <div className="grid grid-cols-2 gap-3 mb-3">
                        <div className={`rounded-lg p-3 border ${selectedUserSuggestion.aAccepted ? 'bg-green-50/80 border-green-200' : 'bg-gray-50/80 border-gray-200'}`}>
                          <p className="text-xs font-semibold text-gray-700 mb-1">{selectedUserSuggestion.userA.displayName}</p>
                          <p className={`text-sm font-medium ${selectedUserSuggestion.aAccepted ? 'text-green-700' : 'text-gray-600'}`}>
                            {selectedUserSuggestion.aAccepted ? '✅ Accepted' : '⏳ Pending'}
                          </p>
                        </div>
                        <div className={`rounded-lg p-3 border ${selectedUserSuggestion.bAccepted ? 'bg-green-50/80 border-green-200' : 'bg-gray-50/80 border-gray-200'}`}>
                          <p className="text-xs font-semibold text-gray-700 mb-1">{selectedUserSuggestion.userB.displayName}</p>
                          <p className={`text-sm font-medium ${selectedUserSuggestion.bAccepted ? 'text-green-700' : 'text-gray-600'}`}>
                            {selectedUserSuggestion.bAccepted ? '✅ Accepted' : '⏳ Pending'}
                          </p>
                        </div>
                      </div>

                      {/* Timestamp */}
                      <div className="flex items-center justify-between text-xs text-gray-500">
                        <span>Suggested: {new Date(selectedUserSuggestion.createdAt).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })} at {new Date(selectedUserSuggestion.createdAt).toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' })}</span>
                        {selectedUserSuggestion.status === 'accepted' && (
                          <span className="text-green-600 font-medium">🎉 Both users connected!</span>
                        )}
                      </div>
                    </div>
                  )}
                </div>
              </div>
            )}
          </div>
        ) : activeTab === 'suggestions' ? (
          // Suggestions Tab Content - Master-Detail Layout
          <div className="space-y-6">
            {/* Header */}
            <div className="backdrop-blur-xl bg-gradient-to-r from-blue-50/80 to-indigo-50/80 border border-blue-200/60 rounded-2xl p-6 shadow-lg">
              <div className="flex items-center justify-between">
                <div>
                  <h2 className="text-lg font-bold text-blue-800 mb-2 flex items-center gap-2">
                    <span>💡</span> Match Suggestions For You
                  </h2>
                  <p className="text-sm text-blue-700">
                    Others think you'd connect well with these people. Review each suggestion and decide if you'd like to meet!
                  </p>
                </div>
                {/* Mobile sidebar toggle */}
                <button
                  onClick={() => setShowIncomingSuggestionSidebar(!showIncomingSuggestionSidebar)}
                  className="lg:hidden px-3 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 transition-all duration-200"
                >
                  {showIncomingSuggestionSidebar ? '✕' : '☰'}
                </button>
              </div>
            </div>

            {suggestions.length === 0 ? (
              <div className="backdrop-blur-xl bg-gradient-to-br from-white/80 via-purple-50/60 to-blue-50/60 rounded-2xl border border-white/60 shadow-lg p-8 text-center">
                <p className="text-gray-600">💡 No match suggestions yet</p>
              </div>
            ) : (
              <div className="flex flex-col lg:flex-row gap-6 items-start">
                {/* Left Panel - Suggestion List */}
                <div className={`${showIncomingSuggestionSidebar ? 'block' : 'hidden lg:block'} w-full lg:w-80 flex-shrink-0`}>
                  <div className="backdrop-blur-lg bg-white/50 rounded-2xl border border-blue-200/40 shadow-lg overflow-hidden">
                    <div className="p-4 border-b border-blue-100">
                      <p className="text-sm font-semibold text-blue-800">
                        {suggestions.length} Suggestion{suggestions.length !== 1 ? 's' : ''}
                      </p>
                    </div>
                    <div className="overflow-y-auto max-h-[600px]">
                      {suggestions.map((suggestion) => {
                        const isSelected = selectedSuggestion?.id === suggestion.id;
                        const statusColor = suggestion.myAcceptance && suggestion.otherAcceptance
                          ? 'text-green-600'
                          : suggestion.myAcceptance
                          ? 'text-yellow-600'
                          : 'text-blue-600';

                        return (
                          <button
                            key={suggestion.id}
                            onClick={() => setSelectedSuggestion(suggestion)}
                            className={`w-full p-4 border-b border-blue-100/40 hover:bg-blue-50/40 transition-all duration-200 text-left ${
                              isSelected ? 'bg-blue-50/60 border-l-4 border-l-blue-400 shadow-md' : ''
                            }`}
                          >
                            {/* Avatar */}
                            <div className="flex items-center gap-3 mb-2">
                              <Image
                                src={suggestion.otherUser.avatarUrl || '/default-avatar.png'}
                                alt={suggestion.otherUser.displayName}
                                width={40}
                                height={40}
                                className="rounded-full border border-blue-200 shadow-sm"
                              />
                              <div className="flex-1 min-w-0">
                                <p className="text-sm font-semibold text-gray-900 truncate">
                                  {suggestion.otherUser.displayName}
                                </p>
                                <p className="text-xs text-gray-600 truncate">
                                  @{suggestion.otherUser.username}
                                </p>
                              </div>
                            </div>

                            {/* Status */}
                            <div className="flex items-center justify-between">
                              <span className={`text-[10px] font-medium ${statusColor}`}>
                                {suggestion.myAcceptance && suggestion.otherAcceptance
                                  ? '✅ Both Accepted'
                                  : suggestion.myAcceptance
                                  ? '⏳ Awaiting Response'
                                  : '💡 New Suggestion'}
                              </span>
                            </div>
                          </button>
                        );
                      })}
                    </div>
                  </div>
                </div>

                {/* Right Panel - Detailed View */}
                <div className="flex-1 w-full min-w-0">
                  {!selectedSuggestion ? (
                    <div className="backdrop-blur-xl bg-gradient-to-br from-white/80 via-purple-50/60 to-blue-50/60 rounded-2xl border border-white/60 shadow-lg p-12 text-center">
                      <p className="text-gray-600">Select a suggestion to view details</p>
                    </div>
                  ) : (
                    <div className="backdrop-blur-xl bg-gradient-to-br from-white/80 via-purple-50/60 to-blue-50/60 rounded-2xl border border-white/60 shadow-lg hover:shadow-2xl transition-all duration-300 p-6">
                      <div className="flex items-start space-x-4 mb-4">
                        <Image
                          src={selectedSuggestion.otherUser.avatarUrl || '/default-avatar.png'}
                          alt={selectedSuggestion.otherUser.displayName}
                          width={64}
                          height={64}
                          className="rounded-full border-2 border-purple-200 shadow-md"
                        />
                        <div className="flex-1">
                          <h3 className="font-bold text-gray-900 text-xl mb-1 flex items-center gap-2">
                            <span>🤝</span>
                            <span>Match suggestion with {selectedSuggestion.otherUser.displayName}</span>
                          </h3>
                          <p className="text-sm text-gray-600">
                            @{selectedSuggestion.otherUser.username}
                          </p>
                        </div>
                      </div>

                      <div className="backdrop-blur-xl bg-gradient-to-r from-blue-50/80 to-indigo-50/80 border border-blue-200/60 rounded-xl p-4 mb-4">
                        <p className="text-sm font-medium text-blue-900 mb-1">Why this match?</p>
                        <p className="text-sm text-blue-800 italic">&quot;{selectedSuggestion.message}&quot;</p>
                      </div>

                      {selectedSuggestion.status === 'proposed' && !selectedSuggestion.myAcceptance && (
                        <div className="flex gap-3 mb-4">
                          <button
                            onClick={() => handleAcceptSuggestion(selectedSuggestion.id)}
                            disabled={actionLoading}
                            className="flex-1 bg-gradient-to-r from-green-500 to-emerald-500 text-white px-5 py-3 rounded-xl hover:from-green-600 hover:to-emerald-600 disabled:from-gray-300 disabled:to-gray-400 font-semibold shadow-md hover:shadow-lg transition-all duration-200 disabled:cursor-not-allowed"
                          >
                            {actionLoading ? '⏳ Processing...' : '✅ Accept'}
                          </button>
                          <button
                            onClick={() => handleDeclineSuggestion(selectedSuggestion.id)}
                            disabled={actionLoading}
                            className="flex-1 bg-gradient-to-r from-red-500 to-rose-500 text-white px-5 py-3 rounded-xl hover:from-red-600 hover:to-rose-600 disabled:from-gray-300 disabled:to-gray-400 font-semibold shadow-md hover:shadow-lg transition-all duration-200 disabled:cursor-not-allowed"
                          >
                            {actionLoading ? '⏳ Processing...' : '❌ Decline'}
                          </button>
                        </div>
                      )}

                      {selectedSuggestion.myAcceptance && !selectedSuggestion.otherAcceptance && (
                        <div className="backdrop-blur-xl bg-gradient-to-r from-yellow-50/80 to-amber-50/80 border border-yellow-200/60 rounded-xl p-4 mb-4">
                          <p className="text-sm text-yellow-900 flex items-center gap-2">
                            <span>⏳</span>
                            <span><strong>You accepted.</strong> Waiting for {selectedSuggestion.otherUser.displayName}...</span>
                          </p>
                        </div>
                      )}

                      {selectedSuggestion.myAcceptance && selectedSuggestion.otherAcceptance && selectedSuggestion.chatRoomId && (
                        <button
                          onClick={() => router.push(`/mini/chat/${selectedSuggestion.chatRoomId}`)}
                          className="w-full px-6 py-3 bg-gradient-to-r from-purple-500 to-indigo-500 text-white rounded-xl hover:from-purple-600 hover:to-indigo-600 font-semibold shadow-md hover:shadow-lg transition-all duration-200"
                        >
                          💬 Open Chat Room
                        </button>
                      )}
                    </div>
                  )}
                </div>
              </div>
            )}
          </div>
        ) : matches.length === 0 ? (
          <div className="backdrop-blur-xl bg-gradient-to-br from-white/80 via-purple-50/60 to-blue-50/60 rounded-2xl border border-white/60 shadow-lg p-8 text-center">
            <p className="text-gray-600 mb-4">
              {activeTab === 'pending' && '🕓 No pending matches'}
              {activeTab === 'awaiting' && '💬 No matches awaiting response'}
              {activeTab === 'accepted' && '✅ No accepted matches yet'}
              {activeTab === 'declined' && '❌ No declined matches'}
              {activeTab === 'completed' && '🟣 No completed meetings yet'}
            </p>
          </div>
        ) : (
          <div className="flex flex-col lg:flex-row gap-6 items-start">
            {/* Mobile toggle button */}
            <button
              onClick={() => setShowMatchSidebar(!showMatchSidebar)}
              className="lg:hidden w-full px-4 py-3 bg-gradient-to-r from-purple-500 to-indigo-500 text-white rounded-xl hover:from-purple-600 hover:to-indigo-600 font-medium transition-all duration-200 flex items-center justify-center gap-2"
            >
              <span>{showMatchSidebar ? '✕ Hide' : '☰ Show'} Match List</span>
            </button>

            {/* Left Panel - Match List */}
            <div className={`${showMatchSidebar ? 'block' : 'hidden lg:block'} w-full lg:w-80 flex-shrink-0`}>
              <div className="backdrop-blur-lg bg-white/50 rounded-2xl border border-purple-200/40 shadow-lg overflow-hidden">
                <div className="p-4 border-b border-purple-100">
                  <p className="text-sm font-semibold text-purple-800">
                    {matches.length} Match{matches.length !== 1 ? 'es' : ''}
                  </p>
                </div>
                <div className="overflow-y-auto max-h-[600px]">
                  {matches.map((match) => {
                    const displayInfo = getMatchDisplayInfo(match);
                    if (!displayInfo) return null;
                    const isSelected = selectedMatch?.id === match.id;

                    return (
                      <button
                        key={match.id}
                        onClick={() => {
                          setSelectedMatch(match);
                          // Auto-hide sidebar on mobile after selection
                          if (window.innerWidth < 1024) {
                            setShowMatchSidebar(false);
                          }
                        }}
                        className={`w-full p-4 border-b border-purple-100/40 hover:bg-purple-50/40 transition-all duration-200 text-left ${
                          isSelected ? 'bg-purple-50/60 border-l-4 border-l-purple-400 shadow-md' : ''
                        }`}
                      >
                        {/* Avatar and name */}
                        <div className="flex items-center gap-3 mb-2">
                          <Image
                            src={displayInfo.avatar}
                            alt={displayInfo.title}
                            width={40}
                            height={40}
                            className="rounded-full border border-purple-200 shadow-sm"
                          />
                          <div className="flex-1 min-w-0">
                            <p className="text-sm font-semibold text-gray-900 truncate">
                              {displayInfo.title}
                            </p>
                            <p className="text-xs text-gray-600 truncate">
                              {displayInfo.subtitle}
                            </p>
                          </div>
                        </div>

                        {/* Status badges */}
                        <div className="flex flex-wrap gap-2 items-center">
                          <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-medium border ${getStatusBadgeColor(match.status)}`}>
                            <span>{getStatusEmoji(match.status)}</span>
                            <span>{getStatusLabel(match)}</span>
                          </span>
                          {!isTerminalStatus(match.status) && needsMyAction(match) && (
                            <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-bold bg-gradient-to-r from-red-50/90 to-rose-50/90 text-red-700 border border-red-200">
                              <span>⚠️</span>
                            </span>
                          )}
                        </div>
                      </button>
                    );
                  })}
                </div>
              </div>
            </div>

            {/* Right Panel - Match Details */}
            <div className="flex-1 w-full min-w-0">
              <div className="backdrop-blur-xl bg-gradient-to-br from-white/80 via-purple-50/60 to-blue-50/60 rounded-2xl border border-white/60 shadow-lg p-8">
              {!selectedMatch ? (
                <div className="flex items-center justify-center h-64">
                  <p className="text-gray-600 text-lg">✨ Select a match to view details</p>
                </div>
              ) : (
                <>
                  {/* Header */}
                  <div className="border-b border-purple-100 pb-5 mb-6">
                    <div className="flex items-start justify-between">
                      <div className="flex items-center space-x-4">
                        <Image
                          src={getMatchDisplayInfo(selectedMatch)?.avatar || ''}
                          alt={getMatchDisplayInfo(selectedMatch)?.title || ''}
                          width={72}
                          height={72}
                          className="rounded-full border-3 border-purple-200 shadow-lg"
                        />
                        <div>
                          <h3 className="text-2xl font-bold text-gray-900 mb-1">
                            {getMatchDisplayInfo(selectedMatch)?.title}
                          </h3>
                          <p className="text-base text-gray-600">
                            {getMatchDisplayInfo(selectedMatch)?.subtitle}
                          </p>
                        </div>
                      </div>
                      <span className={`inline-flex items-center gap-1.5 px-4 py-2 rounded-full text-sm font-medium border shadow-sm ${getStatusBadgeColor(selectedMatch.status)}`}>
                        <span>{getStatusEmoji(selectedMatch.status)}</span>
                        <span>{getStatusLabel(selectedMatch)}</span>
                      </span>
                    </div>
                  </div>

                  {/* Rationale */}
                  {selectedMatch.rationale && (
                    <div className="backdrop-blur-xl bg-gradient-to-r from-purple-50/80 to-indigo-50/80 border border-purple-200/60 rounded-xl p-5 mb-5 shadow-sm">
                      <h4 className="font-bold text-purple-900 mb-3 flex items-center gap-2">
                        <span>✨</span>
                        <span>Why you matched</span>
                      </h4>
                      <p className="text-sm text-purple-800 leading-relaxed mb-3">
                        {getRationaleMessage(selectedMatch.rationale)}
                      </p>
                      {selectedMatch.rationale.traitOverlap && selectedMatch.rationale.traitOverlap.length > 0 && (
                        <div className="flex flex-wrap gap-2">
                          {selectedMatch.rationale.traitOverlap.slice(0, 6).map((trait) => (
                            <span
                              key={trait}
                              className="px-3 py-1.5 bg-white/80 backdrop-blur-sm border border-purple-300 rounded-full text-xs font-medium text-purple-700 shadow-sm"
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
                    <div className="backdrop-blur-xl bg-gradient-to-r from-blue-50/80 to-indigo-50/80 border border-blue-200/60 rounded-xl p-5 mb-5 shadow-sm">
                      <h4 className="font-bold text-blue-900 mb-3 flex items-center gap-2">
                        <span>💬</span>
                        <span>Message from @{selectedMatch.creator_username}</span>
                      </h4>
                      <p className="text-sm text-blue-800 leading-relaxed italic">&quot;{selectedMatch.message}&quot;</p>
                    </div>
                  )}

                  {/* Action Buttons */}
                  {!isTerminalStatus(selectedMatch.status) && needsMyAction(selectedMatch) && (
                    <div className="backdrop-blur-xl bg-gradient-to-r from-yellow-50/80 to-amber-50/80 border border-yellow-200/60 rounded-xl p-5 mb-5 shadow-sm">
                      <p className="text-sm text-gray-800 mb-4 font-semibold flex items-center gap-2">
                        <span>🤝</span>
                        <span>Do you want to connect with this person?</span>
                      </p>
                      <div className="flex gap-3">
                        <button
                          onClick={() => handleRespond(selectedMatch.id, 'accept')}
                          disabled={isTerminalStatus(selectedMatch.status) || actionLoading}
                          className="flex-1 bg-gradient-to-r from-green-500 to-emerald-500 text-white px-5 py-3 rounded-xl hover:from-green-600 hover:to-emerald-600 disabled:from-gray-300 disabled:to-gray-400 font-semibold shadow-md hover:shadow-lg transition-all duration-200 disabled:cursor-not-allowed"
                        >
                          {actionLoading ? '⏳ Processing...' : '✅ Accept'}
                        </button>
                        <button
                          onClick={() => handleRespond(selectedMatch.id, 'decline')}
                          disabled={isTerminalStatus(selectedMatch.status) || actionLoading}
                          className="flex-1 bg-gradient-to-r from-red-500 to-rose-500 text-white px-5 py-3 rounded-xl hover:from-red-600 hover:to-rose-600 disabled:from-gray-300 disabled:to-gray-400 font-semibold shadow-md hover:shadow-lg transition-all duration-200 disabled:cursor-not-allowed"
                        >
                          {actionLoading ? '⏳ Processing...' : '❌ Decline'}
                        </button>
                      </div>
                    </div>
                  )}

                  {/* Chat Room Access */}
                  {(selectedMatch.status === 'accepted' || selectedMatch.status === 'completed') && (() => {
                    const chatRoomId = chatRoomMap.get(selectedMatch.id);

                    return (
                      <div className="backdrop-blur-xl bg-gradient-to-r from-green-50/80 to-emerald-50/80 border border-green-200/60 rounded-xl p-6 shadow-sm">
                        <h4 className="font-bold text-green-900 mb-3 flex items-center gap-2 text-lg">
                          <span>{selectedMatch.status === 'completed' ? '🎉' : '💬'}</span>
                          <span>{selectedMatch.status === 'completed' ? 'Meeting Completed!' : 'Chat Room Ready!'}</span>
                        </h4>
                        <p className="text-sm text-green-800 mb-4 leading-relaxed">
                          Both parties have accepted. Your chat room is ready to use!
                        </p>

                        {/* 2-Hour Rule Message */}
                        {selectedMatch.status === 'accepted' && (
                          <div className="backdrop-blur-xl bg-gradient-to-r from-blue-50/80 to-cyan-50/80 border border-blue-300/60 rounded-lg p-4 mb-4">
                            <p className="text-sm text-blue-900 leading-relaxed">
                              <span className="font-semibold">⏱️ Important:</span> The 2-hour countdown will start as soon as either person enters the chat room or sends the first message. After 2 hours, the room will auto-close (read-only).
                            </p>
                          </div>
                        )}

                        {/* Completed Message */}
                        {selectedMatch.status === 'completed' && (
                          <div className="backdrop-blur-xl bg-gradient-to-r from-purple-50/80 to-violet-50/80 border border-purple-300/60 rounded-lg p-4 mb-4">
                            <p className="text-sm text-purple-900 leading-relaxed">
                              ✅ This meeting has been marked as completed. You can still access the chat history.
                            </p>
                          </div>
                        )}

                        <div className="flex space-x-3">
                          {chatRoomId ? (
                            <button
                              onClick={() => router.push(`/mini/chat/${chatRoomId}`)}
                              className="px-8 py-3 rounded-xl font-semibold bg-gradient-to-r from-green-500 to-emerald-500 text-white hover:from-green-600 hover:to-emerald-600 shadow-md hover:shadow-lg transition-all duration-200"
                            >
                              💬 Open Chat
                            </button>
                          ) : (
                            <div className="text-sm text-gray-600 flex items-center gap-2">
                              <span className="animate-spin">⏳</span>
                              <span>Loading chat room...</span>
                            </div>
                          )}
                        </div>
                      </div>
                    );
                  })()}


                  {/* Created by system */}
                  {selectedMatch.created_by === 'system' && (
                    <div className="mt-6 text-center">
                      <p className="text-xs text-gray-500 flex items-center justify-center gap-1.5">
                        <span>🤖</span>
                        <span>This match was automatically generated by the system</span>
                      </p>
                    </div>
                  )}
                </>
              )}
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
