'use client';

import { Suspense, useEffect, useState } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import Link from 'next/link';
import toast, { Toaster } from 'react-hot-toast';
import { useFarcasterAuth } from '@/components/providers/FarcasterAuthProvider';
import { Navigation } from '@/components/shared/Navigation';
import { UserLookup, UserProfile } from '@/components/shared/UserLookup';
import { apiClient } from '@/lib/api-client';
import { CooldownCard } from '@/components/shared/CooldownCard';
import {
  CooldownInfo,
  extractCooldownInfo,
  formatCooldownMessage,
} from '@/lib/utils/cooldown';
import {
  getSuggestDraft,
  setSuggestDraft,
  clearSuggestDraft,
  setDraftFarcasterUserA,
  setDraftFarcasterUserB,
  type SuggestDraftUser,
} from '@/lib/suggest-draft';

function SuggestMatchContent() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const { user, isAuthenticated, loading: authLoading } = useFarcasterAuth();
  const [userA, setUserA] = useState<UserProfile | null>(null);
  const [userB, setUserB] = useState<UserProfile | null>(null);
  const [farcasterUserA, setFarcasterUserA] = useState<UserProfile | null>(null);
  const [farcasterUserB, setFarcasterUserB] = useState<UserProfile | null>(null);
  const [message, setMessage] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [cooldownInfo, setCooldownInfo] = useState<CooldownInfo | null>(null);
  const [initialized, setInitialized] = useState(false);

  // Matching mode state
  const [matchWithMeetShipper, setMatchWithMeetShipper] = useState(false);
  const [matchWithFarcaster, setMatchWithFarcaster] = useState(false);

  // Redirect if not authenticated
  useEffect(() => {
    if (!authLoading && !isAuthenticated) {
      router.push('/');
    }
  }, [isAuthenticated, authLoading, router]);

  // Initialize from sessionStorage (one-time)
  useEffect(() => {
    if (!isAuthenticated || !user || initialized) return;

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

    // Load Farcaster users from draft
    if (draft.farcasterA) {
      setFarcasterUserA({
        fid: draft.farcasterA.fid,
        username: draft.farcasterA.username,
        display_name: draft.farcasterA.displayName,
        avatar_url: draft.farcasterA.pfpUrl,
        bio: draft.farcasterA.bio,
      });
    }

    if (draft.farcasterB) {
      setFarcasterUserB({
        fid: draft.farcasterB.fid,
        username: draft.farcasterB.username,
        display_name: draft.farcasterB.displayName,
        avatar_url: draft.farcasterB.pfpUrl,
        bio: draft.farcasterB.bio,
      });
    }

    setInitialized(true);
  }, [isAuthenticated, user, initialized]);

  // Handle URL params for user selection (every time params change)
  useEffect(() => {
    if (!isAuthenticated || !user) return;

    const slotParam = searchParams.get('slot');
    const slot = slotParam ? (slotParam.toLowerCase() as 'a' | 'b') : null;
    const fidParam = searchParams.get('fid');
    const sourceParam = searchParams.get('source'); // 'meetshipper' or 'farcaster'

    // Handle prefill from URL
    if (fidParam && slot) {
      const fidNum = parseInt(fidParam);
      if (!isNaN(fidNum) && fidNum !== user.fid) {
        // Determine matching mode from source parameter
        if (sourceParam === 'farcaster') {
          // Automatically check the Farcaster checkbox (only once)
          if (!matchWithFarcaster) {
            setMatchWithFarcaster(true);
            setMatchWithMeetShipper(false);
            return; // Exit early to avoid processing before checkbox state updates
          }

          // Process Farcaster user selection
          handleFarcasterUserSelection(fidNum, slot);
        } else if (sourceParam === 'meetshipper') {
          // Automatically check the MeetShipper checkbox (only once)
          if (!matchWithMeetShipper) {
            setMatchWithMeetShipper(true);
            setMatchWithFarcaster(false);
            return; // Exit early to avoid processing before checkbox state updates
          }

          // Process MeetShipper user selection
          const draft = getSuggestDraft();
          fetchAndPrefillUser(fidNum, slot, draft, false);
        }
      }
    }
  }, [searchParams, isAuthenticated, user, matchWithFarcaster, matchWithMeetShipper]);

  const fetchAndPrefillUser = async (
    fid: number,
    slot: 'a' | 'b' | null,
    existingDraft: any,
    isFarcasterMode: boolean = false
  ) => {
    // Note: Farcaster mode is now handled by handleFarcasterUserSelection
    // This function only handles MeetShipper mode

    // For MeetShipper mode, validate through API
    try {
      const data = await apiClient.get<UserProfile>(`/api/users/${fid}`);

      // Check if user was found (null returned for 404)
      if (!data) {
        console.log('[Suggest] User not found for FID:', fid);
        setError(`User not found. Please check the FID (${fid}) or try again.`);
        return;
      }

      const draftUser: SuggestDraftUser = {
        fid: data.fid,
        username: data.username,
        displayName: data.display_name,
        pfpUrl: data.avatar_url,
        bio: data.bio,
      };

      // Update MeetShipper user state
      if (slot === 'a') {
        setUserA(data);
        setSuggestDraft({ ...existingDraft, a: draftUser });
      } else if (slot === 'b') {
        if (existingDraft.a?.fid === fid) {
          toast.error('User A and User B must be different.');
          return;
        }
        setUserB(data);
        setSuggestDraft({ ...existingDraft, b: draftUser });
      } else {
        // No slot specified, use heuristic
        if (!existingDraft.a) {
          setUserA(data);
          setSuggestDraft({ ...existingDraft, a: draftUser });
        } else if (!existingDraft.b && existingDraft.a.fid !== fid) {
          setUserB(data);
          setSuggestDraft({ ...existingDraft, b: draftUser });
        }
      }
    } catch (err) {
      console.error('Error fetching MeetShipper user:', err);
      setError('An error occurred while fetching the user. Please try again.');
    }
  };

  // Handle Farcaster user selection from URL params
  const handleFarcasterUserSelection = async (fid: number, slot: 'a' | 'b') => {
    console.log('[Suggest] Fetching Farcaster user FID:', fid, 'for slot:', slot);

    try {
      const data = await apiClient.get<UserProfile>(`/api/farcaster/user/${fid}`);

      // Check if user was found (null returned for 404)
      if (!data) {
        console.log('[Suggest] Farcaster user not found for FID:', fid);
        setError(`Farcaster user not found. Please check the FID (${fid}) or try again.`);
        return;
      }

      console.log('[Suggest] Fetched Farcaster user:', data);

      // Convert to draft format
      const draftUser: SuggestDraftUser = {
        fid: data.fid,
        username: data.username,
        displayName: data.display_name,
        pfpUrl: data.avatar_url,
        bio: data.bio,
      };

      // Update state based on slot WITHOUT resetting the other slot
      if (slot === 'a') {
        // Check for duplicate with User B
        if (farcasterUserB && farcasterUserB.fid === fid) {
          toast.error('Farcaster User A and User B must be different.');
          return;
        }
        setFarcasterUserA(data);
        setDraftFarcasterUserA(draftUser);
      } else if (slot === 'b') {
        // Check for duplicate with User A
        if (farcasterUserA && farcasterUserA.fid === fid) {
          toast.error('Farcaster User A and User B must be different.');
          return;
        }
        setFarcasterUserB(data);
        setDraftFarcasterUserB(draftUser);
      }

      console.log('[Suggest] Successfully set Farcaster user for slot:', slot);
    } catch (err) {
      console.error('Error fetching Farcaster user:', err);
      setError('An error occurred while fetching the Farcaster user. Please try again.');
    }
  };

  const handleUserAChange = (newUser: UserProfile | null) => {
    // Check if trying to select same user as B
    if (newUser && userB && newUser.fid === userB.fid) {
      toast.error('User A and User B must be different.');
      return;
    }

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
    // Check if trying to select same user as A
    if (newUser && userA && newUser.fid === userA.fid) {
      toast.error('User A and User B must be different.');
      return;
    }

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

  const handleFarcasterUserAChange = (newUser: UserProfile | null) => {
    // Check if trying to select same user as Farcaster B
    if (newUser && farcasterUserB && newUser.fid === farcasterUserB.fid) {
      toast.error('Farcaster User A and User B must be different.');
      return;
    }
    setFarcasterUserA(newUser);

    // Save to draft
    if (newUser) {
      const draftUser: SuggestDraftUser = {
        fid: newUser.fid,
        username: newUser.username,
        displayName: newUser.display_name,
        pfpUrl: newUser.avatar_url,
        bio: newUser.bio,
      };
      setDraftFarcasterUserA(draftUser);
    } else {
      setDraftFarcasterUserA(undefined);
    }
  };

  const handleFarcasterUserBChange = (newUser: UserProfile | null) => {
    // Check if trying to select same user as Farcaster A
    if (newUser && farcasterUserA && newUser.fid === farcasterUserA.fid) {
      toast.error('Farcaster User A and User B must be different.');
      return;
    }
    setFarcasterUserB(newUser);

    // Save to draft
    if (newUser) {
      const draftUser: SuggestDraftUser = {
        fid: newUser.fid,
        username: newUser.username,
        displayName: newUser.display_name,
        pfpUrl: newUser.avatar_url,
        bio: newUser.bio,
      };
      setDraftFarcasterUserB(draftUser);
    } else {
      setDraftFarcasterUserB(undefined);
    }
  };

  // Handlers for mutually exclusive checkboxes
  const handleMeetShipperCheckbox = (checked: boolean) => {
    setMatchWithMeetShipper(checked);
    if (checked) {
      setMatchWithFarcaster(false);
      setFarcasterUserA(null);
      setFarcasterUserB(null);
      // Clear Farcaster draft
      setDraftFarcasterUserA(undefined);
      setDraftFarcasterUserB(undefined);
    }
  };

  const handleFarcasterCheckbox = (checked: boolean) => {
    setMatchWithFarcaster(checked);
    if (checked) {
      setMatchWithMeetShipper(false);
      setUserA(null);
      setUserB(null);
      // Clear MeetShipper draft
      const draft = getSuggestDraft();
      setSuggestDraft({ ...draft, a: undefined, b: undefined });
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
  const isFormValid = (() => {
    const messageValid = message.length >= 20 && message.length <= 100;

    if (matchWithMeetShipper) {
      return userA && userB && userA.fid !== userB.fid && messageValid;
    }

    if (matchWithFarcaster) {
      return farcasterUserA && farcasterUserB && farcasterUserA.fid !== farcasterUserB.fid && messageValid;
    }

    return false;
  })();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!isFormValid) return;

    let activeUserA: UserProfile | null = null;
    let activeUserB: UserProfile | null = null;

    if (matchWithMeetShipper) {
      if (!userA || !userB) return;
      activeUserA = userA;
      activeUserB = userB;
    } else if (matchWithFarcaster) {
      if (!farcasterUserA || !farcasterUserB) return;
      activeUserA = farcasterUserA;
      activeUserB = farcasterUserB;
    } else {
      return;
    }

    // Additional validation: A ≠ B
    if (activeUserA.fid === activeUserB.fid) {
      setError('User A and User B must be different people');
      return;
    }

    setError(null);
    setLoading(true);

    try {
      // Determine endpoint based on mode
      const endpoint = matchWithFarcaster ? '/api/suggestions/external' : '/api/matches/suggestions';
      const requestBody = matchWithFarcaster
        ? {
            userAFid: activeUserA.fid,
            userBFid: activeUserB.fid,
            reason: message.trim(),
          }
        : {
            userAFid: activeUserA.fid,
            userBFid: activeUserB.fid,
            message: message.trim(),
          };

      console.log('[Frontend] Submitting suggestion:', {
        mode: matchWithFarcaster ? 'farcaster' : 'meetshipper',
        endpoint,
        userA: activeUserA.username,
        userB: activeUserB.username,
        reason: message.trim(),
      });

      const response = await apiClient.post<{ success: boolean; suggestion?: any }>(endpoint, requestBody);

      console.log('[Frontend] Response:', {
        success: response?.success,
        suggestionId: response?.suggestion?.id,
      });

      if (response?.success) {
        // Clear saved state
        clearSuggestDraft();

        // Show success toast based on mode
        if (matchWithFarcaster) {
          toast.success('✅ Suggestion sent to both users via Farcaster!', {
            duration: 4000,
            style: {
              background: '#10B981',
              color: '#fff',
              fontWeight: '600',
            },
          });
          // Redirect to your suggestions in inbox
          router.push('/mini/inbox?tab=your-suggestions');
        } else {
          // Success! Redirect to dashboard for MeetShipper mode
          router.push('/dashboard?suggestion=created');
        }
      }
    } catch (err: any) {
      console.error('[Frontend] Error creating suggestion:', err);

      // Extract cooldown info using shared utility
      const cooldown = extractCooldownInfo(err);

      if (cooldown) {
        setCooldownInfo(cooldown);
        setError(formatCooldownMessage(cooldown));
      } else {
        setCooldownInfo(null);
        setError(err.message || 'Failed to create match suggestion');
      }
    } finally {
      setLoading(false);
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
      <Toaster position="top-center" />
      <Navigation />

      <div className="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Main Container */}
        <div className="backdrop-blur-xl bg-gradient-to-br from-white/80 via-purple-50/60 to-blue-50/60 rounded-2xl border border-white/60 shadow-lg hover:shadow-2xl transition-all duration-300 p-8 mb-6">
          {/* Title Bar */}
          <div className="text-center mb-8">
            <h1 className="text-2xl font-bold bg-gradient-to-r from-purple-700 to-blue-700 bg-clip-text text-transparent flex items-center justify-center gap-2 mb-2">
              <span>🤝</span> Suggest a Match Between Two Users
            </h1>
            <p className="text-sm text-gray-600">
              Connect two people from your network
            </p>
          </div>

          {/* How it works */}
          <div className="backdrop-blur-xl bg-gradient-to-r from-blue-50/80 to-indigo-50/80 border border-blue-200/60 rounded-xl p-5 mb-6">
            <h2 className="text-sm font-bold text-blue-800 mb-3 flex items-center gap-2">
              <svg
                className="w-4 h-4"
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
            <p className="text-sm text-blue-800">
              You can suggest a match between two users along with an introduction
              message. Each of them can accept or decline. If both accept, they
              will earn points and automatically receive a link to a shared chat
              room.
            </p>
          </div>

          {/* How to add users from Explore Users */}
          <div className="backdrop-blur-xl bg-gradient-to-r from-green-50/80 to-emerald-50/80 border border-green-200/60 rounded-xl p-5 mb-6">
            <h2 className="text-sm font-bold text-green-800 mb-3 flex items-center gap-2">
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
                  d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01"
                />
              </svg>
              How to add users from Explore Users
            </h2>
            <div className="text-sm text-green-800 space-y-3">
              <div>
                <p className="font-semibold mb-2">Steps:</p>
                <ol className="list-decimal list-inside space-y-1.5 ml-2 text-xs">
                  <li>
                    Go to{' '}
                    <Link
                      href="/users"
                      className="underline hover:text-green-900 font-semibold"
                    >
                      Explore Users
                    </Link>{' '}
                    and open a person's View Profile
                  </li>
                  <li>
                    Click <strong>+ Suggest Match</strong>:
                    <ul className="list-disc list-inside ml-5 mt-1 space-y-0.5">
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
              <div className="pt-2 border-t border-green-200/60">
                <p className="font-semibold mb-1.5">Rules:</p>
                <ul className="space-y-1 ml-2 text-xs">
                  <li className="flex items-start gap-1.5">
                    <span className="flex-shrink-0">✓</span>
                    <span>User A and User B must be different FIDs</span>
                  </li>
                  <li className="flex items-start gap-1.5">
                    <span className="flex-shrink-0">✓</span>
                    <span>Once a user is selected as User A, the Suggest Match button on that
                    same profile will be disabled</span>
                  </li>
                  <li className="flex items-start gap-1.5">
                    <span className="flex-shrink-0">✓</span>
                    <span>Manual entry is allowed via <strong>Manual USER ID (FID)</strong> with
                    live validation</span>
                  </li>
                </ul>
              </div>
            </div>
          </div>

          {/* Form */}
          <div className="space-y-6">
            {/* MeetShipper Users Checkbox */}
            <div className="mb-6 flex flex-col lg:flex-row gap-4">
              <div className="flex-shrink-0">
                <label className="flex items-center gap-3 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={matchWithMeetShipper}
                    onChange={(e) => handleMeetShipperCheckbox(e.target.checked)}
                    disabled={matchWithFarcaster}
                    className="w-5 h-5 text-[#4F46E5] border-2 border-gray-300 rounded focus:ring-2 focus:ring-[#4F46E5] disabled:opacity-50 disabled:cursor-not-allowed"
                  />
                  <span className={`text-base font-bold ${matchWithFarcaster ? 'text-gray-400' : 'text-[#4F46E5]'}`}>
                    Match Two Different MeetShipper Users
                  </span>
                </label>
              </div>

              {/* How It Works Info Box */}
              <div className="flex-1 bg-gradient-to-br from-violet-50 to-purple-50 rounded-xl p-4 shadow-sm border border-violet-200">
                <h4 className="text-sm font-semibold text-violet-600 mb-2">How It Works</h4>
                <p className="text-xs text-gray-700 leading-relaxed">
                  For User A, click Find User to select or enter their FID.
                  Verify with the Lookup button.
                  Then repeat the same steps for User B.
                  Once both users are set, your message and suggestion notification are sent to each of them.
                  Both users can accept or decline; you can track their responses from the Inbox page.
                </p>
              </div>
            </div>

            {/* User A FID */}
            <UserLookup
              label="User A FID"
              value={userA}
              onChange={handleUserAChange}
              currentUserFid={user.fid}
              excludeFid={userB?.fid}
              slot="a"
              source="suggest-match-meetshipper"
              disabled={!matchWithMeetShipper}
            />

            {/* User B FID */}
            <UserLookup
              label="User B FID"
              value={userB}
              onChange={handleUserBChange}
              currentUserFid={user.fid}
              excludeFid={userA?.fid}
              slot="b"
              source="suggest-match-meetshipper"
              disabled={!matchWithMeetShipper}
            />

            {/* Farcaster Users Checkbox */}
            <div className="mb-6 mt-8 pt-8 border-t border-gray-200 flex flex-col lg:flex-row gap-4">
              <div className="flex-shrink-0">
                <label className="flex items-center gap-3 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={matchWithFarcaster}
                    onChange={(e) => handleFarcasterCheckbox(e.target.checked)}
                    disabled={matchWithMeetShipper}
                    className="w-5 h-5 text-[#4F46E5] border-2 border-gray-300 rounded focus:ring-2 focus:ring-[#4F46E5] disabled:opacity-50 disabled:cursor-not-allowed"
                  />
                  <span className={`text-base font-bold ${matchWithMeetShipper ? 'text-gray-400' : 'text-[#4F46E5]'}`}>
                    Match Two Different Farcaster Users
                  </span>
                </label>
              </div>

              {/* How It Works Info Box */}
              <div className="flex-1 bg-gradient-to-br from-violet-50 to-purple-50 rounded-xl p-4 shadow-sm border border-violet-200">
                <h4 className="text-sm font-semibold text-violet-600 mb-2">How It Works</h4>
                <p className="text-xs text-gray-700 leading-relaxed">
                  For User A, click Find User to select or enter their FID.
                  Verify with the Lookup button.
                  Then repeat the same steps for User B.
                  Once both users are verified, a message notification is created and delivered to both users' Farcaster inboxes.
                  Each user can open the Meet Shipper link from that message to review and respond to the suggested match.
                  You can monitor accept or decline statuses through the Inbox page.
                </p>
              </div>
            </div>

            {/* Farcaster User A FID */}
            <UserLookup
              label="Farcaster User A FID"
              value={farcasterUserA}
              onChange={handleFarcasterUserAChange}
              currentUserFid={user.fid}
              excludeFid={farcasterUserB?.fid}
              slot="a"
              source="suggest-match-farcaster"
              disabled={!matchWithFarcaster}
            />

            {/* Farcaster User B FID */}
            <UserLookup
              label="Farcaster User B FID"
              value={farcasterUserB}
              onChange={handleFarcasterUserBChange}
              currentUserFid={user.fid}
              excludeFid={farcasterUserA?.fid}
              slot="b"
              source="suggest-match-farcaster"
              disabled={!matchWithFarcaster}
            />

            {/* A ≠ B Validation Warning - MeetShipper */}
            {matchWithMeetShipper && userA && userB && userA.fid === userB.fid && (
              <div className="backdrop-blur-xl bg-gradient-to-r from-red-50/80 to-pink-50/80 border border-red-200/60 rounded-xl p-4">
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
                  <p className="text-sm text-red-800 font-medium">
                    User A and User B must be different people. Please select different users.
                  </p>
                </div>
              </div>
            )}

            {/* A ≠ B Validation Warning - Farcaster */}
            {matchWithFarcaster && farcasterUserA && farcasterUserB && farcasterUserA.fid === farcasterUserB.fid && (
              <div className="backdrop-blur-xl bg-gradient-to-r from-red-50/80 to-pink-50/80 border border-red-200/60 rounded-xl p-4">
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
                  <p className="text-sm text-red-800 font-medium">
                    User A and User B must be different people. Please select different users.
                  </p>
                </div>
              </div>
            )}

            {/* Message */}
            <div>
              <label
                htmlFor="message"
                className="block text-sm font-semibold text-gray-700 mb-3"
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
                disabled={!matchWithMeetShipper && !matchWithFarcaster}
                className={`w-full px-4 py-3 bg-white/70 backdrop-blur-sm border rounded-xl focus:ring-2 text-gray-900 placeholder:text-gray-400 resize-none transition-all duration-200 ${
                  !matchWithMeetShipper && !matchWithFarcaster
                    ? 'opacity-60 cursor-not-allowed'
                    : message.length > 0 && messageError
                    ? 'border-red-300 focus:ring-red-400 focus:border-red-400'
                    : 'border-purple-200/60 focus:ring-purple-400 focus:border-purple-400 hover:border-purple-300'
                }`}
              />
              <div className="mt-2 flex items-center justify-between">
                <div>
                  {message.length > 0 && messageError ? (
                    <p className="text-xs text-red-600 font-medium">{messageError}</p>
                  ) : message.length >= 20 ? (
                    <p className="text-xs text-emerald-600 font-medium flex items-center gap-1">
                      <svg className="w-3.5 h-3.5" fill="currentColor" viewBox="0 0 20 20">
                        <path
                          fillRule="evenodd"
                          d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
                          clipRule="evenodd"
                        />
                      </svg>
                      Message looks good
                    </p>
                  ) : (
                    <p className="text-xs text-gray-500">Required: 20-100 characters</p>
                  )}
                </div>
                <p
                  className={`text-xs font-medium ${
                    message.length > 100 ? 'text-red-600' : 'text-gray-500'
                  }`}
                >
                  {message.length}/100
                </p>
              </div>
            </div>

            {/* Error Display */}
            {error && (
              <div className="mb-4">
                {cooldownInfo ? (
                  <CooldownCard
                    cooldownInfo={cooldownInfo}
                    message={error}
                    context="suggestion"
                  />
                ) : (
                  <div className="backdrop-blur-xl bg-gradient-to-r from-red-50/80 to-pink-50/80 border border-red-200/60 rounded-xl p-4">
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
                      <p className="text-sm text-red-800 font-medium">{error}</p>
                    </div>
                  </div>
                )}
              </div>
            )}

            {/* What happens next */}
            <div className="backdrop-blur-xl bg-gradient-to-br from-purple-50/80 via-blue-50/80 to-indigo-50/80 border border-purple-200/60 rounded-xl p-5">
              <h3 className="text-sm font-bold text-purple-800 mb-3 flex items-center gap-2">
                <span>💡</span> What happens next?
              </h3>
              <ul className="text-sm text-purple-800 space-y-2">
                <li className="flex items-start gap-2">
                  <span className="flex-shrink-0">📨</span>
                  <span>Both users will receive your match suggestion and message in their inbox</span>
                </li>
                <li className="flex items-start gap-2">
                  <span className="flex-shrink-0">✅</span>
                  <span>Each of them can accept or decline the suggestion</span>
                </li>
                <li className="flex items-start gap-2">
                  <span className="flex-shrink-0">🔗</span>
                  <span>If accepted: Both users will earn points and receive an automatic chat room link</span>
                </li>
                <li className="flex items-start gap-2">
                  <span className="flex-shrink-0">⏳</span>
                  <span>If declined: You'll be notified (7-day cooldown applies)</span>
                </li>
              </ul>
            </div>

            {/* Validation Summary */}
            {!isFormValid && (userA || userB || farcasterUserA || farcasterUserB || message.length > 0) && (
              <div className="backdrop-blur-xl bg-gradient-to-r from-gray-50/80 to-slate-50/80 border border-gray-200/60 rounded-xl p-4">
                <p className="text-xs font-bold text-gray-700 mb-2 uppercase tracking-wide">
                  To submit suggestion:
                </p>
                <ul className="text-xs text-gray-600 space-y-1.5">
                  <li className={`flex items-center gap-2 ${matchWithMeetShipper || matchWithFarcaster ? 'text-emerald-600 font-medium' : ''}`}>
                    <span className="flex-shrink-0">{matchWithMeetShipper || matchWithFarcaster ? '✓' : '○'}</span>
                    <span>Select a matching type (MeetShipper or Farcaster)</span>
                  </li>
                  {matchWithMeetShipper && (
                    <>
                      <li className={`flex items-center gap-2 ${userA ? 'text-emerald-600 font-medium' : ''}`}>
                        <span className="flex-shrink-0">{userA ? '✓' : '○'}</span>
                        <span>Select User A</span>
                      </li>
                      <li className={`flex items-center gap-2 ${userB ? 'text-emerald-600 font-medium' : ''}`}>
                        <span className="flex-shrink-0">{userB ? '✓' : '○'}</span>
                        <span>Select User B</span>
                      </li>
                      <li
                        className={`flex items-center gap-2 ${
                          userA && userB && userA.fid !== userB.fid
                            ? 'text-emerald-600 font-medium'
                            : ''
                        }`}
                      >
                        <span className="flex-shrink-0">
                          {userA && userB && userA.fid !== userB.fid ? '✓' : '○'}
                        </span>
                        <span>User A and User B must be different</span>
                      </li>
                    </>
                  )}
                  {matchWithFarcaster && (
                    <>
                      <li className={`flex items-center gap-2 ${farcasterUserA ? 'text-emerald-600 font-medium' : ''}`}>
                        <span className="flex-shrink-0">{farcasterUserA ? '✓' : '○'}</span>
                        <span>Select Farcaster User A</span>
                      </li>
                      <li className={`flex items-center gap-2 ${farcasterUserB ? 'text-emerald-600 font-medium' : ''}`}>
                        <span className="flex-shrink-0">{farcasterUserB ? '✓' : '○'}</span>
                        <span>Select Farcaster User B</span>
                      </li>
                      <li
                        className={`flex items-center gap-2 ${
                          farcasterUserA && farcasterUserB && farcasterUserA.fid !== farcasterUserB.fid
                            ? 'text-emerald-600 font-medium'
                            : ''
                        }`}
                      >
                        <span className="flex-shrink-0">
                          {farcasterUserA && farcasterUserB && farcasterUserA.fid !== farcasterUserB.fid ? '✓' : '○'}
                        </span>
                        <span>User A and User B must be different</span>
                      </li>
                    </>
                  )}
                  <li
                    className={`flex items-center gap-2 ${
                      message.length >= 20 && message.length <= 100
                        ? 'text-emerald-600 font-medium'
                        : ''
                    }`}
                  >
                    <span className="flex-shrink-0">
                      {message.length >= 20 && message.length <= 100 ? '✓' : '○'}
                    </span>
                    <span>Write introduction message (20-100 chars)</span>
                  </li>
                </ul>
              </div>
            )}

            {/* Buttons */}
            <div className="flex items-center gap-3 pt-2">
              <button
                type="button"
                onClick={() => router.back()}
                className="px-6 py-3 border-2 border-gray-300/60 rounded-xl text-gray-700 bg-white/70 backdrop-blur-sm hover:bg-white hover:border-gray-400 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-gray-400 font-medium transition-all duration-200"
              >
                Cancel
              </button>
              <button
                type="submit"
                onClick={handleSubmit}
                disabled={loading || !isFormValid}
                aria-disabled={loading || !isFormValid}
                className="flex-1 px-6 py-3 bg-gradient-to-r from-purple-600 to-blue-600 text-white rounded-xl hover:from-purple-700 hover:to-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-purple-500 disabled:from-gray-300 disabled:to-gray-400 disabled:cursor-not-allowed font-semibold shadow-md hover:shadow-lg transition-all duration-200"
              >
                {loading ? 'Creating Suggestion...' : 'Create Match Suggestion'}
              </button>
            </div>
          </div>
        </div>

        {/* Privacy Notice */}
        <div className="backdrop-blur-xl bg-gradient-to-r from-purple-50/80 to-indigo-50/80 border border-purple-200/60 rounded-xl p-4">
          <p className="text-sm text-purple-800">
            <strong className="font-semibold">Privacy Notice:</strong> Your identity as the suggester will be
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