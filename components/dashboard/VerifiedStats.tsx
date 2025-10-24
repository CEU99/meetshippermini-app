'use client';

import { useEffect, useState } from 'react';
import { motion } from 'framer-motion';
import { useFarcasterAuth } from '@/components/providers/FarcasterAuthProvider';

// ============================================================================
// Types
// ============================================================================
interface VerifiedUser {
  username: string;
  walletAddress: string;
  createdAt: string;
}

interface VerifiedStatsData {
  totalCount: number;
  recentUsers: VerifiedUser[];
}

// ============================================================================
// VerifiedStats Component
// ============================================================================
export default function VerifiedStats() {
  const { user } = useFarcasterAuth();
  const [stats, setStats] = useState<VerifiedStatsData | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [hoveredUser, setHoveredUser] = useState<string | null>(null);

  // ==========================================================================
  // Fetch Stats (USER-SCOPED)
  // ==========================================================================
  const fetchStats = async () => {
    if (!user?.fid) {
      console.log('[VerifiedStats] No user FID available, skipping fetch');
      setIsLoading(false);
      return;
    }

    try {
      console.log('[VerifiedStats] Fetching verified users statistics for FID:', user.fid);
      setIsLoading(true);
      const response = await fetch(`/api/stats/verified?fid=${user.fid}`);

      if (!response.ok) {
        throw new Error('Failed to fetch verified stats');
      }

      const data = await response.json();
      console.log('[VerifiedStats] Stats fetched:', data);

      if (data.success) {
        setStats(data.data);
      } else {
        throw new Error(data.error || 'Failed to load stats');
      }
    } catch (err: any) {
      console.error('[VerifiedStats] Error fetching stats:', err);
      setError(err.message || 'Failed to load verified users statistics');
    } finally {
      setIsLoading(false);
    }
  };

  // Initial fetch - wait for user to be loaded
  useEffect(() => {
    if (user) {
      fetchStats();
    }
  }, [user]);

  // ==========================================================================
  // Listen for "attestation-complete" event
  // ==========================================================================
  useEffect(() => {
    const handleRefetch = () => {
      console.log('🔄 Refetching VerifiedStats after attestation complete...');
      fetchStats();
    };

    window.addEventListener('attestation-complete', handleRefetch);
    return () => window.removeEventListener('attestation-complete', handleRefetch);
  }, []);

  // ==========================================================================
  // Helpers
  // ==========================================================================
  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    const now = new Date();
    const diffInSeconds = Math.floor((now.getTime() - date.getTime()) / 1000);

    if (diffInSeconds < 60) return 'Just now';
    if (diffInSeconds < 3600) return `${Math.floor(diffInSeconds / 60)}m ago`;
    if (diffInSeconds < 86400) return `${Math.floor(diffInSeconds / 3600)}h ago`;
    if (diffInSeconds < 604800) return `${Math.floor(diffInSeconds / 86400)}d ago`;
    return date.toLocaleDateString();
  };

  const formatAddress = (addr: string) => `${addr.slice(0, 6)}...${addr.slice(-4)}`;

  // ==========================================================================
  // Motion Variants (Type-safe)
  // ==========================================================================
  const containerVariants = {
    hidden: { opacity: 0, y: 20 },
    visible: {
      opacity: 1,
      y: 0,
      transition: {
        duration: 0.5,
        ease: 'easeOut' as any,
        staggerChildren: 0.1,
      },
    },
  };

  const itemVariants = {
    hidden: { opacity: 0, x: -20 },
    visible: {
      opacity: 1,
      x: 0,
      transition: { duration: 0.3, ease: 'easeOut' as any },
    },
  };

  const getDisplayUsers = () => stats?.recentUsers || [];

  // ==========================================================================
  // Render
  // ==========================================================================
  return (
    <motion.div
      initial="hidden"
      animate="visible"
      variants={containerVariants}
      className="bg-gradient-to-br from-green-50 to-emerald-50 border border-green-200 rounded-xl p-6 shadow-sm hover:shadow-md transition-shadow duration-300"
    >
      {/* Header */}
      <div className="flex items-center gap-3 mb-6">
        <div className="p-2.5 bg-green-100 rounded-lg">
          <svg
            className="w-6 h-6 text-green-600"
            fill="currentColor"
            viewBox="0 0 20 20"
          >
            <path
              fillRule="evenodd"
              d="M6.267 3.455a3.066 3.066 0 001.745-.723 3.066 3.066 0 013.976 0 3.066 3.066 0 001.745.723 3.066 3.066 0 012.812 2.812c.051.643.304 1.254.723 1.745a3.066 3.066 0 010 3.976 3.066 3.066 0 00-.723 1.745 3.066 3.066 0 01-2.812 2.812 3.066 3.066 0 00-1.745.723 3.066 3.066 0 01-3.976 0 3.066 3.066 0 00-1.745-.723 3.066 3.066 0 01-2.812-2.812 3.066 3.066 0 00-.723-1.745 3.066 3.066 0 010-3.976 3.066 3.066 0 00.723-1.745 3.066 3.066 0 012.812-2.812zm7.44 5.252a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
              clipRule="evenodd"
            />
          </svg>
        </div>
        <div>
          <h3 className="text-lg font-semibold text-gray-900">Verified Users</h3>
          <p className="text-sm text-gray-600">On-chain attestations</p>
        </div>
      </div>

      {/* Loading */}
      {isLoading && (
        <div className="flex items-center justify-center py-8 text-green-600">
          <svg
            className="animate-spin h-5 w-5 mr-2"
            xmlns="http://www.w3.org/2000/svg"
            fill="none"
            viewBox="0 0 24 24"
          >
            <circle
              className="opacity-25"
              cx="12"
              cy="12"
              r="10"
              stroke="currentColor"
              strokeWidth="4"
            ></circle>
            <path
              className="opacity-75"
              fill="currentColor"
              d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
            ></path>
          </svg>
          <span className="text-sm font-medium">Loading stats...</span>
        </div>
      )}

      {/* Error */}
      {error && !isLoading && (
        <div className="flex items-center gap-2 p-4 bg-red-50 border border-red-200 rounded-lg">
          <svg
            className="w-5 h-5 text-red-600"
            fill="currentColor"
            viewBox="0 0 20 20"
          >
            <path
              fillRule="evenodd"
              d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z"
              clipRule="evenodd"
            />
          </svg>
          <span className="text-sm text-red-700">{error}</span>
        </div>
      )}

      {/* Stats */}
      {stats && !isLoading && !error && (
        <div className="space-y-6">
          {/* Total Count */}
          <motion.div
            variants={itemVariants}
            className="text-center py-4 bg-white rounded-lg border border-green-100"
          >
            <div className="text-4xl font-bold text-green-600 mb-1">
              {stats.totalCount}
            </div>
            <div className="text-sm text-gray-600">Total Verified</div>
          </motion.div>

          {/* Recent Users */}
          <div>
            <h4 className="text-sm font-semibold text-gray-700 mb-3 px-1">
              Recently Verified
            </h4>
            <div className="space-y-2">
              {getDisplayUsers().map((user, index) => (
                <motion.div
                  key={`${user.walletAddress}-${user.createdAt}`}
                  variants={itemVariants}
                  className={`relative flex items-center justify-between p-3 bg-white rounded-lg border border-green-100 hover:border-green-300 hover:shadow-sm transition-all duration-200 cursor-pointer ${
                    index >= 3 ? 'hidden sm:flex' : ''
                  }`}
                  onMouseEnter={() => setHoveredUser(user.walletAddress)}
                  onMouseLeave={() => setHoveredUser(null)}
                >
                  <div className="flex items-center gap-3 flex-1 min-w-0">
                    <div className="flex-shrink-0 w-6 h-6 flex items-center justify-center bg-green-100 text-green-700 rounded-full text-xs font-semibold">
                      {index + 1}
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="text-sm font-medium text-gray-900 truncate">
                        {user.username}
                      </div>
                      <div className="text-xs text-gray-500">
                        {formatDate(user.createdAt)}
                      </div>
                    </div>
                    <div className="flex-shrink-0">
                      <svg
                        className="w-5 h-5 text-green-600"
                        fill="currentColor"
                        viewBox="0 0 20 20"
                      >
                        <path
                          fillRule="evenodd"
                          d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
                          clipRule="evenodd"
                        />
                      </svg>
                    </div>
                  </div>

                  {hoveredUser === user.walletAddress && (
                    <motion.div
                      initial={{ opacity: 0, y: 5 }}
                      animate={{ opacity: 1, y: 0 }}
                      exit={{ opacity: 0, y: 5 }}
                      transition={{ duration: 0.2 }}
                      className="absolute -top-12 left-1/2 transform -translate-x-1/2 px-3 py-2 bg-gray-900 text-white text-xs rounded-lg whitespace-nowrap shadow-xl z-10"
                    >
                      <span className="font-mono">{formatAddress(user.walletAddress)}</span>
                      <div className="absolute top-full left-1/2 transform -translate-x-1/2 -mt-1">
                        <div className="border-[5px] border-transparent border-t-gray-900"></div>
                      </div>
                    </motion.div>
                  )}
                </motion.div>
              ))}
            </div>

            {stats.recentUsers.length > 3 && (
              <p className="text-xs text-gray-500 text-center mt-3 sm:hidden">
                Showing top 3 · {stats.recentUsers.length - 3} more on desktop
              </p>
            )}
          </div>
        </div>
      )}
    </motion.div>
  );
}