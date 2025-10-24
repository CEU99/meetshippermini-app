'use client';

import { useEffect, useState, useRef } from 'react';
import { motion } from 'framer-motion';
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Legend,
  Area,
  AreaChart,
} from 'recharts';
import { useFarcasterAuth } from '@/components/providers/FarcasterAuthProvider';

// ============================================================================
// Types
// ============================================================================

interface DailyCount {
  date: string;
  count: number;
}

interface GrowthData {
  dailyCounts: DailyCount[];
  weeklyTotal: number;
  previousWeekTotal: number;
  growthRate: number;
  currentWeekCounts: DailyCount[];
  previousWeekCounts: DailyCount[];
}

// ============================================================================
// GrowthDashboard Component
// ============================================================================

export default function GrowthDashboard() {
  const { user } = useFarcasterAuth();
  const [growth, setGrowth] = useState<GrowthData | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [lastUpdated, setLastUpdated] = useState<Date | null>(null);
  const [isHovered, setIsHovered] = useState(false);
  const intervalRef = useRef<NodeJS.Timeout | null>(null);

  // Fetch growth data (USER-SCOPED)
  const fetchGrowth = async () => {
    if (!user?.fid) {
      console.log('[GrowthDashboard] No user FID available, skipping fetch');
      setIsLoading(false);
      return;
    }

    try {
      console.log('[GrowthDashboard] Fetching growth data for FID:', user.fid);
      const response = await fetch(`/api/stats/growth?fid=${user.fid}`);

      if (!response.ok) {
        throw new Error('Failed to fetch growth data');
      }

      const data = await response.json();
      console.log('[GrowthDashboard] Growth data fetched:', data);

      if (data.success) {
        setGrowth(data.data);
        setLastUpdated(new Date());
        setError(null);
      } else {
        throw new Error(data.error || 'Failed to load growth data');
      }
    } catch (err: any) {
      console.error('[GrowthDashboard] Error fetching growth:', err);
      setError(err.message || 'Failed to load growth analytics');
    } finally {
      setIsLoading(false);
    }
  };

  // Initial fetch and auto-refresh every 30s - wait for user to be loaded
  useEffect(() => {
    if (!user) {
      return;
    }

    fetchGrowth();

    // Set up auto-refresh interval
    intervalRef.current = setInterval(() => {
      console.log('[GrowthDashboard] Auto-refreshing growth data (30s interval)');
      fetchGrowth();
    }, 30000); // 30 seconds

    // Cleanup interval on unmount
    return () => {
      if (intervalRef.current) {
        clearInterval(intervalRef.current);
      }
    };
  }, [user]);

  // Format date for display (MMM DD)
  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
  };

  // Format time for "Last updated" display
  const formatTime = (date: Date | null) => {
    if (!date) return '';
    return date.toLocaleTimeString('en-US', {
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
    });
  };

  // Prepare data for chart
  const chartData = growth?.dailyCounts.map((item) => ({
    date: formatDate(item.date),
    Verifications: item.count,
  })) || [];

  // Determine growth badge color and icon
  const isPositiveGrowth = growth && growth.growthRate >= 0;
  const growthBadgeColor = isPositiveGrowth
    ? 'bg-green-100 text-green-700 border-green-300'
    : 'bg-red-100 text-red-700 border-red-300';

  // Framer Motion variants
  const containerVariants = {
    hidden: { opacity: 0, y: 20 },
    visible: {
      opacity: 1,
      y: 0,
      transition: {
        duration: 0.5,
        ease: 'easeOut',
        staggerChildren: 0.15,
      },
    },
  };

  const itemVariants = {
    hidden: { opacity: 0, scale: 0.95 },
    visible: {
      opacity: 1,
      scale: 1,
      transition: { duration: 0.4, ease: 'easeOut' },
    },
  };

  const badgeVariants = {
    hidden: { opacity: 0, x: -20 },
    visible: {
      opacity: 1,
      x: 0,
      transition: { duration: 0.5, ease: 'easeOut' },
    },
  };

  return (
    <motion.div
      initial="hidden"
      animate="visible"
      variants={containerVariants}
      className="space-y-6"
    >
      {/* Header with Growth Badge */}
      <div className="flex items-center justify-between flex-wrap gap-4">
        <div className="flex items-center gap-3">
          <div className="p-2.5 bg-gradient-to-br from-green-100 to-purple-100 rounded-lg">
            <svg
              className="w-6 h-6 text-purple-600"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6"
              />
            </svg>
          </div>
          <div>
            <h3 className="text-lg font-semibold text-gray-900">
              Growth Analytics
            </h3>
            <p className="text-sm text-gray-600">
              Weekly verification trends
              {lastUpdated && (
                <span className="text-xs text-gray-500 ml-2">
                  • Updated {formatTime(lastUpdated)}
                </span>
              )}
            </p>
          </div>
        </div>

        {/* Growth Badge */}
        {growth && !isLoading && !error && (
          <motion.div
            variants={badgeVariants}
            className={`flex items-center gap-2 px-4 py-2.5 rounded-lg border-2 font-semibold text-sm ${growthBadgeColor} shadow-sm`}
            onMouseEnter={() => setIsHovered(true)}
            onMouseLeave={() => setIsHovered(false)}
            animate={{
              boxShadow: isHovered
                ? isPositiveGrowth
                  ? '0 0 20px rgba(34, 197, 94, 0.4)'
                  : '0 0 20px rgba(239, 68, 68, 0.4)'
                : '0 1px 2px 0 rgb(0 0 0 / 0.05)',
            }}
            transition={{ duration: 0.3 }}
          >
            {isPositiveGrowth ? (
              <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
                <path
                  fillRule="evenodd"
                  d="M12 7a1 1 0 110-2h5a1 1 0 011 1v5a1 1 0 11-2 0V8.414l-4.293 4.293a1 1 0 01-1.414 0L8 10.414l-4.293 4.293a1 1 0 01-1.414-1.414l5-5a1 1 0 011.414 0L11 10.586 14.586 7H12z"
                  clipRule="evenodd"
                />
              </svg>
            ) : (
              <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
                <path
                  fillRule="evenodd"
                  d="M12 13a1 1 0 100 2h5a1 1 0 001-1V9a1 1 0 10-2 0v2.586l-4.293-4.293a1 1 0 00-1.414 0L8 9.586 3.707 5.293a1 1 0 00-1.414 1.414l5 5a1 1 0 001.414 0L11 9.414 14.586 13H12z"
                  clipRule="evenodd"
                />
              </svg>
            )}
            <span>
              {isPositiveGrowth ? '+' : ''}
              {growth.growthRate.toFixed(1)}% This Week
            </span>
          </motion.div>
        )}
      </div>

      {/* Loading State */}
      {isLoading && (
        <div className="flex items-center justify-center py-16">
          <div className="flex items-center gap-2 text-purple-600">
            <svg
              className="animate-spin h-6 w-6"
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
            <span className="text-sm font-medium">Loading growth data...</span>
          </div>
        </div>
      )}

      {/* Error State */}
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

      {/* Chart and Stats */}
      {growth && !isLoading && !error && (
        <>
          {/* Growth Chart */}
          <motion.div
            variants={itemVariants}
            className="bg-gradient-to-br from-green-50 via-emerald-50 to-purple-50 border border-green-200 rounded-xl p-6 shadow-sm hover:shadow-lg transition-all duration-300"
          >
            <div className="mb-4">
              <h4 className="text-base font-semibold text-gray-900 flex items-center gap-2">
                <span className="text-green-600">📈</span>
                14-Day Growth Trend
              </h4>
              <p className="text-xs text-gray-600 mt-1">
                Daily verification counts with weekly comparison
              </p>
            </div>

            <ResponsiveContainer width="100%" height={300}>
              <AreaChart data={chartData}>
                <defs>
                  <linearGradient id="growthGradient" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#16a34a" stopOpacity={0.3} />
                    <stop offset="95%" stopColor="#9333ea" stopOpacity={0.1} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
                <XAxis
                  dataKey="date"
                  tick={{ fontSize: 12, fill: '#6b7280' }}
                  stroke="#9ca3af"
                />
                <YAxis
                  tick={{ fontSize: 12, fill: '#6b7280' }}
                  stroke="#9ca3af"
                  allowDecimals={false}
                />
                <Tooltip
                  contentStyle={{
                    backgroundColor: '#fff',
                    border: '1px solid #d1d5db',
                    borderRadius: '8px',
                    fontSize: '12px',
                  }}
                />
                <Legend
                  wrapperStyle={{ fontSize: '12px', paddingTop: '10px' }}
                />
                <Area
                  type="monotone"
                  dataKey="Verifications"
                  stroke="#16a34a"
                  strokeWidth={3}
                  fill="url(#growthGradient)"
                  animationDuration={1500}
                  animationEasing="ease-in-out"
                />
              </AreaChart>
            </ResponsiveContainer>
          </motion.div>

          {/* Summary Cards */}
          <motion.div
            variants={itemVariants}
            className="grid grid-cols-1 sm:grid-cols-3 gap-4"
          >
            {/* Current Week */}
            <div className="bg-white border-2 border-green-200 rounded-lg p-5 hover:border-green-400 hover:shadow-md transition-all duration-300 group">
              <div className="flex items-center justify-between mb-2">
                <span className="text-xs font-semibold text-green-700 uppercase tracking-wider">
                  Current Week
                </span>
                <div className="p-1.5 bg-green-100 rounded-full group-hover:scale-110 transition-transform duration-300">
                  <svg
                    className="w-4 h-4 text-green-600"
                    fill="currentColor"
                    viewBox="0 0 20 20"
                  >
                    <path
                      fillRule="evenodd"
                      d="M10 18a8 8 0 100-16 8 8 0 000 16zm1-12a1 1 0 10-2 0v4a1 1 0 00.293.707l2.828 2.829a1 1 0 101.415-1.415L11 9.586V6z"
                      clipRule="evenodd"
                    />
                  </svg>
                </div>
              </div>
              <div className="text-3xl font-bold text-green-600 mb-1">
                {growth.weeklyTotal}
              </div>
              <div className="text-xs text-gray-600">Verifications (Last 7 days)</div>
            </div>

            {/* Previous Week */}
            <div className="bg-white border-2 border-gray-200 rounded-lg p-5 hover:border-purple-300 hover:shadow-md transition-all duration-300 group">
              <div className="flex items-center justify-between mb-2">
                <span className="text-xs font-semibold text-gray-700 uppercase tracking-wider">
                  Previous Week
                </span>
                <div className="p-1.5 bg-gray-100 rounded-full group-hover:scale-110 transition-transform duration-300">
                  <svg
                    className="w-4 h-4 text-gray-600"
                    fill="currentColor"
                    viewBox="0 0 20 20"
                  >
                    <path
                      fillRule="evenodd"
                      d="M10 18a8 8 0 100-16 8 8 0 000 16zm.707-10.293a1 1 0 00-1.414-1.414l-3 3a1 1 0 000 1.414l3 3a1 1 0 001.414-1.414L9.414 11H13a1 1 0 100-2H9.414l1.293-1.293z"
                      clipRule="evenodd"
                    />
                  </svg>
                </div>
              </div>
              <div className="text-3xl font-bold text-gray-600 mb-1">
                {growth.previousWeekTotal}
              </div>
              <div className="text-xs text-gray-600">Verifications (7-14 days ago)</div>
            </div>

            {/* Growth Rate */}
            <div
              className={`bg-white border-2 rounded-lg p-5 hover:shadow-md transition-all duration-300 group ${
                isPositiveGrowth
                  ? 'border-green-300 hover:border-green-400'
                  : 'border-red-300 hover:border-red-400'
              }`}
            >
              <div className="flex items-center justify-between mb-2">
                <span className="text-xs font-semibold uppercase tracking-wider">
                  Growth Rate
                </span>
                <div
                  className={`p-1.5 rounded-full group-hover:scale-110 transition-transform duration-300 ${
                    isPositiveGrowth ? 'bg-green-100' : 'bg-red-100'
                  }`}
                >
                  {isPositiveGrowth ? (
                    <svg
                      className="w-4 h-4 text-green-600"
                      fill="currentColor"
                      viewBox="0 0 20 20"
                    >
                      <path
                        fillRule="evenodd"
                        d="M3.293 9.707a1 1 0 010-1.414l6-6a1 1 0 011.414 0l6 6a1 1 0 01-1.414 1.414L11 5.414V17a1 1 0 11-2 0V5.414L4.707 9.707a1 1 0 01-1.414 0z"
                        clipRule="evenodd"
                      />
                    </svg>
                  ) : (
                    <svg
                      className="w-4 h-4 text-red-600"
                      fill="currentColor"
                      viewBox="0 0 20 20"
                    >
                      <path
                        fillRule="evenodd"
                        d="M16.707 10.293a1 1 0 010 1.414l-6 6a1 1 0 01-1.414 0l-6-6a1 1 0 111.414-1.414L9 14.586V3a1 1 0 012 0v11.586l4.293-4.293a1 1 0 011.414 0z"
                        clipRule="evenodd"
                      />
                    </svg>
                  )}
                </div>
              </div>
              <div
                className={`text-3xl font-bold mb-1 ${
                  isPositiveGrowth ? 'text-green-600' : 'text-red-600'
                }`}
              >
                {isPositiveGrowth ? '+' : ''}
                {growth.growthRate.toFixed(1)}%
              </div>
              <div className="text-xs text-gray-600">Week-over-week change</div>
            </div>
          </motion.div>

          {/* Auto-refresh Notice */}
          <motion.div
            variants={itemVariants}
            className="flex items-center justify-center gap-2 text-xs text-gray-500"
          >
            <svg
              className="w-4 h-4 animate-spin"
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
            <span>Auto-refreshing every 30 seconds</span>
          </motion.div>
        </>
      )}
    </motion.div>
  );
}
