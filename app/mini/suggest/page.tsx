'use client';

import { Suspense, useEffect, useState } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import Link from 'next/link';
import { useFarcasterAuth } from '@/components/providers/FarcasterAuthProvider';
import { Navigation } from '@/components/shared/Navigation';
import { UserLookup, UserProfile } from '@/components/shared/UserLookup';
import { apiClient } from '@/lib/api-client';
import {
  getSuggestDraft,
  setSuggestDraft,
  clearSuggestDraft,
  type SuggestDraftUser,
} from '@/lib/suggest-draft';

function SuggestMatchContent() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const { user, isAuthenticated, loading: authLoading } = useFarcasterAuth();
  const [userA, setUserA] = useState<UserProfile | null>(null);
  const [userB, setUserB] = useState<UserProfile | null>(null);
  const [message, setMessage] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [initialized, setInitialized] = useState(false);

  // Redirect if not authenticated
  useEffect(() => {
    if (!authLoading && !isAuthenticated) {
      router.push('/');
    }
  }, [isAuthenticated, authLoading, router]);

  // Initialize from sessionStorage and URL params
  useEffect(() => {
    if (!isAuthenticated || !user || initialized) return;

    const slot = searchParams.get('slot') as 'a' | 'b' | null;
    const fidParam = searchParams.get('fid');

    // Load existing draft
    const draft = getSuggestDraft();

    // Convert draft users to UserProfile format
    if (draft.a) {
      setUserA({
        fid: draft.a.fid,
        username: draft.a.username,
        display_name: draft.a.displayName,
        avatar_url: draft.a.pfpUrl,
        bio: draft.a.bio,
      });
    }

    if (draft.b) {
      setUserB({
        fid: draft.b.fid,
        username: draft.b.username,
        display_name: draft.b.displayName,
        avatar_url: draft.b.pfpUrl,
        bio: draft.b.bio,
      });
    }

    // Handle prefill from URL
    if (fidParam) {
      const fidNum = parseInt(fidParam);
      if (!isNaN(fidNum) && fidNum !== user.fid) {
        fetchAndPrefillUser(fidNum, slot, draft);
      }
    }

    setInitialized(true);
  }, [searchParams, isAuthenticated, user, initialized]);

  const fetchAndPrefillUser = async (
    fid: number,
    slot: 'a' | 'b' | null,
    existingDraft: any
  ) => {
    try {
      const data = await apiClient.get<UserProfile>(`/api/users/${fid}`);

      const draftUser: SuggestDraftUser = {
        fid: data.fid,
        username: data.username,
        displayName: data.display_name,
        pfpUrl: data.avatar_url,
        bio: data.bio,
      };

      if (slot === 'a') {
        setUserA(data);
        setSuggestDraft({ ...existingDraft, a: draftUser });
      } else if (slot === 'b') {
        // Check if trying to set same user as A
        if (existingDraft.a?.fid === fid) {
          setError('Cannot select the same user for both positions');
          return;
        }
        setUserB(data);
        setSuggestDraft({ ...existingDraft, b: draftUser });
      } else {
        // No slot specified, use heuristic: fill A first, then B
        if (!existingDraft.a) {
          setUserA(data);
          setSuggestDraft({ ...existingDraft, a: draftUser });
        } else if (!existingDraft.b && existingDraft.a.fid !== fid) {
          setUserB(data);
          setSuggestDraft({ ...existingDraft, b: draftUser });
        }
      }
    } catch (err) {
      console.error('Error prefilling user:', err);
    }
  };

  const handleUserAChange = (newUser: UserProfile | null) => {
    setUserA(newUser);
    const draft = getSuggestDraft();

    if (newUser) {
      const draftUser: SuggestDraftUser = {
        fid: newUser.fid,
        username: newUser.username,
        displayName: newUser.display_name,
        pfpUrl: newUser.avatar_url,
        bio: newUser.bio,
      };
      setSuggestDraft({ ...draft, a: draftUser });
    } else {
      setSuggestDraft({ ...draft, a: undefined });
    }
  };

  const handleUserBChange = (newUser: UserProfile | null) => {
    setUserB(newUser);
    const draft = getSuggestDraft();

    if (newUser) {
      const draftUser: SuggestDraftUser = {
        fid: newUser.fid,
        username: newUser.username,
        displayName: newUser.display_name,
        pfpUrl: newUser.avatar_url,
        bio: newUser.bio,
      };
      setSuggestDraft({ ...draft, b: draftUser });
    } else {
      setSuggestDraft({ ...draft, b: undefined });
    }
  };

  // Validate message
  const messageError = (() => {
    if (message.length === 0) return null;
    if (message.length < 20) return `Minimum 20 characters (${message.length}/20)`;
    if (message.length > 100) return `Maximum 100 characters (${message.length}/100)`;
    return null;
  })();

  // Check if form is valid
  const isFormValid =
    userA &&
    userB &&
    userA.fid !== userB.fid &&
    message.length >= 20 &&
    message.length <= 100;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!isFormValid || !userA || !userB) return;

    // Additional validation: A ≠ B
    if (userA.fid === userB.fid) {
      setError('User A and User B must be different people');
      return;
    }

    setError(null);
    setLoading(true);

    try {
      const response = await apiClient.post('/api/matches/suggestions', {
        userAFid: userA.fid,
        userBFid: userB.fid,
        message: message.trim(),
      });

      if (response.success) {
        // Clear saved state
        clearSuggestDraft();

        // Success! Redirect to dashboard
        router.push('/dashboard?suggestion=created');
      }
    } catch (err: any) {
      console.error('Error creating suggestion:', err);
      setError(err.message || 'Failed to create match suggestion');
    } finally {
      setLoading(false);
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
        {/* Header */}
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-900 mb-2">
            Suggest a Match Between Two Users
          </h1>
          <p className="text-gray-600">
            Suggest a potential connection between two people in your network
          </p>
        </div>

        {/* How it works */}
        <div className="bg-blue-50 border border-blue-200 rounded-lg p-6 mb-6">
          <h2 className="text-lg font-semibold text-blue-900 mb-3 flex items-center">
            <svg
              className="w-5 h-5 mr-2"
              fill="currentColor"
              viewBox="0 0 20 20"
            >
              <path
                fillRule="evenodd"
                d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z"
                clipRule="evenodd"
              />
            </svg>
            How it works
          </h2>
          <p className="text-blue-800 text-sm">
            You can suggest a match between two users along with an introduction
            message. Each of them can accept or decline. If both accept, they
            will earn points and automatically receive a link to a shared chat
            room.
          </p>
        </div>

        {/* How to add users from Explore Users */}
        <div className="bg-green-50 border border-green-200 rounded-lg p-6 mb-6">
          <h2 className="text-lg font-semibold text-green-900 mb-3 flex items-center">
            <svg
              className="w-5 h-5 mr-2"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01"
              />
            </svg>
            How to add users from Explore Users
          </h2>
          <div className="text-green-800 text-sm space-y-3">
            <div>
              <p className="font-medium mb-2">Steps:</p>
              <ol className="list-decimal list-inside space-y-1.5 ml-2">
                <li>
                  Go to{' '}
                  <Link
                    href="/users"
                    className="underline hover:text-green-900 font-medium"
                  >
                    Explore Users
                  </Link>{' '}
                  and open a person's View Profile
                </li>
                <li>
                  Click <strong>+ Suggest Match</strong>:
                  <ul className="list-disc list-inside ml-5 mt-1 space-y-0.5 text-xs">
                    <li>If neither slot is filled yet, that profile becomes User A</li>
                    <li>If User A is already chosen, the next selection becomes User B</li>
                  </ul>
                </li>
                <li>
                  You'll be brought back to Suggest Match with the slot prefilled
                </li>
                <li>
                  You can click <strong>Change</strong> on a slot to return to Explore
                  Users and pick someone else
                </li>
              </ol>
            </div>
            <div className="pt-2 border-t border-green-200">
              <p className="font-medium mb-1.5">Rules:</p>
              <ul className="space-y-1 ml-2 text-xs">
                <li className="flex items-start">
                  <svg
                    className="w-4 h-4 mr-1.5 flex-shrink-0 mt-0.5"
                    fill="currentColor"
                    viewBox="0 0 20 20"
                  >
                    <path
                      fillRule="evenodd"
                      d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
                      clipRule="evenodd"
                    />
                  </svg>
                  User A and User B must be different FIDs
                </li>
                <li className="flex items-start">
                  <svg
                    className="w-4 h-4 mr-1.5 flex-shrink-0 mt-0.5"
                    fill="currentColor"
                    viewBox="0 0 20 20"
                  >
                    <path
                      fillRule="evenodd"
                      d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
                      clipRule="evenodd"
                    />
                  </svg>
                  Once a user is selected as User A, the Suggest Match button on that
                  same profile will be disabled
                </li>
                <li className="flex items-start">
                  <svg
                    className="w-4 h-4 mr-1.5 flex-shrink-0 mt-0.5"
                    fill="currentColor"
                    viewBox="0 0 20 20"
                  >
                    <path
                      fillRule="evenodd"
                      d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
                      clipRule="evenodd"
                    />
                  </svg>
                  Manual entry is allowed via <strong>Manual USER ID (FID)</strong> with
                  live validation
                </li>
              </ul>
            </div>
          </div>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit} className="bg-white rounded-lg shadow p-6">
          {/* User A FID */}
          <UserLookup
            label="User A FID"
            value={userA}
            onChange={handleUserAChange}
            currentUserFid={user.fid}
            excludeFid={userB?.fid}
            slot="a"
          />

          {/* User B FID */}
          <UserLookup
            label="User B FID"
            value={userB}
            onChange={handleUserBChange}
            currentUserFid={user.fid}
            excludeFid={userA?.fid}
            slot="b"
          />

          {/* A ≠ B Validation Warning */}
          {userA && userB && userA.fid === userB.fid && (
            <div className="mb-6 p-4 bg-red-50 border border-red-200 rounded-md">
              <div className="flex items-start gap-2">
                <svg
                  className="w-5 h-5 text-red-600 flex-shrink-0 mt-0.5"
                  fill="currentColor"
                  viewBox="0 0 20 20"
                >
                  <path
                    fillRule="evenodd"
                    d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z"
                    clipRule="evenodd"
                  />
                </svg>
                <p className="text-sm text-red-800">
                  User A and User B must be different people. Please select different users.
                </p>
              </div>
            </div>
          )}

          {/* Message */}
          <div className="mb-6">
            <label
              htmlFor="message"
              className="block text-sm font-medium text-gray-700 mb-2"
            >
              Why are you suggesting this match between these two users?{' '}
              <span className="text-red-600">*</span>
            </label>
            <textarea
              id="message"
              value={message}
              onChange={(e) => setMessage(e.target.value)}
              placeholder="Explain why you think these two people should connect..."
              required
              rows={5}
              maxLength={100}
              className={`w-full px-4 py-2 border rounded-md focus:ring-2 focus:ring-purple-500 focus:border-transparent resize-none text-gray-900 placeholder:text-gray-400 ${
                message.length > 0 && messageError
                  ? 'border-red-300 focus:ring-red-500'
                  : 'border-gray-300'
              }`}
            />
            <div className="mt-2 flex items-center justify-between">
              <div>
                {message.length > 0 && messageError ? (
                  <p className="text-sm text-red-600">{messageError}</p>
                ) : message.length >= 20 ? (
                  <p className="text-sm text-green-600 flex items-center gap-1">
                    <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                      <path
                        fillRule="evenodd"
                        d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
                        clipRule="evenodd"
                      />
                    </svg>
                    Message looks good
                  </p>
                ) : (
                  <p className="text-sm text-gray-500">Required: 20-100 characters</p>
                )}
              </div>
              <p
                className={`text-sm font-medium ${
                  message.length > 100 ? 'text-red-600' : 'text-gray-500'
                }`}
              >
                {message.length}/100
              </p>
            </div>
          </div>

          {/* Error Display */}
          {error && (
            <div className="mb-6 p-4 bg-red-50 border border-red-200 rounded-md">
              <div className="flex items-start gap-2">
                <svg
                  className="w-5 h-5 text-red-600 flex-shrink-0 mt-0.5"
                  fill="currentColor"
                  viewBox="0 0 20 20"
                >
                  <path
                    fillRule="evenodd"
                    d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z"
                    clipRule="evenodd"
                  />
                </svg>
                <p className="text-sm text-red-800">{error}</p>
              </div>
            </div>
          )}

          {/* What happens next */}
          <div className="bg-gray-50 border border-gray-200 rounded-lg p-4 mb-6">
            <h3 className="text-sm font-semibold text-gray-900 mb-2">
              What happens next:
            </h3>
            <ul className="text-sm text-gray-700 space-y-1 list-disc list-inside">
              <li>
                Both users will receive your match suggestion and message in their
                inbox
              </li>
              <li>Each of them can accept or decline the suggestion</li>
              <li>
                If accepted: Both users will earn points and receive an automatic
                chat room link
              </li>
              <li>If declined: You'll be notified (7-day cooldown applies)</li>
            </ul>
          </div>

          {/* Validation Summary */}
          {!isFormValid && (userA || userB || message.length > 0) && (
            <div className="mb-6 bg-gray-50 border border-gray-200 rounded-md p-3">
              <p className="text-sm font-medium text-gray-700 mb-2">
                To submit suggestion:
              </p>
              <ul className="text-sm text-gray-600 space-y-1">
                <li className={userA ? 'text-green-600 flex items-center gap-1' : 'flex items-center gap-1'}>
                  {userA ? (
                    <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                      <path
                        fillRule="evenodd"
                        d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
                        clipRule="evenodd"
                      />
                    </svg>
                  ) : (
                    '○'
                  )}{' '}
                  Select User A
                </li>
                <li className={userB ? 'text-green-600 flex items-center gap-1' : 'flex items-center gap-1'}>
                  {userB ? (
                    <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                      <path
                        fillRule="evenodd"
                        d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
                        clipRule="evenodd"
                      />
                    </svg>
                  ) : (
                    '○'
                  )}{' '}
                  Select User B
                </li>
                <li
                  className={
                    userA && userB && userA.fid !== userB.fid
                      ? 'text-green-600 flex items-center gap-1'
                      : 'flex items-center gap-1'
                  }
                >
                  {userA && userB && userA.fid !== userB.fid ? (
                    <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                      <path
                        fillRule="evenodd"
                        d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
                        clipRule="evenodd"
                      />
                    </svg>
                  ) : (
                    '○'
                  )}{' '}
                  User A and User B must be different
                </li>
                <li
                  className={
                    message.length >= 20 && message.length <= 100
                      ? 'text-green-600 flex items-center gap-1'
                      : 'flex items-center gap-1'
                  }
                >
                  {message.length >= 20 && message.length <= 100 ? (
                    <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                      <path
                        fillRule="evenodd"
                        d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
                        clipRule="evenodd"
                      />
                    </svg>
                  ) : (
                    '○'
                  )}{' '}
                  Write introduction message (20-100 chars)
                </li>
              </ul>
            </div>
          )}

          {/* Buttons */}
          <div className="flex items-center gap-4">
            <button
              type="button"
              onClick={() => router.back()}
              className="px-6 py-2 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50 transition-colors font-medium"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={loading || !isFormValid}
              aria-disabled={loading || !isFormValid}
              className="flex-1 px-6 py-2 bg-purple-600 text-white rounded-md hover:bg-purple-700 disabled:bg-gray-300 disabled:cursor-not-allowed transition-colors font-medium"
            >
              {loading ? 'Creating Suggestion...' : 'Create Match Suggestion'}
            </button>
          </div>
        </form>

        {/* Privacy Notice */}
        <div className="mt-6 p-4 bg-yellow-50 border border-yellow-200 rounded-lg">
          <p className="text-sm text-yellow-800">
            <strong>Privacy Notice:</strong> Your identity as the suggester will be
            kept private. The participants will only see your message, not your name
            or FID.
          </p>
        </div>
      </div>
    </div>
  );
}

export default function SuggestMatchPage() {
  return (
    <Suspense
      fallback={
        <div className="min-h-screen bg-gray-50 flex items-center justify-center">
          <div className="text-center">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-purple-600 mx-auto mb-4"></div>
            <p className="text-gray-600">Loading...</p>
          </div>
        </div>
      }
    >
      <SuggestMatchContent />
    </Suspense>
  );
}
