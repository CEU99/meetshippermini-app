'use client';

import { useEffect, useState } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import Link from 'next/link';
import { getSuggestDraft, setSuggestDraft, type SuggestDraftUser } from '@/lib/suggest-draft';
import { apiClient } from '@/lib/api-client';

interface UserProfileActionsProps {
  fid: number;
  username: string;
  displayName?: string;
  pfpUrl?: string;
  bio?: string;
}

export function UserProfileActions({
  fid,
  username,
  displayName,
  pfpUrl,
  bio,
}: UserProfileActionsProps) {
  const router = useRouter();
  const searchParams = useSearchParams();
  const [isAlreadySelected, setIsAlreadySelected] = useState(false);
  const [suggestSlot, setSuggestSlot] = useState<'a' | 'b'>('a');
  const [loading, setLoading] = useState(false);

  // Get slot from URL if present
  const urlSlot = searchParams.get('slot')?.toLowerCase() as 'a' | 'b' | null;

  useEffect(() => {
    // Check if this FID is already in the draft
    const draft = getSuggestDraft();

    if (draft.a?.fid === fid) {
      setIsAlreadySelected(true);
    } else {
      setIsAlreadySelected(false);
      // Determine which slot to use: if A is empty, use A; otherwise use B
      // If URL has a slot parameter, use that; otherwise use heuristic
      if (urlSlot === 'a' || urlSlot === 'b') {
        setSuggestSlot(urlSlot);
      } else {
        setSuggestSlot(draft.a ? 'b' : 'a');
      }
    }
  }, [fid, urlSlot]);

  const handleSuggestMatchClick = async (e: React.MouseEvent) => {
    e.preventDefault();
    setLoading(true);

    try {
      // Fetch full user profile to ensure we have all data
      const userProfile = await apiClient.get<any>(`/api/users/${fid}`);

      const draftUser: SuggestDraftUser = {
        fid: userProfile.fid,
        username: userProfile.username,
        displayName: userProfile.display_name || displayName,
        pfpUrl: userProfile.avatar_url || pfpUrl,
        bio: userProfile.bio || bio,
      };

      // Update the draft with the selected user
      const draft = getSuggestDraft();
      if (suggestSlot === 'a') {
        setSuggestDraft({ ...draft, a: draftUser });
      } else {
        setSuggestDraft({ ...draft, b: draftUser });
      }

      // Redirect back to suggest page
      router.push('/mini/suggest');
    } catch (error) {
      console.error('Error fetching user profile:', error);
      // Fallback: just navigate with query params
      router.push(`/mini/suggest?slot=${suggestSlot}&fid=${fid}`);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex flex-wrap gap-3">
      {/* Create Match Button */}
      <Link
        href={`/mini/create?targetFid=${fid}`}
        className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-purple-600 hover:bg-purple-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-purple-500 transition-colors"
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
            d="M12 4v16m8-8H4"
          />
        </svg>
        Create Match
      </Link>

      {/* Suggest Match Button */}
      {isAlreadySelected ? (
        <div className="relative group">
          <button
            disabled
            aria-label="This user is already selected as User A"
            className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-gray-300 cursor-not-allowed transition-colors"
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
                d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"
              />
            </svg>
            Suggest Match
          </button>
          {/* Tooltip */}
          <div className="absolute bottom-full left-1/2 transform -translate-x-1/2 mb-2 px-3 py-2 bg-gray-900 text-white text-xs rounded-md opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none whitespace-nowrap z-10">
            Already selected as User A
            <div className="absolute top-full left-1/2 transform -translate-x-1/2 -mt-1">
              <div className="border-4 border-transparent border-t-gray-900"></div>
            </div>
          </div>
        </div>
      ) : (
        <button
          onClick={handleSuggestMatchClick}
          disabled={loading}
          className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-green-600 hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500 transition-colors disabled:bg-green-400 disabled:cursor-wait"
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
              d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"
            />
          </svg>
          {loading ? 'Selecting...' : 'Suggest Match'}
        </button>
      )}

      {/* View on Warpcast Button */}
      <a
        href={`https://warpcast.com/${username}`}
        target="_blank"
        rel="noopener noreferrer"
        className="inline-flex items-center px-4 py-2 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-purple-500 transition-colors"
      >
        <svg
          className="w-4 h-4 mr-2"
          fill="currentColor"
          viewBox="0 0 24 24"
        >
          <path d="M12 2L2 7v10c0 5.55 3.84 10.74 9 12 5.16-1.26 9-6.45 9-12V7l-10-5z" />
        </svg>
        View on Warpcast
      </a>
    </div>
  );
}
