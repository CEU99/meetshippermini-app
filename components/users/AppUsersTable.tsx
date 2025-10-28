'use client';

import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { Avatar } from '@/components/shared/Avatar';

interface User {
  fid: number;
  username: string;
  display_name?: string;
  avatar_url?: string;
  bio?: string;
  user_code?: string;
  created_at?: string;
  updated_at?: string;
}

interface AppUsersTableProps {
  users: User[];
  loading: boolean;
  searchTerm: string;
  sourceParam: string | null;
  slotParam: string | null;
  excludeFid: number | null;
}

export function AppUsersTable({ users, loading, searchTerm, sourceParam, slotParam, excludeFid }: AppUsersTableProps) {
  const router = useRouter();

  if (loading) {
    return (
      <div className="divide-y divide-gray-200">
        {[1, 2, 3, 4, 5].map((i) => (
          <div key={i} className="p-6 animate-pulse">
            <div className="flex items-center space-x-4">
              <div className="w-12 h-12 bg-gray-200 rounded-full"></div>
              <div className="flex-1">
                <div className="h-4 bg-gray-200 rounded w-1/4 mb-2"></div>
                <div className="h-3 bg-gray-200 rounded w-1/6"></div>
              </div>
              <div className="h-10 w-32 bg-gray-200 rounded"></div>
            </div>
          </div>
        ))}
      </div>
    );
  }

  if (users.length === 0) {
    return (
      <div className="p-12 text-center">
        <svg
          className="mx-auto h-12 w-12 text-gray-400"
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
        <h3 className="mt-4 text-lg font-medium text-gray-900">No users found</h3>
        <p className="mt-2 text-gray-600">
          {searchTerm
            ? `No users match "${searchTerm}". Try a different search.`
            : 'No users registered yet.'}
        </p>
      </div>
    );
  }

  return (
    <div className="overflow-x-auto">
      {/* Desktop view */}
      <table className="hidden md:table min-w-full divide-y divide-gray-200">
        <thead className="bg-[#EDE9FE]">
          <tr>
            <th className="px-6 py-3 text-left text-xs font-medium text-[#4F46E5] uppercase tracking-wider">
              User
            </th>
            <th className="px-6 py-3 text-left text-xs font-medium text-[#4F46E5] uppercase tracking-wider">
              User Code
            </th>
            <th className="px-6 py-3 text-right text-xs font-medium text-[#4F46E5] uppercase tracking-wider">
              Actions
            </th>
          </tr>
        </thead>
        <tbody className="bg-white divide-y divide-gray-200">
          {users.map((user) => (
            <tr key={user.fid} className="hover:bg-[#EDE9FE]/30 transition-colors">
              <td className="px-6 py-4">
                <div className="flex items-center gap-3">
                  <div className="flex-shrink-0">
                    <Avatar
                      src={user.avatar_url}
                      alt={user.display_name || user.username}
                      size={48}
                    />
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-semibold text-gray-900 truncate">
                      {user.display_name || user.username}
                    </p>
                    <p className="text-xs text-gray-600 truncate">@{user.username}</p>
                    <div className="mt-1 inline-flex items-center px-2 py-0.5 bg-[#EDE9FE] rounded-full">
                      <span className="text-xs font-mono text-[#4F46E5]">{user.fid}</span>
                    </div>
                  </div>
                </div>
              </td>
              <td className="px-6 py-4 whitespace-nowrap">
                {user.user_code ? (
                  <div className="text-sm text-gray-900 font-mono">{user.user_code}</div>
                ) : (
                  <span className="text-xs text-gray-400">Not set</span>
                )}
              </td>
              <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                <div className="flex items-center justify-end gap-2">
                  {sourceParam === 'create-match-meetshipper' ? (
                    <>
                      {/* View Profile disabled, Create Match active, Suggest Match disabled */}
                      <button
                        disabled
                        className="inline-flex items-center px-3 py-1.5 border-2 border-gray-300 text-gray-400 rounded-lg shadow-sm opacity-50 cursor-not-allowed text-xs font-semibold"
                      >
                        View Profile
                      </button>
                      <button
                        onClick={() => router.push(`/mini/create?targetFid=${user.fid}`)}
                        className="inline-flex items-center px-3 py-1.5 bg-[#4F46E5] text-white hover:bg-[#4338CA] rounded-lg shadow-sm transition-colors text-xs font-semibold"
                      >
                        Create Match
                      </button>
                      <button
                        disabled
                        className="inline-flex items-center px-3 py-1.5 bg-gray-300 text-white rounded-lg shadow-sm opacity-50 cursor-not-allowed text-xs font-semibold"
                      >
                        Suggest Match
                      </button>
                    </>
                  ) : sourceParam === 'suggest-match-meetshipper' ? (
                    <>
                      {/* View Profile disabled, Create Match disabled, Suggest Match active/disabled based on excludeFid */}
                      <button
                        disabled
                        className="inline-flex items-center px-3 py-1.5 border-2 border-gray-300 text-gray-400 rounded-lg shadow-sm opacity-50 cursor-not-allowed text-xs font-semibold"
                      >
                        View Profile
                      </button>
                      <button
                        disabled
                        className="inline-flex items-center px-3 py-1.5 bg-gray-300 text-white rounded-lg shadow-sm opacity-50 cursor-not-allowed text-xs font-semibold"
                      >
                        Create Match
                      </button>
                      {excludeFid && user.fid === excludeFid ? (
                        <button
                          disabled
                          className="inline-flex items-center px-3 py-1.5 bg-gray-300 text-white rounded-lg shadow-sm opacity-50 cursor-not-allowed text-xs font-semibold"
                          title="User already selected"
                        >
                          Suggest Match
                        </button>
                      ) : (
                        <button
                          onClick={() => {
                            const params = new URLSearchParams({ fid: user.fid.toString(), source: 'meetshipper' });
                            if (slotParam) params.append('slot', slotParam);
                            router.push(`/mini/suggest?${params.toString()}`);
                          }}
                          className="inline-flex items-center px-3 py-1.5 bg-[#4F46E5] text-white hover:bg-[#4338CA] rounded-lg shadow-sm transition-colors text-xs font-semibold"
                        >
                          Suggest Match
                        </button>
                      )}
                    </>
                  ) : sourceParam === 'create-match-farcaster' || sourceParam === 'suggest-match-farcaster' ? (
                    <>
                      {/* All buttons disabled for Farcaster sources */}
                      <button
                        disabled
                        className="inline-flex items-center px-3 py-1.5 border-2 border-gray-300 text-gray-400 rounded-lg shadow-sm opacity-50 cursor-not-allowed text-xs font-semibold"
                      >
                        View Profile
                      </button>
                      <button
                        disabled
                        className="inline-flex items-center px-3 py-1.5 bg-gray-300 text-white rounded-lg shadow-sm opacity-50 cursor-not-allowed text-xs font-semibold"
                      >
                        Create Match
                      </button>
                      <button
                        disabled
                        className="inline-flex items-center px-3 py-1.5 bg-gray-300 text-white rounded-lg shadow-sm opacity-50 cursor-not-allowed text-xs font-semibold"
                      >
                        Suggest Match
                      </button>
                    </>
                  ) : (
                    <>
                      {/* Default: View Profile active, others disabled */}
                      <a
                        href={user.username ? `https://warpcast.com/${user.username}` : `https://warpcast.com/~/profiles/${user.fid}`}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="inline-flex items-center px-3 py-1.5 border-2 border-[#4F46E5] text-[#4F46E5] hover:bg-[#4F46E5] hover:text-white rounded-lg transition-colors shadow-sm text-xs font-semibold"
                      >
                        View Profile
                      </a>
                      <button
                        disabled
                        className="inline-flex items-center px-3 py-1.5 bg-gray-300 text-white rounded-lg shadow-sm opacity-50 cursor-not-allowed text-xs font-semibold"
                        title="Coming soon"
                      >
                        Create Match
                      </button>
                      <button
                        disabled
                        className="inline-flex items-center px-3 py-1.5 bg-gray-300 text-white rounded-lg shadow-sm opacity-50 cursor-not-allowed text-xs font-semibold"
                        title="Coming soon"
                      >
                        Suggest Match
                      </button>
                    </>
                  )}
                </div>
              </td>
            </tr>
          ))}
        </tbody>
      </table>

      {/* Mobile view */}
      <div className="md:hidden divide-y divide-gray-200">
        {users.map((user) => (
          <div key={user.fid} className="p-4 hover:bg-[#EDE9FE]/30 transition-colors">
            <div className="flex items-start space-x-3">
              <div className="flex-shrink-0">
                <Avatar
                  src={user.avatar_url}
                  alt={user.display_name || user.username}
                  size={48}
                />
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-sm font-semibold text-gray-900 truncate">
                  {user.display_name || user.username}
                </p>
                <p className="text-xs text-gray-600 truncate">@{user.username}</p>
                <div className="mt-1 inline-flex items-center px-2 py-0.5 bg-[#EDE9FE] rounded-full">
                  <span className="text-xs font-mono text-[#4F46E5]">{user.fid}</span>
                </div>
                {user.user_code && (
                  <div className="mt-2 text-xs text-gray-600">
                    Code: <span className="font-mono text-gray-900">{user.user_code}</span>
                  </div>
                )}
                <div className="mt-3 flex flex-wrap items-center gap-2">
                  {sourceParam === 'create-match-meetshipper' ? (
                    <>
                      <button
                        disabled
                        className="inline-flex items-center px-3 py-1.5 border-2 border-gray-300 text-gray-400 rounded-lg shadow-sm opacity-50 cursor-not-allowed text-xs font-semibold"
                      >
                        View Profile
                      </button>
                      <button
                        onClick={() => router.push(`/mini/create?targetFid=${user.fid}`)}
                        className="inline-flex items-center px-3 py-1.5 bg-[#4F46E5] text-white hover:bg-[#4338CA] rounded-lg shadow-sm transition-colors text-xs font-semibold"
                      >
                        Create Match
                      </button>
                      <button
                        disabled
                        className="inline-flex items-center px-3 py-1.5 bg-gray-300 text-white rounded-lg shadow-sm opacity-50 cursor-not-allowed text-xs font-semibold"
                      >
                        Suggest Match
                      </button>
                    </>
                  ) : sourceParam === 'suggest-match-meetshipper' ? (
                    <>
                      <button
                        disabled
                        className="inline-flex items-center px-3 py-1.5 border-2 border-gray-300 text-gray-400 rounded-lg shadow-sm opacity-50 cursor-not-allowed text-xs font-semibold"
                      >
                        View Profile
                      </button>
                      <button
                        disabled
                        className="inline-flex items-center px-3 py-1.5 bg-gray-300 text-white rounded-lg shadow-sm opacity-50 cursor-not-allowed text-xs font-semibold"
                      >
                        Create Match
                      </button>
                      {excludeFid && user.fid === excludeFid ? (
                        <button
                          disabled
                          className="inline-flex items-center px-3 py-1.5 bg-gray-300 text-white rounded-lg shadow-sm opacity-50 cursor-not-allowed text-xs font-semibold"
                          title="User already selected"
                        >
                          Suggest Match
                        </button>
                      ) : (
                        <button
                          onClick={() => {
                            const params = new URLSearchParams({ fid: user.fid.toString(), source: 'meetshipper' });
                            if (slotParam) params.append('slot', slotParam);
                            router.push(`/mini/suggest?${params.toString()}`);
                          }}
                          className="inline-flex items-center px-3 py-1.5 bg-[#4F46E5] text-white hover:bg-[#4338CA] rounded-lg shadow-sm transition-colors text-xs font-semibold"
                        >
                          Suggest Match
                        </button>
                      )}
                    </>
                  ) : sourceParam === 'create-match-farcaster' || sourceParam === 'suggest-match-farcaster' ? (
                    <>
                      <button
                        disabled
                        className="inline-flex items-center px-3 py-1.5 border-2 border-gray-300 text-gray-400 rounded-lg shadow-sm opacity-50 cursor-not-allowed text-xs font-semibold"
                      >
                        View Profile
                      </button>
                      <button
                        disabled
                        className="inline-flex items-center px-3 py-1.5 bg-gray-300 text-white rounded-lg shadow-sm opacity-50 cursor-not-allowed text-xs font-semibold"
                      >
                        Create Match
                      </button>
                      <button
                        disabled
                        className="inline-flex items-center px-3 py-1.5 bg-gray-300 text-white rounded-lg shadow-sm opacity-50 cursor-not-allowed text-xs font-semibold"
                      >
                        Suggest Match
                      </button>
                    </>
                  ) : (
                    <>
                      <a
                        href={user.username ? `https://warpcast.com/${user.username}` : `https://warpcast.com/~/profiles/${user.fid}`}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="inline-flex items-center px-3 py-1.5 border-2 border-[#4F46E5] text-[#4F46E5] hover:bg-[#4F46E5] hover:text-white rounded-lg transition-colors shadow-sm text-xs font-semibold"
                      >
                        View Profile
                      </a>
                      <button
                        disabled
                        className="inline-flex items-center px-3 py-1.5 bg-gray-300 text-white rounded-lg shadow-sm opacity-50 cursor-not-allowed text-xs font-semibold"
                        title="Coming soon"
                      >
                        Create Match
                      </button>
                      <button
                        disabled
                        className="inline-flex items-center px-3 py-1.5 bg-gray-300 text-white rounded-lg shadow-sm opacity-50 cursor-not-allowed text-xs font-semibold"
                        title="Coming soon"
                      >
                        Suggest Match
                      </button>
                    </>
                  )}
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
