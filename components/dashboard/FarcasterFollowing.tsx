'use client';

import { useEffect, useState, useRef } from 'react';
import Image from 'next/image';
import Link from 'next/link';
import { apiClient } from '@/lib/api-client';

interface FollowingUser {
  fid: number;
  username?: string;
  displayName?: string;
  pfpUrl?: string;
  bio?: string;
}

export function FarcasterFollowing() {
  const [following, setFollowing] = useState<FollowingUser[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const scrollContainerRef = useRef<HTMLDivElement>(null);
  const [showLeftScroll, setShowLeftScroll] = useState(false);
  const [showRightScroll, setShowRightScroll] = useState(false);

  // Fetch following list (uses ?all=true to handle pagination automatically)
  const fetchFollowing = async () => {
    try {
      setError(null);
      const data = await apiClient.get<{ users: FollowingUser[]; total?: number }>(
        '/api/farcaster/following?all=true&limit=500'
      );

      console.log('[FarcasterFollowing] Raw API response:', data);
      console.log(`[FarcasterFollowing] Loaded ${data.users?.length || 0} following users`);

      // Debug: Log first few users to check data structure
      if (data.users && data.users.length > 0) {
        console.log('[FarcasterFollowing] First 3 users:', data.users.slice(0, 3));
      }

      setFollowing(data.users || []);
    } catch (err) {
      console.error('[FarcasterFollowing] Error fetching following:', err);
      setError('Failed to load following list');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchFollowing();

    // Poll for updates every 2 minutes
    const interval = setInterval(() => {
      fetchFollowing();
    }, 120000); // 120 seconds = 2 minutes

    return () => clearInterval(interval);
  }, []);

  // Handle scroll button visibility
  const updateScrollButtons = () => {
    if (scrollContainerRef.current) {
      const { scrollLeft, scrollWidth, clientWidth } = scrollContainerRef.current;
      setShowLeftScroll(scrollLeft > 0);
      setShowRightScroll(scrollLeft < scrollWidth - clientWidth - 10);
    }
  };

  useEffect(() => {
    updateScrollButtons();
    window.addEventListener('resize', updateScrollButtons);
    return () => window.removeEventListener('resize', updateScrollButtons);
  }, [following]);

  // Scroll functions
  const scrollLeft = () => {
    if (scrollContainerRef.current) {
      scrollContainerRef.current.scrollBy({ left: -300, behavior: 'smooth' });
    }
  };

  const scrollRight = () => {
    if (scrollContainerRef.current) {
      scrollContainerRef.current.scrollBy({ left: 300, behavior: 'smooth' });
    }
  };

  if (loading) {
    return (
      <div className="bg-white rounded-lg shadow-md p-6">
        <h2 className="text-xl font-bold text-gray-900 mb-4 flex items-center">
          <svg
            className="w-5 h-5 mr-2 text-purple-600"
            fill="currentColor"
            viewBox="0 0 24 24"
          >
            <path d="M17 3a2.828 2.828 0 114 4L7.5 20.5 2 22l1.5-5.5L17 3z" />
          </svg>
          Farcaster Following
        </h2>
        <div className="flex space-x-4 overflow-hidden">
          {[1, 2, 3, 4, 5].map((i) => (
            <div
              key={i}
              className="flex-shrink-0 w-32 h-40 bg-gray-100 rounded-lg animate-pulse"
            />
          ))}
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="bg-white rounded-lg shadow-md p-6">
        <h2 className="text-xl font-bold text-gray-900 mb-4 flex items-center">
          <svg
            className="w-5 h-5 mr-2 text-purple-600"
            fill="currentColor"
            viewBox="0 0 24 24"
          >
            <path d="M17 3a2.828 2.828 0 114 4L7.5 20.5 2 22l1.5-5.5L17 3z" />
          </svg>
          Farcaster Following
        </h2>
        <div className="text-center py-8">
          <p className="text-red-600 mb-4">{error}</p>
          <button
            onClick={fetchFollowing}
            className="px-4 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700"
          >
            Retry
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="bg-white rounded-lg shadow-md p-6 relative">
      {/* Header */}
      <div className="flex items-center justify-between mb-4">
        <h2 className="text-xl font-bold text-gray-900 flex items-center">
          <svg
            className="w-5 h-5 mr-2 text-purple-600"
            fill="currentColor"
            viewBox="0 0 24 24"
          >
            <path d="M17 3a2.828 2.828 0 114 4L7.5 20.5 2 22l1.5-5.5L17 3z" />
          </svg>
          Farcaster Following
          <span className="ml-2 text-sm font-normal text-gray-500">
            ({following.length})
          </span>
        </h2>
        <button
          onClick={fetchFollowing}
          className="p-2 text-gray-500 hover:text-purple-600 hover:bg-purple-50 rounded-lg transition-colors"
          title="Refresh following list"
        >
          <svg
            className="w-5 h-5"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"
            />
          </svg>
        </button>
      </div>

      {/* Scroll Container */}
      <div className="relative">
        {/* Left Scroll Button */}
        {showLeftScroll && (
          <button
            onClick={scrollLeft}
            className="absolute left-0 top-1/2 -translate-y-1/2 z-10 bg-white/90 hover:bg-white shadow-lg rounded-full p-2 transition-all"
            aria-label="Scroll left"
          >
            <svg
              className="w-5 h-5 text-gray-700"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M15 19l-7-7 7-7"
              />
            </svg>
          </button>
        )}

        {/* Right Scroll Button */}
        {showRightScroll && (
          <button
            onClick={scrollRight}
            className="absolute right-0 top-1/2 -translate-y-1/2 z-10 bg-white/90 hover:bg-white shadow-lg rounded-full p-2 transition-all"
            aria-label="Scroll right"
          >
            <svg
              className="w-5 h-5 text-gray-700"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M9 5l7 7-7 7"
              />
            </svg>
          </button>
        )}

        {/* Following Cards */}
        <div
          ref={scrollContainerRef}
          onScroll={updateScrollButtons}
          className="flex space-x-4 overflow-x-auto scrollbar-thin scrollbar-thumb-purple-300 scrollbar-track-gray-100 pb-2"
          style={{
            scrollbarWidth: 'thin',
            scrollbarColor: '#c084fc #f3f4f6',
          }}
        >
          {following.length === 0 ? (
            <div className="w-full text-center py-8 text-gray-500">
              <p className="text-lg">No following users found</p>
              <p className="text-sm mt-2">
                Start following users on Farcaster to see them here!
              </p>
            </div>
          ) : (
            following.map((user) => {
              // Validate that user object exists and has FID
              if (!user || !user.fid) {
                console.warn('[FarcasterFollowing] Skipping invalid user:', user);
                return null;
              }

              // Provide fallbacks for missing data
              const displayName = user.displayName || user.username || `User ${user.fid}`;
              const username = user.username || `user${user.fid}`;
              const pfpUrl = user.pfpUrl || 'https://via.placeholder.com/64/9333EA/ffffff?text=FC';
              const altText = `${displayName} (@${username}) - FID: ${user.fid}`;

              // Link to Warpcast profile (external Farcaster profile viewer)
              const profileUrl = user.username
                ? `https://warpcast.com/${user.username}`
                : `https://warpcast.com/~/profiles/${user.fid}`;

              return (
                <a
                  key={`farcaster-user-${user.fid}`}
                  href={profileUrl}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="flex-shrink-0 w-40 bg-gradient-to-br from-purple-50 to-white border-2 border-purple-100 rounded-lg p-4 hover:border-purple-300 hover:shadow-lg transition-all group"
                >
                  {/* Profile Picture */}
                  <div className="relative w-16 h-16 mx-auto mb-3">
                    <Image
                      src={pfpUrl}
                      alt={altText}
                      width={64}
                      height={64}
                      className="rounded-full border-2 border-purple-200 group-hover:border-purple-400 transition-colors"
                      unoptimized
                      onError={(e) => {
                        const target = e.target as HTMLImageElement;
                        target.src = 'https://via.placeholder.com/64/9333EA/ffffff?text=FC';
                      }}
                    />
                    {/* External link indicator */}
                    <div className="absolute bottom-0 right-0 w-4 h-4 bg-blue-500 border-2 border-white rounded-full flex items-center justify-center">
                      <svg className="w-2 h-2 text-white" fill="currentColor" viewBox="0 0 20 20">
                        <path d="M11 3a1 1 0 100 2h2.586l-6.293 6.293a1 1 0 101.414 1.414L15 6.414V9a1 1 0 102 0V4a1 1 0 00-1-1h-5z" />
                        <path d="M5 5a2 2 0 00-2 2v8a2 2 0 002 2h8a2 2 0 002-2v-3a1 1 0 10-2 0v3H5V7h3a1 1 0 000-2H5z" />
                      </svg>
                    </div>
                  </div>

                  {/* User Info */}
                  <div className="text-center">
                    {/* Display Name */}
                    <p className="font-semibold text-gray-900 text-sm truncate group-hover:text-purple-700 transition-colors">
                      {displayName}
                    </p>

                    {/* Username */}
                    <p className="text-xs text-gray-600 truncate">
                      @{username}
                    </p>

                    {/* FID Badge */}
                    <div className="mt-2 inline-flex items-center px-2 py-1 bg-purple-100 rounded-full">
                      <svg
                        className="w-3 h-3 mr-1 text-purple-600"
                        fill="currentColor"
                        viewBox="0 0 24 24"
                      >
                        <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 18c-4.41 0-8-3.59-8-8s3.59-8 8-8 8 3.59 8 8-3.59 8-8 8zm-1-13h2v6h-2zm0 8h2v2h-2z" />
                      </svg>
                      <span className="text-xs font-mono text-purple-700">
                        {user.fid}
                      </span>
                    </div>
                  </div>

                  {/* Hover Effect Indicator */}
                  <div className="mt-3 text-center opacity-0 group-hover:opacity-100 transition-opacity">
                    <span className="text-xs text-purple-600 font-medium flex items-center justify-center gap-1">
                      View on Warpcast
                      <svg className="w-3 h-3" fill="currentColor" viewBox="0 0 20 20">
                        <path d="M11 3a1 1 0 100 2h2.586l-6.293 6.293a1 1 0 101.414 1.414L15 6.414V9a1 1 0 102 0V4a1 1 0 00-1-1h-5z" />
                      </svg>
                    </span>
                  </div>
                </a>
              );
            }).filter(Boolean)
          )}
        </div>
      </div>

      {/* Progress Indicator / Scrollbar Guide */}
      {following.length > 5 && (
        <div className="mt-4 flex items-center justify-center space-x-1">
          <div className="h-1 w-24 bg-gray-200 rounded-full overflow-hidden">
            <div
              className="h-full bg-gradient-to-r from-purple-400 to-purple-600 rounded-full transition-all"
              style={{
                width: `${Math.min(
                  100,
                  (5 / following.length) * 100
                )}%`,
              }}
            />
          </div>
          <span className="text-xs text-gray-500">
            {following.length > 5 ? 'Scroll to see more' : ''}
          </span>
        </div>
      )}
    </div>
  );
}
