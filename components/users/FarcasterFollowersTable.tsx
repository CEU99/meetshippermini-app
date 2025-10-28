'use client';

import { useEffect, useState, useRef } from 'react';
import { useRouter } from 'next/navigation';
import Image from 'next/image';
import { apiClient } from '@/lib/api-client';

interface FollowingUser {
  fid: number;
  username?: string;
  displayName?: string;
  pfpUrl?: string;
  bio?: string;
}

interface FarcasterFollowersTableProps {
  loading?: boolean;
  sourceParam: string | null;
  slotParam: string | null;
  excludeFid: number | null;
}

export function FarcasterFollowersTable({ sourceParam, slotParam, excludeFid }: FarcasterFollowersTableProps) {
  const router = useRouter();
  const [following, setFollowing] = useState<FollowingUser[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [hasFailed, setHasFailed] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');

  // Fetch following list
  const fetchFollowing = async () => {
    try {
      setError(null);
      const data = await apiClient.get<{ users: FollowingUser[]; total?: number }>(
        '/api/farcaster/following?all=true&limit=500'
      );

      console.log('[FarcasterFollowers] Loaded:', data.users?.length || 0, 'users');
      setFollowing(data.users || []);
      setHasFailed(false);
    } catch (err) {
      console.error('[FarcasterFollowers] Error:', err);
      if (loading) {
        setHasFailed(true);
      }
      setFollowing([]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchFollowing();

    // Poll for updates every 2 minutes
    const interval = setInterval(fetchFollowing, 120000);
    return () => clearInterval(interval);
  }, []);

  // Filter followers based on search term
  const filteredFollowing = following.filter((user) => {
    if (!searchTerm) return true;
    const searchLower = searchTerm.toLowerCase();
    const displayName = (user.displayName || '').toLowerCase();
    const username = (user.username || '').toLowerCase();
    const fid = user.fid.toString();
    return displayName.includes(searchLower) || username.includes(searchLower) || fid.includes(searchLower);
  });

  // If failed to load initially, show minimal error
  if (hasFailed) {
    return (
      <div className="bg-white rounded-lg border border-gray-200 p-6 text-center">
        <div className="flex justify-center mb-3">
          <svg className="h-10 w-10 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
        </div>
        <p className="text-sm text-gray-600">Unable to load Farcaster followers</p>
      </div>
    );
  }

  if (loading) {
    return (
      <div className="space-y-3">
        {[1, 2, 3, 4].map((i) => (
          <div key={i} className="p-4 animate-pulse bg-white rounded-lg border border-gray-200">
            <div className="flex items-center space-x-3">
              <div className="w-12 h-12 bg-gray-200 rounded-full"></div>
              <div className="flex-1">
                <div className="h-4 bg-gray-200 rounded w-2/3 mb-2"></div>
                <div className="h-3 bg-gray-200 rounded w-1/2"></div>
              </div>
            </div>
          </div>
        ))}
      </div>
    );
  }

  if (error) {
    return (
      <div className="bg-white rounded-lg border border-gray-200 p-6 text-center">
        <p className="text-red-600 text-sm mb-3">{error}</p>
        <button
          onClick={fetchFollowing}
          className="px-4 py-2 bg-[#4F46E5] text-white rounded-lg hover:bg-[#4338CA] transition-colors text-sm font-medium"
        >
          Retry
        </button>
      </div>
    );
  }

  if (following.length === 0) {
    return (
      <div className="bg-white rounded-lg border border-gray-200 p-8 text-center">
        <div className="flex justify-center mb-4">
          <svg className="h-12 w-12 text-[#4F46E5]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
          </svg>
        </div>
        <h3 className="text-sm font-semibold text-gray-900 mb-2">No Farcaster Followers Found</h3>
        <p className="text-sm text-gray-600 mb-4">
          Start following users on Farcaster to see them here and create matches!
        </p>
      </div>
    );
  }

  // Display followers in a scrollable list
  return (
    <div className="space-y-3">
      {/* Search Bar */}
      <div className="relative">
        <input
          type="text"
          placeholder="Search by name, username, or FID..."
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          className="w-full px-4 py-3 pl-11 border-2 border-gray-200 rounded-xl focus:ring-2 focus:ring-[#4F46E5] focus:border-[#4F46E5] transition-all text-gray-900"
        />
        <svg
          className="absolute left-3 top-3.5 h-5 w-5 text-gray-400"
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
      </div>

      {/* Results count and refresh */}
      <div className="flex items-center justify-between">
        <p className="text-sm text-gray-600">
          {searchTerm ? (
            <span>
              Showing <span className="font-semibold text-[#4F46E5]">{filteredFollowing.length}</span> of{' '}
              <span className="font-semibold text-[#4F46E5]">{following.length}</span> followers
            </span>
          ) : (
            <span className="font-semibold text-gray-700">
              {following.length} Follower{following.length !== 1 ? 's' : ''}
            </span>
          )}
        </p>
        <button
          onClick={fetchFollowing}
          className="p-1.5 text-gray-500 hover:text-[#4F46E5] hover:bg-[#EDE9FE] rounded-lg transition-colors"
          title="Refresh"
        >
          <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
          </svg>
        </button>
      </div>

      {/* Scrollable list */}
      <div className="max-h-[600px] overflow-y-auto pr-2">
        {filteredFollowing.length === 0 && searchTerm ? (
          <div className="text-center py-8">
            <p className="text-sm text-gray-600">No followers match "{searchTerm}"</p>
          </div>
        ) : (
          filteredFollowing.map((user) => {
        if (!user || !user.fid) return null;

        const displayName = user.displayName || user.username || `User ${user.fid}`;
        const username = user.username || `user${user.fid}`;
        const pfpUrl = user.pfpUrl || 'https://via.placeholder.com/48/4F46E5/ffffff?text=FC';
        const profileUrl = user.username
          ? `https://warpcast.com/${user.username}`
          : `https://warpcast.com/~/profiles/${user.fid}`;

        return (
          <div
            key={`follower-${user.fid}`}
            className="bg-white rounded-lg border border-gray-200 p-3 hover:border-[#4F46E5] hover:shadow-md transition-all"
          >
            <div className="flex items-center gap-3">
              <a href={profileUrl} target="_blank" rel="noopener noreferrer" className="flex-shrink-0 relative group">
                <Image
                  src={pfpUrl}
                  alt={displayName}
                  width={48}
                  height={48}
                  className="rounded-full border-2 border-gray-200 group-hover:border-[#4F46E5] transition-colors"
                  unoptimized
                  onError={(e) => {
                    const target = e.target as HTMLImageElement;
                    target.src = 'https://via.placeholder.com/48/4F46E5/ffffff?text=FC';
                  }}
                />
                {/* External link indicator */}
                <div className="absolute bottom-0 right-0 w-4 h-4 bg-blue-500 border-2 border-white rounded-full flex items-center justify-center">
                  <svg className="w-2 h-2 text-white" fill="currentColor" viewBox="0 0 20 20">
                    <path d="M11 3a1 1 0 100 2h2.586l-6.293 6.293a1 1 0 101.414 1.414L15 6.414V9a1 1 0 102 0V4a1 1 0 00-1-1h-5z" />
                  </svg>
                </div>
              </a>

              <div className="flex-1 min-w-0">
                <p className="text-sm font-semibold text-gray-900 truncate">{displayName}</p>
                <p className="text-xs text-gray-600 truncate">@{username}</p>
                <div className="mt-1 inline-flex items-center px-2 py-0.5 bg-[#EDE9FE] rounded-full">
                  <svg className="w-3 h-3 mr-1 text-[#4F46E5]" fill="currentColor" viewBox="0 0 24 24">
                    <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 18c-4.41 0-8-3.59-8-8s3.59-8 8-8 8 3.59 8 8-3.59 8-8 8z" />
                  </svg>
                  <span className="text-xs font-mono text-[#4F46E5]">{user.fid}</span>
                </div>
              </div>

              <div className="flex-shrink-0 flex items-center gap-2">
                {sourceParam === 'create-match-farcaster' ? (
                  <>
                    <button
                      onClick={() => router.push(`/mini/create?farcasterTargetFid=${user.fid}`)}
                      className="px-3 py-1.5 bg-[#4F46E5] hover:bg-[#4338CA] text-white text-xs font-semibold rounded-lg transition-colors shadow-sm cursor-pointer"
                      title="Create a match with this user"
                    >
                      Create Match
                    </button>
                    <button
                      disabled
                      className="px-3 py-1.5 bg-gray-300 text-white text-xs font-semibold rounded-lg shadow-sm opacity-50 cursor-not-allowed"
                    >
                      Suggest Match
                    </button>
                  </>
                ) : sourceParam === 'suggest-match-farcaster' ? (
                  <>
                    <button
                      disabled
                      className="px-3 py-1.5 bg-gray-300 text-white text-xs font-semibold rounded-lg shadow-sm opacity-50 cursor-not-allowed"
                    >
                      Create Match
                    </button>
                    {excludeFid && user.fid === excludeFid ? (
                      <button
                        disabled
                        className="px-3 py-1.5 bg-gray-300 text-white text-xs font-semibold rounded-lg shadow-sm opacity-50 cursor-not-allowed"
                        title="User already selected"
                      >
                        Suggest Match
                      </button>
                    ) : (
                      <button
                        onClick={() => {
                          const params = new URLSearchParams({ fid: user.fid.toString(), source: 'farcaster' });
                          if (slotParam) params.append('slot', slotParam);
                          router.push(`/mini/suggest?${params.toString()}`);
                        }}
                        className="px-3 py-1.5 bg-[#4F46E5] hover:bg-[#4338CA] text-white text-xs font-semibold rounded-lg transition-colors shadow-sm cursor-pointer"
                        title="Suggest a match with this user"
                      >
                        Suggest Match
                      </button>
                    )}
                  </>
                ) : (
                  <>
                    <button
                      disabled
                      className="px-3 py-1.5 bg-gray-300 text-white text-xs font-semibold rounded-lg shadow-sm opacity-50 cursor-not-allowed"
                      title="Select a matching type first"
                    >
                      Create Match
                    </button>
                    <button
                      disabled
                      className="px-3 py-1.5 bg-gray-300 text-white text-xs font-semibold rounded-lg shadow-sm opacity-50 cursor-not-allowed"
                      title="Select a matching type first"
                    >
                      Suggest Match
                    </button>
                  </>
                )}
              </div>
            </div>
          </div>
        );
      })
        )}
      </div>
    </div>
  );
}
