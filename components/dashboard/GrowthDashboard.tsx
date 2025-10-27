'use client';

import { useEffect, useState } from 'react';
import { motion } from 'framer-motion';
import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import { useFarcasterAuth } from '@/components/providers/FarcasterAuthProvider';

interface GrowthData {
  date: string;
  count: number;
}

export default function GrowthDashboard() {
  const { user, loading: authLoading } = useFarcasterAuth();
  const [data, setData] = useState<GrowthData[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchGrowth = async () => {
    if (!user?.fid) return;
    try {
      setIsLoading(true);
      const res = await fetch(`/api/stats/insights?fid=${user.fid}`);
      const json = await res.json();
      if (json.success) setData(json.data.verificationsOverTime);
      else setError(json.error || 'Failed to fetch growth analytics');
    } catch (e: any) {
      setError(e.message);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    if (!authLoading && user?.fid) fetchGrowth();
  }, [authLoading, user]);

  if (authLoading || isLoading) {
    return (
      <div className="backdrop-blur-xl bg-white/40 rounded-2xl border border-white/60 shadow-lg p-8">
        <div className="flex items-center justify-center gap-3">
          <div className="w-5 h-5 border-2 border-blue-400 border-t-transparent rounded-full animate-spin" />
          <span className="text-sm text-gray-600 font-medium">Loading growth data...</span>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="backdrop-blur-xl bg-red-50/60 rounded-2xl border border-red-200/60 shadow-lg p-6">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-full bg-red-100 flex items-center justify-center">
            <svg className="w-5 h-5 text-red-600" fill="currentColor" viewBox="0 0 20 20">
              <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clipRule="evenodd" />
            </svg>
          </div>
          <span className="text-sm text-red-700 font-medium">{error}</span>
        </div>
      </div>
    );
  }

  if (data.length === 0) {
    return (
      <div className="backdrop-blur-xl bg-white/40 rounded-2xl border border-white/60 shadow-lg p-8 text-center">
        <span className="text-sm text-gray-500">No growth data available yet.</span>
      </div>
    );
  }

  const formatDate = (dateStr: string) => {
    const date = new Date(dateStr);
    return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
  };

  const chartData = data.map(item => ({
    date: formatDate(item.date),
    count: item.count
  }));

  // Calculate stats
  const totalVerifications = data.reduce((sum, item) => sum + item.count, 0);
  const avgDaily = totalVerifications > 0 ? (totalVerifications / data.length).toFixed(1) : '0';
  const maxDay = data.length > 0 ? Math.max(...data.map(d => d.count)) : 0;

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.6, ease: [0.22, 1, 0.36, 1] }}
      className="space-y-4"
    >
      {/* Chart Card */}
      <motion.div
        initial={{ opacity: 0, scale: 0.95 }}
        animate={{ opacity: 1, scale: 1 }}
        transition={{ duration: 0.5, delay: 0.1 }}
        whileHover={{ y: -4, transition: { duration: 0.2 } }}
        className="backdrop-blur-xl bg-gradient-to-br from-blue-50/80 via-indigo-50/80 to-purple-50/80 rounded-2xl border border-blue-200/60 shadow-lg hover:shadow-2xl transition-all duration-300 p-6"
      >
        {/* Header */}
        <div className="flex items-center justify-between mb-6">
          <div className="flex items-center gap-2">
            <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-blue-100 to-indigo-100 flex items-center justify-center">
              <span className="text-xl">📊</span>
            </div>
            <div>
              <h4 className="text-base font-semibold text-gray-900">14-Day Growth Trend</h4>
              <p className="text-xs text-gray-500">Verification activity overview</p>
            </div>
          </div>

          {/* Mini Stats Pills */}
          <div className="flex items-center gap-2">
            <div className="px-3 py-1.5 rounded-full bg-white/70 backdrop-blur-sm border border-blue-200/40">
              <div className="flex items-center gap-1.5">
                <span className="text-xs text-gray-500">Total:</span>
                <span className="text-sm font-semibold text-blue-700">{totalVerifications}</span>
              </div>
            </div>
            <div className="px-3 py-1.5 rounded-full bg-white/70 backdrop-blur-sm border border-indigo-200/40">
              <div className="flex items-center gap-1.5">
                <span className="text-xs text-gray-500">Avg:</span>
                <span className="text-sm font-semibold text-indigo-700">{avgDaily}/day</span>
              </div>
            </div>
          </div>
        </div>

        {/* Chart */}
        <ResponsiveContainer width="100%" height={320}>
          <AreaChart data={chartData}>
            <defs>
              <linearGradient id="growthGradient" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stopColor="#3b82f6" stopOpacity={0.4} />
                <stop offset="50%" stopColor="#6366f1" stopOpacity={0.2} />
                <stop offset="100%" stopColor="#8b5cf6" stopOpacity={0.05} />
              </linearGradient>
              <linearGradient id="strokeGradient" x1="0" y1="0" x2="1" y2="0">
                <stop offset="0%" stopColor="#3b82f6" />
                <stop offset="50%" stopColor="#6366f1" />
                <stop offset="100%" stopColor="#8b5cf6" />
              </linearGradient>
            </defs>
            <CartesianGrid strokeDasharray="3 3" stroke="#d1d5db" strokeOpacity={0.3} />
            <XAxis
              dataKey="date"
              tick={{ fontSize: 11, fill: '#6b7280' }}
              stroke="#9ca3af"
              strokeWidth={0.5}
              tickLine={false}
              axisLine={{ stroke: '#e5e7eb' }}
            />
            <YAxis
              tick={{ fontSize: 11, fill: '#6b7280' }}
              stroke="#9ca3af"
              strokeWidth={0.5}
              tickLine={false}
              axisLine={{ stroke: '#e5e7eb' }}
              allowDecimals={false}
            />
            <Tooltip
              contentStyle={{
                backgroundColor: 'rgba(255, 255, 255, 0.95)',
                backdropFilter: 'blur(12px)',
                border: '1px solid rgba(209, 213, 219, 0.4)',
                borderRadius: '12px',
                fontSize: '12px',
                padding: '8px 12px',
                boxShadow: '0 4px 12px rgba(0,0,0,0.1)'
              }}
              cursor={{ stroke: '#6366f1', strokeWidth: 1, strokeDasharray: '4 4' }}
            />
            <Area
              type="monotone"
              dataKey="count"
              stroke="url(#strokeGradient)"
              strokeWidth={3}
              fill="url(#growthGradient)"
              fillOpacity={1}
              dot={{ fill: '#6366f1', r: 5, strokeWidth: 2, stroke: '#fff' }}
              activeDot={{ r: 7, strokeWidth: 2, stroke: '#fff', fill: '#6366f1' }}
            />
          </AreaChart>
        </ResponsiveContainer>

        {/* Bottom Stats Grid */}
        <div className="grid grid-cols-3 gap-3 mt-6 pt-6 border-t border-white/60">
          {/* Total */}
          <div className="flex flex-col items-center justify-center p-3 rounded-xl bg-white/50 backdrop-blur-sm border border-blue-100/60">
            <div className="text-2xl font-bold bg-gradient-to-r from-blue-600 to-indigo-600 bg-clip-text text-transparent">
              {totalVerifications}
            </div>
            <div className="text-xs text-gray-600 mt-1">Total Verifications</div>
          </div>

          {/* Average */}
          <div className="flex flex-col items-center justify-center p-3 rounded-xl bg-white/50 backdrop-blur-sm border border-indigo-100/60">
            <div className="text-2xl font-bold bg-gradient-to-r from-indigo-600 to-purple-600 bg-clip-text text-transparent">
              {avgDaily}
            </div>
            <div className="text-xs text-gray-600 mt-1">Avg per Day</div>
          </div>

          {/* Peak */}
          <div className="flex flex-col items-center justify-center p-3 rounded-xl bg-white/50 backdrop-blur-sm border border-purple-100/60">
            <div className="text-2xl font-bold bg-gradient-to-r from-purple-600 to-pink-600 bg-clip-text text-transparent">
              {maxDay}
            </div>
            <div className="text-xs text-gray-600 mt-1">Peak Day</div>
          </div>
        </div>
      </motion.div>
    </motion.div>
  );
}
