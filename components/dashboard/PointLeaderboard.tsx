'use client';

import { useEffect, useState } from 'react';
import Image from 'next/image';
import { motion } from 'framer-motion';

interface LeaderboardEntry {
  rank: number;
  fid: number;
  username: string;
  displayName: string | null;
  avatarUrl: string | null;
  points: number;
  level: number;
}

export default function PointLeaderboard() {
  const [leaderboard, setLeaderboard] = useState<LeaderboardEntry[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetchLeaderboard();
  }, []);

  const fetchLeaderboard = async () => {
    try {
      setIsLoading(true);
      const res = await fetch('/api/stats/leaderboard');
      const json = await res.json();

      if (json.success) {
        setLeaderboard(json.data);
      } else {
        setError(json.error || 'Failed to fetch leaderboard');
      }
    } catch (e: any) {
      setError(e.message);
    } finally {
      setIsLoading(false);
    }
  };

  // Get rank styling (gold, silver, bronze for top 3)
  const getRankStyle = (rank: number) => {
    switch (rank) {
      case 1:
        return 'from-yellow-50/90 to-amber-50/90 border-yellow-300/60 hover:shadow-yellow-200/50';
      case 2:
        return 'from-gray-50/90 to-slate-50/90 border-gray-300/60 hover:shadow-gray-200/50';
      case 3:
        return 'from-orange-50/90 to-amber-50/90 border-orange-300/60 hover:shadow-orange-200/50';
      default:
        return 'from-white/70 to-purple-50/50 border-purple-100/40 hover:shadow-purple-100/50';
    }
  };

  // Get rank emoji
  const getRankEmoji = (rank: number) => {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return rank;
    }
  };

  if (isLoading) {
    return (
      <div className="backdrop-blur-xl bg-gradient-to-br from-purple-100/80 to-blue-100/80 rounded-2xl border border-purple-200/60 shadow-lg p-6">
        <div className="text-center mb-4">
          <h3 className="text-sm font-bold text-purple-700 uppercase tracking-wider flex items-center justify-center gap-2">
            <span>🏆</span> Point Leaderboard
          </h3>
        </div>
        <div className="flex flex-col items-center justify-center gap-3 py-8">
          <div className="w-5 h-5 border-2 border-purple-400 border-t-transparent rounded-full animate-spin" />
          <span className="text-sm text-gray-600 font-medium">Loading leaderboard...</span>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="backdrop-blur-xl bg-gradient-to-br from-purple-100/80 to-blue-100/80 rounded-2xl border border-purple-200/60 shadow-lg p-6">
        <div className="text-center mb-4">
          <h3 className="text-sm font-bold text-purple-700 uppercase tracking-wider flex items-center justify-center gap-2">
            <span>🏆</span> Point Leaderboard
          </h3>
        </div>
        <div className="backdrop-blur-xl bg-red-50/60 rounded-xl border border-red-200/60 p-4">
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 rounded-full bg-red-100 flex items-center justify-center">
              <svg className="w-4 h-4 text-red-600" fill="currentColor" viewBox="0 0 20 20">
                <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clipRule="evenodd" />
              </svg>
            </div>
            <span className="text-xs text-red-700 font-medium">{error}</span>
          </div>
        </div>
      </div>
    );
  }

  if (leaderboard.length === 0) {
    return (
      <div className="backdrop-blur-xl bg-gradient-to-br from-purple-100/80 to-blue-100/80 rounded-2xl border border-purple-200/60 shadow-lg p-6">
        <div className="text-center mb-4">
          <h3 className="text-sm font-bold text-purple-700 uppercase tracking-wider flex items-center justify-center gap-2">
            <span>🏆</span> Point Leaderboard
          </h3>
        </div>
        <div className="text-center py-8">
          <span className="text-sm text-gray-500">No data available yet.</span>
        </div>
      </div>
    );
  }

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.6, ease: [0.22, 1, 0.36, 1] }}
      className="backdrop-blur-xl bg-gradient-to-br from-purple-100/80 to-blue-100/80 rounded-2xl border border-purple-200/60 shadow-lg hover:shadow-xl transition-all duration-300 p-5"
    >
      {/* Header */}
      <div className="text-center mb-4">
        <h3 className="text-sm font-bold text-purple-700 uppercase tracking-wider flex items-center justify-center gap-2">
          <span>🏆</span> Point Leaderboard
        </h3>
        <p className="text-xs text-purple-600 mt-1">Top 5 Users by Points</p>
      </div>

      {/* Leaderboard List */}
      <div className="space-y-2">
        {leaderboard.slice(0, 5).map((entry, index) => (
          <motion.div
            key={entry.fid}
            initial={{ opacity: 0, x: -20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.4, delay: index * 0.05 }}
            className={`backdrop-blur-xl bg-gradient-to-r ${getRankStyle(entry.rank)} rounded-xl border shadow-sm hover:shadow-lg transition-all duration-200 p-3 group`}
          >
            <div className="flex items-center gap-3">
              {/* Rank */}
              <div className="flex-shrink-0 w-8 h-8 rounded-lg bg-white/60 backdrop-blur-sm flex items-center justify-center font-bold text-sm">
                {getRankEmoji(entry.rank)}
              </div>

              {/* Avatar */}
              {entry.avatarUrl ? (
                <div className="relative flex-shrink-0">
                  <div className="absolute inset-0 bg-gradient-to-br from-purple-400 to-blue-400 rounded-full blur opacity-20 group-hover:opacity-40 transition-opacity duration-300"></div>
                  <Image
                    src={entry.avatarUrl}
                    alt={entry.username}
                    width={36}
                    height={36}
                    className="rounded-full relative z-10 ring-2 ring-white/50"
                  />
                </div>
              ) : (
                <div className="flex-shrink-0 w-9 h-9 rounded-full bg-gradient-to-br from-purple-200 to-blue-200 flex items-center justify-center">
                  <span className="text-sm font-semibold text-purple-700">
                    {entry.username.charAt(0).toUpperCase()}
                  </span>
                </div>
              )}

              {/* User Info */}
              <div className="flex-1 min-w-0">
                <p className="text-sm font-semibold text-gray-900 truncate">
                  @{entry.username}
                </p>
                <p className="text-xs text-gray-600">
                  Level {entry.level}
                </p>
              </div>

              {/* Points */}
              <div className="flex-shrink-0 text-right">
                <p className="text-sm font-bold bg-gradient-to-r from-purple-700 to-blue-700 bg-clip-text text-transparent">
                  {entry.points.toLocaleString()}
                </p>
                <p className="text-xs text-gray-500">pts</p>
              </div>
            </div>
          </motion.div>
        ))}
      </div>

      {/* Footer Note */}
      <div className="mt-4 pt-3 border-t border-purple-200/40">
        <p className="text-xs text-center text-purple-600/80">
          Earn points through achievements and activities
        </p>
      </div>
    </motion.div>
  );
}
