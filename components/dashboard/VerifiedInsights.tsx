'use client';

import { useEffect, useState } from 'react';
import { motion } from 'framer-motion';
import {
  LineChart,
  Line,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Legend,
} from 'recharts';
import { useFarcasterAuth } from '@/components/providers/FarcasterAuthProvider';

// ============================================================================
// Types
// ============================================================================
interface VerificationOverTime {
  date: string;
  count: number;
}

interface TopVerifiedUser {
  username: string;
  count: number;
}

interface InsightsData {
  verificationsOverTime: VerificationOverTime[];
  topVerifiedUsers: TopVerifiedUser[];
}

// ============================================================================
// VerifiedInsights Component
// ============================================================================
export default function VerifiedInsights() {
  const { user } = useFarcasterAuth();
  const [insights, setInsights] = useState<InsightsData | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // ==========================================================================
  // Fetch Insights (USER-SCOPED)
  // ==========================================================================
  const fetchInsights = async () => {
    if (!user?.fid) {
      console.log('[VerifiedInsights] No user FID available, skipping fetch');
      setIsLoading(false);
      return;
    }

    try {
      console.log('[VerifiedInsights] Fetching insights data for FID:', user.fid);
      setIsLoading(true);
      const response = await fetch(`/api/stats/insights?fid=${user.fid}`);

      if (!response.ok) throw new Error('Failed to fetch insights');

      const data = await response.json();
      console.log('[VerifiedInsights] Insights fetched:', data);

      if (data.success) {
        setInsights(data.data);
        console.log('✅ Insights loaded:', data.data);
      } else {
        throw new Error(data.error || 'Failed to load insights');
      }
    } catch (err: any) {
      console.error('[VerifiedInsights] Error fetching insights:', err);
      setError(err.message || 'Failed to load verification insights');
    } finally {
      setIsLoading(false);
    }
  };

  // Initial load - wait for user to be loaded
  useEffect(() => {
    if (user) fetchInsights();
  }, [user]);

  // ==========================================================================
  // Listen for "attestation-complete" and refetch automatically
  // ==========================================================================
  useEffect(() => {
    const handleRefetch = () => {
      console.log('🔄 Refetching VerifiedInsights after attestation complete...');
      fetchInsights();
    };

    window.addEventListener('attestation-complete', handleRefetch);
    return () => window.removeEventListener('attestation-complete', handleRefetch);
  }, []);

  // ==========================================================================
  // Helpers
  // ==========================================================================
  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
  };

  const timeChartData =
    insights?.verificationsOverTime?.map((item) => ({
      date: formatDate(item.date),
      Verifications: item.count,
    })) || [];

  const userChartData =
    insights?.topVerifiedUsers?.map((item) => ({
      username: item.username,
      Verifications: item.count,
    })) || [];

  // ==========================================================================
  // Animation Variants
  // ==========================================================================
  const containerVariants = {
    hidden: { opacity: 0, y: 20 },
    visible: {
      opacity: 1,
      y: 0,
      transition: { duration: 0.5, ease: 'easeOut' as any, staggerChildren: 0.2 },
    },
  };

  const chartVariants = {
    hidden: { opacity: 0, scale: 0.95 },
    visible: { opacity: 1, scale: 1, transition: { duration: 0.4, ease: 'easeOut' as any } },
  };

  // ==========================================================================
  // Render
  // ==========================================================================
  return (
    <motion.div initial="hidden" animate="visible" variants={containerVariants} className="space-y-6">
      {/* Header */}
      <div className="flex items-center gap-3">
        <div className="p-2.5 bg-purple-100 rounded-lg">
          <svg className="w-6 h-6 text-purple-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"
            />
          </svg>
        </div>
        <div>
          <h3 className="text-lg font-semibold text-gray-900">Verified Insights</h3>
          <p className="text-sm text-gray-600">Analytics & trends</p>
        </div>
      </div>

      {/* Loading */}
      {isLoading && (
        <div className="flex items-center justify-center py-16 text-purple-600">
          <svg className="animate-spin h-6 w-6 mr-2" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
            <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
            <path
              className="opacity-75"
              fill="currentColor"
              d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
            ></path>
          </svg>
          <span className="font-medium text-sm">Loading insights...</span>
        </div>
      )}

      {/* Error */}
      {error && !isLoading && (
        <div className="flex items-center gap-2 p-4 bg-red-50 border border-red-200 rounded-lg">
          <svg className="w-5 h-5 text-red-600" fill="currentColor" viewBox="0 0 20 20">
            <path
              fillRule="evenodd"
              d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z"
              clipRule="evenodd"
            />
          </svg>
          <span className="text-sm text-red-700">{error}</span>
        </div>
      )}

      {/* Charts */}
      {insights !== null && !isLoading && !error && (
        <>
          {(timeChartData.length === 0 && userChartData.length === 0) ? (
            <div className="p-8 text-center text-gray-500 text-sm bg-gray-50 rounded-lg border border-gray-200">
              No insights data available yet.
            </div>
          ) : (
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              {/* Line Chart */}
              <motion.div
                variants={chartVariants}
                className="bg-gradient-to-br from-green-50 to-emerald-50 border border-green-200 rounded-xl p-6 shadow-sm hover:shadow-md transition-shadow duration-300"
              >
                <div className="mb-4">
                  <h4 className="text-base font-semibold text-gray-900 flex items-center gap-2">
                    <span className="text-green-600">📈</span> Verifications Over Time
                  </h4>
                  <p className="text-xs text-gray-600 mt-1">Last 14 days</p>
                </div>

                <ResponsiveContainer width="100%" height={280}>
                  <LineChart data={timeChartData}>
                    <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
                    <XAxis dataKey="date" tick={{ fontSize: 12, fill: '#6b7280' }} stroke="#9ca3af" />
                    <YAxis tick={{ fontSize: 12, fill: '#6b7280' }} stroke="#9ca3af" allowDecimals={false} />
                    <Tooltip contentStyle={{ backgroundColor: '#fff', border: '1px solid #d1d5db', borderRadius: '8px', fontSize: '12px' }} />
                    <Legend wrapperStyle={{ fontSize: '12px', paddingTop: '10px' }} />
                    <Line type="monotone" dataKey="Verifications" stroke="#16a34a" strokeWidth={3} dot={{ fill: '#16a34a', r: 4 }} activeDot={{ r: 6 }} animationDuration={1000} />
                  </LineChart>
                </ResponsiveContainer>
              </motion.div>

              {/* Bar Chart */}
              <motion.div
                variants={chartVariants}
                className="bg-gradient-to-br from-purple-50 to-blue-50 border border-purple-200 rounded-xl p-6 shadow-sm hover:shadow-md transition-shadow duration-300"
              >
                <div className="mb-4">
                  <h4 className="text-base font-semibold text-gray-900 flex items-center gap-2">
                    <span className="text-purple-600">🏆</span> Top Verified Users
                  </h4>
                  <p className="text-xs text-gray-600 mt-1">Most verifications</p>
                </div>

                <ResponsiveContainer width="100%" height={280}>
                  <BarChart data={userChartData}>
                    <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
                    <XAxis dataKey="username" tick={{ fontSize: 11, fill: '#6b7280' }} stroke="#9ca3af" angle={-15} textAnchor="end" height={60} />
                    <YAxis tick={{ fontSize: 12, fill: '#6b7280' }} stroke="#9ca3af" allowDecimals={false} />
                    <Tooltip contentStyle={{ backgroundColor: '#fff', border: '1px solid #d1d5db', borderRadius: '8px', fontSize: '12px' }} />
                    <Legend wrapperStyle={{ fontSize: '12px', paddingTop: '10px' }} />
                    <Bar dataKey="Verifications" fill="url(#purpleGreenGradient)" radius={[8, 8, 0, 0]} animationDuration={1000} />
                    <defs>
                      <linearGradient id="purpleGreenGradient" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="0%" stopColor="#9333ea" stopOpacity={0.9} />
                        <stop offset="100%" stopColor="#16a34a" stopOpacity={0.9} />
                      </linearGradient>
                    </defs>
                  </BarChart>
                </ResponsiveContainer>
              </motion.div>
            </div>
          )}
        </>
      )}
    </motion.div>
  );
}