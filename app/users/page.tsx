'use client';

import { useEffect, useState } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { useFarcasterAuth } from '@/components/providers/FarcasterAuthProvider';
import { Navigation } from '@/components/shared/Navigation';
import Link from 'next/link';
import { apiClient } from '@/lib/api-client';
import { supabase } from '@/lib/supabase';
import { Suspense } from 'react';
import { AppUsersTable } from '@/components/users/AppUsersTable';
import { FarcasterFollowersTable } from '@/components/users/FarcasterFollowersTable';

interface User {
  fid: number;
  username: string;
  display_name?: string;
  avatar_url?: string;
  bio?: string;
  user_code?: string;
  has_joined_meetshipper?: boolean;
  created_at?: string;
  updated_at?: string;
}

interface UsersResponse {
  users: User[];
  pagination: {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
  };
}

function UsersPageContent() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const { isAuthenticated, loading: authLoading } = useFarcasterAuth();
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [debouncedSearch, setDebouncedSearch] = useState('');
  const [page, setPage] = useState(1);
  const [pagination, setPagination] = useState({
    page: 1,
    limit: 20,
    total: 0,
    totalPages: 0,
  });
  const [mounted, setMounted] = useState(false);

  // Handle client-side hydration
  useEffect(() => {
    setMounted(true);
  }, []);

  // Get slot parameter from URL
  const slotParam = searchParams.get('slot');
  // Get source parameter from URL (app-users or farcaster)
  const sourceParam = searchParams.get('source');
  // Get excludeFid parameter to disable already-selected user
  const excludeFidParam = searchParams.get('excludeFid') ? parseInt(searchParams.get('excludeFid')!) : null;
  // Get showAll parameter for admin debugging
  const showAll = searchParams.get('showAll') === 'true';

  // Redirect if not authenticated
  useEffect(() => {
    if (!authLoading && !isAuthenticated) {
      router.push('/');
    }
  }, [isAuthenticated, authLoading, router]);

  // Debounce search input
  useEffect(() => {
    const timer = setTimeout(() => {
      setDebouncedSearch(searchTerm);
      setPage(1); // Reset to page 1 on new search
    }, 300);

    return () => clearTimeout(timer);
  }, [searchTerm]);

  // Fetch users
  useEffect(() => {
    if (isAuthenticated) {
      fetchUsers();
    }
  }, [isAuthenticated, page, debouncedSearch, showAll]);

  // Realtime subscription for new users
  useEffect(() => {
    if (!isAuthenticated) return;

    // Subscribe to INSERT events on users table
    const channel = supabase
      .channel('users_changes')
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'users',
        },
        (payload) => {
          console.log('[Realtime] New user inserted:', payload.new);
          // Refresh the list to include the new user
          fetchUsers();
        }
      )
      .on(
        'postgres_changes',
        {
          event: 'UPDATE',
          schema: 'public',
          table: 'users',
        },
        (payload) => {
          console.log('[Realtime] User updated:', payload.new);
          // Update the specific user in the list
          setUsers((prevUsers) =>
            prevUsers.map((user) =>
              user.fid === (payload.new as User).fid ? (payload.new as User) : user
            )
          );
        }
      )
      .subscribe();

    // Cleanup subscription on unmount
    return () => {
      supabase.removeChannel(channel);
    };
  }, [isAuthenticated]);

  const fetchUsers = async () => {
    setLoading(true);
    setError(null);

    try {
      const params = new URLSearchParams({
        page: page.toString(),
        limit: '20',
      });

      if (debouncedSearch) {
        params.append('search', debouncedSearch);
      }

      if (showAll) {
        params.append('showAll', 'true');
      }

      const data = await apiClient.get<UsersResponse>(`/api/users?${params.toString()}`);

      setUsers(data.users);
      setPagination(data.pagination);
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Unknown error';
      console.error('Error fetching users:', err);
      setError(errorMessage || 'Failed to load users');
    } finally {
      setLoading(false);
    }
  };

  // Wait for client-side hydration before rendering
  if (!mounted || authLoading) {
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
    <div className="min-h-screen bg-gradient-to-br from-[#EDE9FE] to-white">
      <Navigation />

      <div className="max-w-[1600px] mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Header */}
        <div className="mb-8 text-center">
          <h1 className="text-3xl font-bold text-gray-900">Explore Users</h1>
          <p className="mt-2 text-gray-600">
            Browse registered users and connect with your Farcaster network
          </p>
        </div>

        {/* Slot Selection Banner */}
        {slotParam && (slotParam === 'A' || slotParam === 'B') && (
          <div className="mb-6 bg-purple-50 border border-purple-200 rounded-lg p-4">
            <div className="flex items-start gap-3">
              <svg
                className="w-5 h-5 text-purple-600 flex-shrink-0 mt-0.5"
                fill="currentColor"
                viewBox="0 0 20 20"
              >
                <path
                  fillRule="evenodd"
                  d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z"
                  clipRule="evenodd"
                />
              </svg>
              <div className="flex-1">
                <h3 className="text-sm font-semibold text-purple-900">
                  Selecting User {slotParam} for Suggest Match
                </h3>
                <p className="text-sm text-purple-800 mt-1">
                  Click <strong className="font-semibold">+ Suggest Match</strong> on any profile
                  below to select them as User {slotParam}. You'll be redirected back to the
                  Suggest Match page.
                </p>
              </div>
              <Link
                href="/mini/suggest"
                className="text-sm text-purple-600 hover:text-purple-800 underline whitespace-nowrap"
              >
                Cancel
              </Link>
            </div>
          </div>
        )}

        {/* Two-Column Layout */}
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
          {/* Left Column - App Users */}
          <div className="lg:col-span-7">
            <div className="bg-white rounded-xl shadow-lg border border-gray-200 overflow-hidden">
              {/* Section Header */}
              <div className="bg-gradient-to-r from-[#4F46E5] to-[#6366F1] px-6 py-4">
                <h2 className="text-lg font-semibold text-white">App Users</h2>
                <p className="text-sm text-white/80 mt-1">
                  Registered MeetShipper community members
                </p>
              </div>

              {/* Info Banner */}
              <div className={`px-6 py-3 border-b ${
                showAll
                  ? 'bg-orange-50 border-orange-100'
                  : 'bg-blue-50 border-blue-100'
              }`}>
                <div className="flex items-start gap-2">
                  <svg
                    className={`w-4 h-4 flex-shrink-0 mt-0.5 ${
                      showAll ? 'text-orange-600' : 'text-blue-600'
                    }`}
                    fill="currentColor"
                    viewBox="0 0 20 20"
                  >
                    <path
                      fillRule="evenodd"
                      d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z"
                      clipRule="evenodd"
                    />
                  </svg>
                  <p className={`text-xs ${showAll ? 'text-orange-800' : 'text-blue-800'}`}>
                    {showAll
                      ? '🔧 Admin Mode: Showing ALL users (including external Farcaster users). Remove ?showAll=true to see only registered members.'
                      : 'Showing only registered MeetShipper members. External Farcaster users are excluded.'}
                  </p>
                </div>
              </div>

              {/* Search Bar */}
              <div className="p-6 border-b border-gray-200 bg-[#EDE9FE]/30">
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

                {/* Results count */}
                <div className="mt-3 text-sm text-gray-600">
                  {loading ? (
                    <span className="flex items-center">
                      <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-[#4F46E5] mr-2"></div>
                      Searching...
                    </span>
                  ) : (
                    <span>
                      Showing <span className="font-semibold text-[#4F46E5]">{users.length}</span> of{' '}
                      <span className="font-semibold text-[#4F46E5]">{pagination.total}</span> users
                      {debouncedSearch && ` matching "${debouncedSearch}"`}
                    </span>
                  )}
                </div>
              </div>

              {/* Error State */}
              {error && (
                <div className="mx-6 mt-4 bg-red-50 border border-red-200 rounded-lg p-4">
                  <p className="text-red-800">{error}</p>
                  <button
                    onClick={fetchUsers}
                    className="mt-2 text-sm text-red-600 hover:text-red-800 underline font-medium"
                  >
                    Try again
                  </button>
                </div>
              )}

              {/* Users Table */}
              <div className="max-h-[600px] overflow-y-auto">
                <AppUsersTable users={users} loading={loading} searchTerm={debouncedSearch} sourceParam={sourceParam} slotParam={slotParam} excludeFid={excludeFidParam} />
              </div>
            </div>

            {/* Pagination */}
            {!loading && pagination.totalPages > 1 && (
              <div className="mt-6 bg-white rounded-xl shadow-lg border border-gray-200 px-6 py-4">
                <div className="flex-1 flex justify-between sm:hidden">
                  <button
                    onClick={() => setPage((p) => Math.max(1, p - 1))}
                    disabled={page === 1}
                    className="relative inline-flex items-center px-4 py-2 border-2 border-[#4F46E5] text-sm font-medium rounded-lg text-[#4F46E5] bg-white hover:bg-[#EDE9FE] disabled:opacity-50 disabled:cursor-not-allowed transition-all"
                  >
                    Previous
                  </button>
                  <button
                    onClick={() => setPage((p) => Math.min(pagination.totalPages, p + 1))}
                    disabled={page === pagination.totalPages}
                    className="ml-3 relative inline-flex items-center px-4 py-2 border-2 border-[#4F46E5] text-sm font-medium rounded-lg text-[#4F46E5] bg-white hover:bg-[#EDE9FE] disabled:opacity-50 disabled:cursor-not-allowed transition-all"
                  >
                    Next
                  </button>
                </div>
                <div className="hidden sm:flex-1 sm:flex sm:items-center sm:justify-between">
                  <div>
                    <p className="text-sm text-gray-700">
                      Showing page <span className="font-semibold text-[#4F46E5]">{page}</span> of{' '}
                      <span className="font-semibold text-[#4F46E5]">{pagination.totalPages}</span> ({pagination.total} total users)
                    </p>
                  </div>
                  <div>
                    <nav className="relative z-0 inline-flex rounded-lg shadow-sm gap-1">
                      <button
                        onClick={() => setPage((p) => Math.max(1, p - 1))}
                        disabled={page === 1}
                        className="relative inline-flex items-center px-3 py-2 rounded-lg border-2 border-[#4F46E5] bg-white text-sm font-medium text-[#4F46E5] hover:bg-[#EDE9FE] disabled:opacity-50 disabled:cursor-not-allowed transition-all"
                      >
                        <span className="sr-only">Previous</span>
                        <svg className="h-5 w-5" fill="currentColor" viewBox="0 0 20 20">
                          <path fillRule="evenodd" d="M12.707 5.293a1 1 0 010 1.414L9.414 10l3.293 3.293a1 1 0 01-1.414 1.414l-4-4a1 1 0 010-1.414l4-4a1 1 0 011.414 0z" clipRule="evenodd" />
                        </svg>
                      </button>

                      {/* Page numbers */}
                      {Array.from({ length: Math.min(5, pagination.totalPages) }, (_, i) => {
                        let pageNum;
                        if (pagination.totalPages <= 5) {
                          pageNum = i + 1;
                        } else if (page <= 3) {
                          pageNum = i + 1;
                        } else if (page >= pagination.totalPages - 2) {
                          pageNum = pagination.totalPages - 4 + i;
                        } else {
                          pageNum = page - 2 + i;
                        }
                        return (
                          <button
                            key={pageNum}
                            onClick={() => setPage(pageNum)}
                            className={`relative inline-flex items-center px-4 py-2 border-2 text-sm font-medium rounded-lg transition-all ${
                              page === pageNum
                                ? 'z-10 bg-[#4F46E5] border-[#4F46E5] text-white shadow-md'
                                : 'bg-white border-gray-200 text-gray-700 hover:bg-[#EDE9FE] hover:border-[#4F46E5]'
                            }`}
                          >
                            {pageNum}
                          </button>
                        );
                      })}

                      <button
                        onClick={() => setPage((p) => Math.min(pagination.totalPages, p + 1))}
                        disabled={page === pagination.totalPages}
                        className="relative inline-flex items-center px-3 py-2 rounded-lg border-2 border-[#4F46E5] bg-white text-sm font-medium text-[#4F46E5] hover:bg-[#EDE9FE] disabled:opacity-50 disabled:cursor-not-allowed transition-all"
                      >
                        <span className="sr-only">Next</span>
                        <svg className="h-5 w-5" fill="currentColor" viewBox="0 0 20 20">
                          <path fillRule="evenodd" d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z" clipRule="evenodd" />
                        </svg>
                      </button>
                    </nav>
                  </div>
                </div>
              </div>
            )}
          </div>

          {/* Right Column - Farcaster Followers */}
          <div className="lg:col-span-5">
            <div className="bg-white rounded-xl shadow-lg border border-gray-200 overflow-hidden sticky top-8">
              {/* Section Header */}
              <div className="bg-gradient-to-r from-[#6366F1] to-[#8B5CF6] px-6 py-4">
                <h2 className="text-lg font-semibold text-white">Match With Your Farcaster Followers</h2>
                <p className="text-sm text-white/80 mt-1">
                  Connect your Farcaster network for better matches
                </p>
              </div>

              {/* Content */}
              <div className="p-6">
                <FarcasterFollowersTable loading={false} sourceParam={sourceParam} slotParam={slotParam} excludeFid={excludeFidParam} />
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

export default function UsersPage() {
  return (
    <Suspense
      fallback={
        <div className="min-h-screen flex items-center justify-center">
          <div className="text-center">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-purple-600 mx-auto"></div>
            <p className="mt-4 text-gray-600">Loading...</p>
          </div>
        </div>
      }
    >
      <UsersPageContent />
    </Suspense>
  );
}
