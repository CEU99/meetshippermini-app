'use client';

import { useEffect, useState } from 'react';
import { motion } from 'framer-motion';
import { useFarcasterAuth } from '@/components/providers/FarcasterAuthProvider';

interface VerifiedUser {
  username: string;
  walletAddress: string;
  createdAt: string;
}

interface VerifiedStatsData {
  totalCount: number;
  recentUsers: VerifiedUser[];
}

export default function VerifiedStats() {
  const { user, loading: authLoading } = useFarcasterAuth();
  const [stats, setStats] = useState<VerifiedStatsData | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchStats = async () => {
    if (!user?.fid) return;
    try {
      setIsLoading(true);
      const res = await fetch(`/api/stats/verified?fid=${user.fid}`);
      const data = await res.json();
      if (data.success) setStats(data.data);
      else setError(data.error || 'Failed to load stats');
    } catch (e: any) {
      setError(e.message);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    if (!authLoading && user?.fid) fetchStats();
  }, [authLoading, user]);

  if (authLoading) return <div className="p-4 text-sm text-gray-500">Loading auth...</div>;

  if (isLoading)
    return <div className="p-4 text-gray-600 text-sm animate-pulse">Loading stats...</div>;

  if (error)
    return <div className="p-4 bg-red-50 border border-red-200 text-red-700 text-sm">{error}</div>;

  if (!stats)
    return <div className="p-4 text-sm text-gray-500">No verified stats available.</div>;

  return (
    <motion.div className="bg-gradient-to-br from-green-50 to-emerald-50 border border-green-200 rounded-xl p-6 shadow-sm">
      <h3 className="text-lg font-semibold text-gray-900 mb-4">Verified Users</h3>
      <div className="text-4xl font-bold text-green-600">{stats.totalCount}</div>
      <p className="text-sm text-gray-600 mb-4">Total Verified</p>
      <ul className="space-y-2">
        {stats.recentUsers.map((u, idx) => (
          <li key={`${u.walletAddress}-${u.createdAt}-${idx}`} className="flex justify-between border-b pb-1 text-sm">
            <span>{u.username}</span>
            <span className="text-gray-400">{u.createdAt.slice(0, 10)}</span>
          </li>
        ))}
      </ul>
    </motion.div>
  );
}