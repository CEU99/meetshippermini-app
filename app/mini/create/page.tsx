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
  const [manualModeActive, setManualModeActive] = useState(false); // Track if user switched to manual mode

  useEffect(() => {
    if (!authLoading && !isAuthenticated) {
      router.push('/');
    }
  }, [isAuthenticated, authLoading, router]);

  // Auto-fill FID from URL parameter (e.g., /mini/create?targetFid=1234567)
  useEffect(() => {
    const targetFid = searchParams.get('targetFid');

    // Only auto-fill if:
    // 1. targetFid exists in URL
    // 2. User is authenticated
    // 3. No user currently loaded
    // 4. User hasn't manually switched to manual mode
    if (targetFid && isAuthenticated && user && !targetUser && !manualModeActive) {
      console.log('[CreateMatch] Auto-filling FID from URL:', targetFid);
      setUserInput(targetFid);

      // Automatically lookup the user
      autoLookupUser(targetFid);
    }
  }, [searchParams, isAuthenticated, user, targetUser, manualModeActive]);

  // Auto-lookup user when FID is provided via URL
  const autoLookupUser = async (fid: string) => {
    if (!fid.trim()) return;

    setLookingUpUser(true);
    setError('');

    try {
      const fidNum = parseInt(fid);

      // Check if trying to match with themselves
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

  // Validate introduction message
  const messageError = (() => {
    if (message.length === 0) return 'Introduction message is required';
    if (message.length < 20) return `Minimum 20 characters (${message.length}/20)`;
    if (message.length > 100) return `Maximum 100 characters (${message.length}/100)`;
    return null;
  })();

  // Check if form is valid
  const isFormValid = targetUser && message.length >= 20 && message.length <= 100;

  // Look up user by FID or User Code
  const lookupUser = async () => {
    if (!userInput.trim()) {
      setError('Please enter a User ID (FID)');
      return;
    }

    setLookingUpUser(true);
    setError('');
    setTargetUser(null);

    try {
      // Try to parse as FID (number)
      const fidMatch = userInput.match(/^\d+$/);
      if (fidMatch) {
        const fid = parseInt(userInput);

        // Check if trying to match with themselves
        if (user && fid === user.fid) {
          setError('You cannot create a match with yourself');
          setLookingUpUser(false);
          return;
        }

        const data = await apiClient.get<UserProfile>(`/api/users/${fid}`);
        setTargetUser(data);
      } else {
        // Try as User Code
        const data = await apiClient.get<{ user: UserProfile }>(`/api/users/by-code/${userInput.trim()}`);

        // Check if trying to match with themselves
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

      // Reset form
      setUserInput('');
      setTargetUser(null);
      setMessage('');

      // Redirect to inbox after 2 seconds
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
      <div className="min-h-screen flex items-center justify-center">
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
        <div className="bg-white rounded-lg shadow-md p-6">
          <h1 className="text-3xl font-bold text-gray-900 mb-2 text-center">
            Create a Match Request
          </h1>
          <p className="text-gray-600 mb-2">
            Request to connect with someone on the platform by entering their User ID.
          </p>
          <div className="bg-blue-50 border border-blue-200 rounded-md p-3 mb-6">
            <p className="text-sm text-blue-800">
              <strong>How it works:</strong> You send a match request with an introduction message.
              The other person can accept or decline. If accepted, you&apos;ll both receive a meeting link.
            </p>
          </div>

          {error && (
            <div className="mb-6 bg-red-50 border border-red-200 rounded-md p-4">
              <p className="text-red-800">{error}</p>
            </div>
          )}

          {success && (
            <div className="mb-6 bg-green-50 border border-green-200 rounded-md p-4">
              <p className="text-green-800">
                Match request sent successfully! The other person will be notified. Redirecting to inbox...
              </p>
            </div>
          )}

          <form onSubmit={handleSubmit}>
            {/* User Lookup */}
            <div className="mb-6">
              <label className="block text-sm font-medium text-gray-700 mb-2">
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
                      className="flex-1 px-4 py-2 border border-gray-300 rounded-md focus:ring-purple-500 focus:border-purple-500 text-gray-900"
                      disabled={lookingUpUser}
                    />
                    <button
                      type="button"
                      onClick={lookupUser}
                      disabled={lookingUpUser || !userInput.trim()}
                      className="px-6 py-2 bg-purple-600 text-white rounded-md hover:bg-purple-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-purple-500 disabled:bg-gray-300 disabled:cursor-not-allowed font-medium"
                    >
                      {lookingUpUser ? 'Looking up...' : 'Lookup'}
                    </button>
                  </div>

                  {/* Find User button - Navigate to Users */}
                  <button
                    type="button"
                    onClick={() => router.push('/users')}
                    className="w-full px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 font-medium text-sm transition-colors flex items-center justify-center gap-2"
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

                  <p className="text-sm text-gray-500">
                    Enter a Farcaster ID (FID) like &quot;12345&quot; or browse users
                  </p>
                </div>
              ) : (
                <div className="space-y-3">
                  <div className="flex items-center justify-between p-4 border-2 border-purple-200 rounded-md bg-purple-50">
                    <div className="flex items-center space-x-3">
                      <Avatar
                        src={targetUser.avatar_url}
                        alt={targetUser.display_name || targetUser.username}
                        size={48}
                      />
                      <div>
                        <p className="font-medium text-gray-900">
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
                      className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 font-medium text-sm"
                    >
                      Change
                    </button>
                  </div>

                  {/* Manual FID Entry Button */}
                  <button
                    type="button"
                    onClick={() => {
                      console.log('[CreateMatch] Switching to manual mode');
                      setManualModeActive(true);  // Prevent auto-fill from running again
                      setTargetUser(null);
                      setUserInput('');
                    }}
                    className="w-full px-4 py-2 border-2 border-gray-300 rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-purple-500 font-medium text-sm flex items-center justify-center"
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
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Introduction Message <span className="text-red-600">*</span>
              </label>
              <textarea
                value={message}
                onChange={(e) => setMessage(e.target.value)}
                rows={4}
                placeholder="Tell them why you'd like to connect... (20-100 characters required)"
                className={`w-full px-4 py-2 border rounded-md focus:ring-purple-500 focus:border-purple-500 text-gray-900 ${
                  message.length > 0 && messageError
                    ? 'border-red-300 focus:ring-red-500 focus:border-red-500'
                    : 'border-gray-300'
                }`}
                maxLength={100}
              />
              <div className="mt-2 flex items-center justify-between">
                <div>
                  {message.length > 0 && messageError ? (
                    <p className="text-sm text-red-600">{messageError}</p>
                  ) : message.length >= 20 ? (
                    <p className="text-sm text-green-600">✓ Message looks good</p>
                  ) : (
                    <p className="text-sm text-gray-500">
                      Required: 20-100 characters
                    </p>
                  )}
                </div>
                <p className={`text-sm ${message.length > 100 ? 'text-red-600' : 'text-gray-500'}`}>
                  {message.length}/100
                </p>
              </div>
            </div>

            {/* Info Box */}
            <div className="mb-6 bg-yellow-50 border border-yellow-200 rounded-md p-4">
              <h3 className="text-sm font-semibold text-yellow-800 mb-2">What happens next?</h3>
              <ul className="text-sm text-yellow-800 space-y-1">
                <li>• {targetUser ? targetUser.display_name || targetUser.username : 'The other person'} will receive your match request in their inbox</li>
                <li>• They can accept or decline your request</li>
                <li>• If accepted: You&apos;ll both get a meeting link automatically</li>
                <li>• If declined: You&apos;ll be notified (7-day cooldown applies)</li>
              </ul>
            </div>

            {/* Submit Button */}
            <div className="flex space-x-4">
              <button
                type="submit"
                disabled={submitting || !isFormValid}
                className="flex-1 bg-purple-600 text-white px-6 py-3 rounded-md hover:bg-purple-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-purple-500 disabled:bg-gray-300 disabled:cursor-not-allowed font-medium"
              >
                {submitting ? 'Sending Request...' : 'Send Match Request'}
              </button>
              <button
                type="button"
                onClick={() => router.push('/dashboard')}
                className="px-6 py-3 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-purple-500 font-medium"
              >
                Cancel
              </button>
            </div>

            {/* Validation Summary */}
            {!isFormValid && (targetUser || message.length > 0) && (
              <div className="mt-4 bg-gray-50 border border-gray-200 rounded-md p-3">
                <p className="text-sm font-medium text-gray-700 mb-2">To send request:</p>
                <ul className="text-sm text-gray-600 space-y-1">
                  <li className={targetUser ? 'text-green-600' : ''}>
                    {targetUser ? '✓' : '○'} Find a user to match with
                  </li>
                  <li className={message.length >= 20 && message.length <= 100 ? 'text-green-600' : ''}>
                    {message.length >= 20 && message.length <= 100 ? '✓' : '○'} Write introduction message (20-100 chars)
                  </li>
                </ul>
              </div>
            )}
          </form>
        </div>
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
