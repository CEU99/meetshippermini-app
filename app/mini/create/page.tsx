'use client';

import { Suspense, useEffect, useState } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { useFarcasterAuth } from '@/components/providers/FarcasterAuthProvider';
import { Navigation } from '@/components/shared/Navigation';
import { apiClient } from '@/lib/api-client';
import { Avatar } from '@/components/shared/Avatar';

interface UserProfile {
  fid: number;
  username: string;
  display_name?: string;
  avatar_url?: string;
  bio?: string;
  user_code?: string;
}

interface MatchStats {
  total: number;
}

function CreateMatchContent() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const { user, isAuthenticated, loading: authLoading } = useFarcasterAuth();

  // Form state
  const [userInput, setUserInput] = useState('');
  const [targetUser, setTargetUser] = useState<UserProfile | null>(null);
  const [message, setMessage] = useState('');
  const [lookingUpUser, setLookingUpUser] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState(false);
  const [manualModeActive, setManualModeActive] = useState(false);
  const [weeklyMatches, setWeeklyMatches] = useState(0);

  useEffect(() => {
    if (!authLoading && !isAuthenticated) {
      router.push('/');
    }
  }, [isAuthenticated, authLoading, router]);

  // Fetch weekly match stats
  useEffect(() => {
    const fetchWeeklyStats = async () => {
      try {
        const data = await apiClient.get<{ matches: Array<{ created_at: string }> }>('/api/matches');

        // Count matches created in the last 7 days
        const oneWeekAgo = new Date();
        oneWeekAgo.setDate(oneWeekAgo.getDate() - 7);

        const recentMatches = data.matches.filter((m) =>
          new Date(m.created_at) > oneWeekAgo
        );

        setWeeklyMatches(recentMatches.length);
      } catch (error) {
        console.error('Error fetching weekly stats:', error);
      }
    };

    if (isAuthenticated) {
      fetchWeeklyStats();
    }
  }, [isAuthenticated]);

  // Auto-fill FID from URL parameter
  useEffect(() => {
    const targetFid = searchParams.get('targetFid');

    if (targetFid && isAuthenticated && user && !targetUser && !manualModeActive) {
      console.log('[CreateMatch] Auto-filling FID from URL:', targetFid);
      setUserInput(targetFid);
      autoLookupUser(targetFid);
    }
  }, [searchParams, isAuthenticated, user, targetUser, manualModeActive]);

  const autoLookupUser = async (fid: string) => {
    if (!fid.trim()) return;

    setLookingUpUser(true);
    setError('');

    try {
      const fidNum = parseInt(fid);

      if (user && fidNum === user.fid) {
        setError('You cannot create a match with yourself');
        setLookingUpUser(false);
        return;
      }

      console.log('[CreateMatch] Auto-looking up user with FID:', fidNum);
      const data = await apiClient.get<UserProfile>(`/api/users/${fidNum}`);
      setTargetUser(data);
      console.log('[CreateMatch] ✅ User found:', data.username);
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      console.error('[CreateMatch] Auto-lookup failed:', error);
      setError(errorMessage || 'User not found. Please check the FID and try again.');
    } finally {
      setLookingUpUser(false);
    }
  };

  const messageError = (() => {
    if (message.length === 0) return 'Introduction message is required';
    if (message.length < 20) return `Minimum 20 characters (${message.length}/20)`;
    if (message.length > 100) return `Maximum 100 characters (${message.length}/100)`;
    return null;
  })();

  const isFormValid = targetUser && message.length >= 20 && message.length <= 100;

  const lookupUser = async () => {
    if (!userInput.trim()) {
      setError('Please enter a User ID (FID)');
      return;
    }

    setLookingUpUser(true);
    setError('');
    setTargetUser(null);

    try {
      const fidMatch = userInput.match(/^\d+$/);
      if (fidMatch) {
        const fid = parseInt(userInput);

        if (user && fid === user.fid) {
          setError('You cannot create a match with yourself');
          setLookingUpUser(false);
          return;
        }

        const data = await apiClient.get<UserProfile>(`/api/users/${fid}`);
        setTargetUser(data);
      } else {
        const data = await apiClient.get<{ user: UserProfile }>(`/api/users/by-code/${userInput.trim()}`);

        if (user && data.user.fid === user.fid) {
          setError('You cannot create a match with yourself');
          setLookingUpUser(false);
          return;
        }

        setTargetUser(data.user);
      }
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      console.error('Error looking up user:', error);
      setError(errorMessage || 'User not found. Please check the FID and try again.');
    } finally {
      setLookingUpUser(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!isFormValid || !targetUser || !user) {
      return;
    }

    setError('');
    setSuccess(false);
    setSubmitting(true);

    try {
      await apiClient.post('/api/matches/manual', {
        targetFid: targetUser.fid,
        introductionMessage: message.trim(),
      });

      setSuccess(true);

      setUserInput('');
      setTargetUser(null);
      setMessage('');

      setTimeout(() => {
        router.push('/mini/inbox');
      }, 2000);
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      console.error('Error creating match:', error);
      setError(errorMessage || 'Failed to create match. Please try again.');
    } finally {
      setSubmitting(false);
    }
  };

  if (authLoading || !user) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-purple-600 mx-auto"></div>
          <p className="mt-4 text-gray-600">Loading...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <Navigation />

      <div className="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Main Form Container */}
        <div className="backdrop-blur-xl bg-gradient-to-br from-white/80 via-purple-50/60 to-blue-50/60 rounded-2xl border border-white/60 shadow-lg hover:shadow-2xl transition-all duration-300 p-8">
          {/* Title Bar */}
          <div className="text-center mb-8">
            <h1 className="text-2xl font-bold bg-gradient-to-r from-purple-700 to-blue-700 bg-clip-text text-transparent flex items-center justify-center gap-2 mb-2">
              <span>💌</span> Create a Match Request
            </h1>
            <p className="text-sm text-gray-600">
              Request to connect with someone on the platform by entering their User ID
            </p>
          </div>

          {/* Info Banner */}
          <div className="backdrop-blur-xl bg-gradient-to-r from-blue-50/80 to-indigo-50/80 border border-blue-200/60 rounded-xl p-4 mb-6">
            <p className="text-sm text-blue-800">
              <strong className="font-semibold">How it works:</strong> You send a match request with an introduction message.
              The other person can accept or decline. If accepted, you&apos;ll both receive a meeting link.
            </p>
          </div>

          {error && (
            <div className="mb-6 backdrop-blur-xl bg-gradient-to-r from-red-50/80 to-pink-50/80 border border-red-200/60 rounded-xl p-4">
              <p className="text-red-800 text-sm font-medium">{error}</p>
            </div>
          )}

          {success && (
            <div className="mb-6 backdrop-blur-xl bg-gradient-to-r from-emerald-50/80 to-green-50/80 border border-emerald-200/60 rounded-xl p-4">
              <p className="text-emerald-800 text-sm font-medium">
                Match request sent successfully! The other person will be notified. Redirecting to inbox...
              </p>
            </div>
          )}

          <form onSubmit={handleSubmit}>
            {/* User Lookup */}
            <div className="mb-6">
              <label className="block text-sm font-semibold text-gray-700 mb-3">
                Enter User ID (FID) <span className="text-red-600">*</span>
              </label>

              {!targetUser ? (
                <div className="space-y-3">
                  <div className="flex gap-2">
                    <input
                      type="text"
                      value={userInput}
                      onChange={(e) => setUserInput(e.target.value)}
                      onKeyDown={(e) => {
                        if (e.key === 'Enter') {
                          e.preventDefault();
                          lookupUser();
                        }
                      }}
                      placeholder="e.g., 12345"
                      className="flex-1 px-4 py-2.5 bg-white/70 backdrop-blur-sm border border-purple-200/60 rounded-xl focus:ring-2 focus:ring-purple-400 focus:border-purple-400 text-gray-900 transition-all duration-200 hover:border-purple-300"
                      disabled={lookingUpUser}
                    />
                    <button
                      type="button"
                      onClick={lookupUser}
                      disabled={lookingUpUser || !userInput.trim()}
                      className="px-6 py-2.5 bg-gradient-to-r from-purple-500 to-purple-600 text-white rounded-xl hover:from-purple-600 hover:to-purple-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-purple-500 disabled:from-gray-300 disabled:to-gray-400 disabled:cursor-not-allowed font-semibold shadow-sm hover:shadow-md transition-all duration-200"
                    >
                      {lookingUpUser ? 'Looking up...' : 'Lookup'}
                    </button>
                  </div>

                  <button
                    type="button"
                    onClick={() => router.push('/users')}
                    className="w-full px-4 py-2.5 bg-gradient-to-r from-blue-500 to-indigo-500 text-white rounded-xl hover:from-blue-600 hover:to-indigo-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 font-semibold text-sm transition-all duration-200 flex items-center justify-center gap-2 shadow-sm hover:shadow-md"
                  >
                    <svg
                      className="w-4 h-4"
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        strokeWidth={2}
                        d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
                      />
                    </svg>
                    Find User
                  </button>

                  <p className="text-xs text-gray-500 text-center">
                    Enter a Farcaster ID (FID) like &quot;12345&quot; or browse users
                  </p>
                </div>
              ) : (
                <div className="space-y-3">
                  <div className="flex items-center justify-between p-4 border-2 border-purple-300/60 rounded-xl bg-gradient-to-r from-purple-50/80 to-violet-50/80 backdrop-blur-sm">
                    <div className="flex items-center space-x-3">
                      <Avatar
                        src={targetUser.avatar_url}
                        alt={targetUser.display_name || targetUser.username}
                        size={48}
                      />
                      <div>
                        <p className="font-semibold text-gray-900">
                          {targetUser.display_name || targetUser.username}
                        </p>
                        <p className="text-sm text-gray-600">@{targetUser.username}</p>
                        {targetUser.bio && (
                          <p className="text-xs text-gray-500 mt-1 line-clamp-2 max-w-md">
                            {targetUser.bio}
                          </p>
                        )}
                      </div>
                    </div>
                    <button
                      type="button"
                      onClick={() => router.push('/users')}
                      className="px-4 py-2 bg-gradient-to-r from-blue-500 to-indigo-500 text-white rounded-xl hover:from-blue-600 hover:to-indigo-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 font-semibold text-sm shadow-sm hover:shadow-md transition-all duration-200"
                    >
                      Change
                    </button>
                  </div>

                  <button
                    type="button"
                    onClick={() => {
                      console.log('[CreateMatch] Switching to manual mode');
                      setManualModeActive(true);
                      setTargetUser(null);
                      setUserInput('');
                    }}
                    className="w-full px-4 py-2 border-2 border-gray-300/60 rounded-xl text-gray-700 bg-white/70 backdrop-blur-sm hover:bg-white hover:border-purple-300 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-purple-500 font-medium text-sm flex items-center justify-center transition-all duration-200"
                  >
                    <svg
                      className="w-4 h-4 mr-2"
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        strokeWidth={2}
                        d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"
                      />
                    </svg>
                    Manual USER ID (FID)
                  </button>
                </div>
              )}
            </div>

            {/* Introduction Message */}
            <div className="mb-6">
              <label className="block text-sm font-semibold text-gray-700 mb-3">
                Introduction Message <span className="text-red-600">*</span>
              </label>
              <textarea
                value={message}
                onChange={(e) => setMessage(e.target.value)}
                rows={4}
                placeholder="Tell them why you'd like to connect... (20-100 characters required)"
                className={`w-full px-4 py-3 bg-white/70 backdrop-blur-sm border rounded-xl focus:ring-2 text-gray-900 transition-all duration-200 ${
                  message.length > 0 && messageError
                    ? 'border-red-300 focus:ring-red-400 focus:border-red-400'
                    : 'border-purple-200/60 focus:ring-purple-400 focus:border-purple-400 hover:border-purple-300'
                }`}
                maxLength={100}
              />
              <div className="mt-2 flex items-center justify-between">
                <div>
                  {message.length > 0 && messageError ? (
                    <p className="text-xs text-red-600 font-medium">{messageError}</p>
                  ) : message.length >= 20 ? (
                    <p className="text-xs text-emerald-600 font-medium">✓ Message looks good</p>
                  ) : (
                    <p className="text-xs text-gray-500">
                      Required: 20-100 characters
                    </p>
                  )}
                </div>
                <p className={`text-xs font-medium ${message.length > 100 ? 'text-red-600' : 'text-gray-500'}`}>
                  {message.length}/100
                </p>
              </div>
            </div>

            {/* What Happens Next Box */}
            <div className="mb-6 backdrop-blur-xl bg-gradient-to-br from-purple-50/80 via-blue-50/80 to-indigo-50/80 border border-purple-200/60 rounded-xl p-5">
              <h3 className="text-sm font-bold text-purple-800 mb-3 flex items-center gap-2">
                <span>💡</span> What happens next?
              </h3>
              <ul className="text-sm text-purple-800 space-y-2">
                <li className="flex items-start gap-2">
                  <span className="flex-shrink-0">📨</span>
                  <span>{targetUser ? targetUser.display_name || targetUser.username : 'The other person'} will receive your match request in their inbox</span>
                </li>
                <li className="flex items-start gap-2">
                  <span className="flex-shrink-0">✅</span>
                  <span>They can accept or decline your request</span>
                </li>
                <li className="flex items-start gap-2">
                  <span className="flex-shrink-0">🔗</span>
                  <span>If accepted: You&apos;ll both get a meeting link automatically</span>
                </li>
                <li className="flex items-start gap-2">
                  <span className="flex-shrink-0">⏳</span>
                  <span>If declined: You&apos;ll be notified (7-day cooldown applies)</span>
                </li>
              </ul>
            </div>

            {/* Action Buttons */}
            <div className="flex space-x-3">
              <button
                type="submit"
                disabled={submitting || !isFormValid}
                className="flex-1 bg-gradient-to-r from-purple-600 to-blue-600 text-white px-6 py-3 rounded-xl hover:from-purple-700 hover:to-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-purple-500 disabled:from-gray-300 disabled:to-gray-400 disabled:cursor-not-allowed font-semibold shadow-md hover:shadow-lg transition-all duration-200"
              >
                {submitting ? 'Sending Request...' : 'Send Match Request'}
              </button>
              <button
                type="button"
                onClick={() => router.push('/dashboard')}
                className="px-6 py-3 border-2 border-gray-300/60 rounded-xl text-gray-700 bg-white/70 backdrop-blur-sm hover:bg-white hover:border-gray-400 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-gray-400 font-medium transition-all duration-200"
              >
                Cancel
              </button>
            </div>

            {/* Validation Summary */}
            {!isFormValid && (targetUser || message.length > 0) && (
              <div className="mt-4 backdrop-blur-xl bg-gradient-to-r from-gray-50/80 to-slate-50/80 border border-gray-200/60 rounded-xl p-4">
                <p className="text-xs font-bold text-gray-700 mb-2 uppercase tracking-wide">To send request:</p>
                <ul className="text-xs text-gray-600 space-y-1.5">
                  <li className={`flex items-center gap-2 ${targetUser ? 'text-emerald-600 font-medium' : ''}`}>
                    <span className="flex-shrink-0">{targetUser ? '✓' : '○'}</span>
                    <span>Find a user to match with</span>
                  </li>
                  <li className={`flex items-center gap-2 ${message.length >= 20 && message.length <= 100 ? 'text-emerald-600 font-medium' : ''}`}>
                    <span className="flex-shrink-0">{message.length >= 20 && message.length <= 100 ? '✓' : '○'}</span>
                    <span>Write introduction message (20-100 chars)</span>
                  </li>
                </ul>
              </div>
            )}
          </form>
        </div>

        {/* Progress Hint Bar */}
        {weeklyMatches > 0 && (
          <div className="mt-6 backdrop-blur-xl bg-gradient-to-r from-green-50/80 to-emerald-50/80 border border-green-200/60 rounded-xl p-4">
            <p className="text-sm text-center text-green-700 font-medium">
              🎉 You've created <span className="font-bold text-green-800">{weeklyMatches}</span> match{weeklyMatches === 1 ? '' : 'es'} this week — keep connecting!
            </p>
          </div>
        )}
      </div>
    </div>
  );
}

export default function CreateMatch() {
  return (
    <Suspense fallback={
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-purple-600 mx-auto mb-4"></div>
          <p className="text-gray-600">Loading...</p>
        </div>
      </div>
    }>
      <CreateMatchContent />
    </Suspense>
  );
}
