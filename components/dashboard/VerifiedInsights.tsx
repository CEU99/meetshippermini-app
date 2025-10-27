'use client';

import { useEffect, useState } from 'react';
import { motion } from 'framer-motion';
import { LineChart, Line, BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, CartesianGrid } from 'recharts';
import { useFarcasterAuth } from '@/components/providers/FarcasterAuthProvider';

interface InsightsData {
  verificationsOverTime: { date: string; count: number }[];
  topVerifiedUsers: { username: string; count: number }[];
}

export default function VerifiedInsights() {
  const { user, loading: authLoading } = useFarcasterAuth();
  const [insights, setInsights] = useState<InsightsData | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchInsights = async () => {
    if (!user?.fid) return;
    try {
      setIsLoading(true);
      const res = await fetch(`/api/stats/insights?fid=${user.fid}`);
      const data = await res.json();
      if (data.success) setInsights(data.data);
      else setError(data.error || 'Failed to load insights');
    } catch (e: any) {
      setError(e.message);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    if (!authLoading && user?.fid) fetchInsights();
  }, [authLoading, user]);

  if (authLoading || isLoading) {
    return (
      <div className="backdrop-blur-xl bg-white/40 rounded-2xl border border-white/60 shadow-lg p-8">
        <div className="flex items-center justify-center gap-3">
          <div className="w-5 h-5 border-2 border-purple-400 border-t-transparent rounded-full animate-spin" />
          <span className="text-sm text-gray-600 font-medium">Loading analytics...</span>
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

  if (!insights) {
    return (
      <div className="backdrop-blur-xl bg-white/40 rounded-2xl border border-white/60 shadow-lg p-8 text-center">
        <span className="text-sm text-gray-500">No analytics data available yet.</span>
      </div>
    );
  }

  const formatDate = (dateStr: string) => {
    const date = new Date(dateStr);
    return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
  };

  const timeData = insights.verificationsOverTime.map(item => ({
    date: formatDate(item.date),
    count: item.count
  }));

  const userData = insights.topVerifiedUsers.slice(0, 5);

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.6, ease: [0.22, 1, 0.36, 1] }}
      className="space-y-4"
    >
      {/* Section Header */}
      <div className="flex items-center gap-3 mb-2">
        <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-purple-100 to-blue-100 flex items-center justify-center">
          <svg className="w-5 h-5 text-purple-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
          </svg>
        </div>
        <div>
          <h3 className="text-lg font-semibold text-gray-900">Verification Analytics</h3>
          <p className="text-sm text-gray-500">On-chain attestation insights</p>
        </div>
      </div>

      {/* Charts Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Verifications Over Time */}
        <motion.div
          initial={{ opacity: 0, scale: 0.95 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ duration: 0.5, delay: 0.1 }}
          whileHover={{ y: -4, transition: { duration: 0.2 } }}
          className="group backdrop-blur-xl bg-gradient-to-br from-emerald-50/80 to-teal-50/80 rounded-2xl border border-emerald-200/60 shadow-lg hover:shadow-2xl transition-all duration-300 p-6"
        >
          <div className="flex items-center gap-2 mb-4">
            <div className="w-8 h-8 rounded-lg bg-emerald-100 flex items-center justify-center">
              <span className="text-lg">📈</span>
            </div>
            <div>
              <h4 className="text-base font-semibold text-gray-900">Verifications Over Time</h4>
              <p className="text-xs text-gray-500">Last 14 days</p>
            </div>
          </div>

          <ResponsiveContainer width="100%" height={280}>
            <LineChart data={timeData}>
              <defs>
                <linearGradient id="lineGradient" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stopColor="#10b981" stopOpacity={0.4} />
                  <stop offset="100%" stopColor="#10b981" stopOpacity={0} />
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
                cursor={{ stroke: '#10b981', strokeWidth: 1, strokeDasharray: '4 4' }}
              />
              <Line
                type="monotone"
                dataKey="count"
                stroke="#10b981"
                strokeWidth={3}
                dot={{ fill: '#10b981', r: 5, strokeWidth: 2, stroke: '#fff' }}
                activeDot={{ r: 7, strokeWidth: 2 }}
                fill="url(#lineGradient)"
              />
            </LineChart>
          </ResponsiveContainer>
        </motion.div>

        {/* Top Verified Users */}
        <motion.div
          initial={{ opacity: 0, scale: 0.95 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ duration: 0.5, delay: 0.2 }}
          whileHover={{ y: -4, transition: { duration: 0.2 } }}
          className="group backdrop-blur-xl bg-gradient-to-br from-violet-50/80 to-purple-50/80 rounded-2xl border border-violet-200/60 shadow-lg hover:shadow-2xl transition-all duration-300 p-6"
        >
          <div className="flex items-center gap-2 mb-4">
            <div className="w-8 h-8 rounded-lg bg-violet-100 flex items-center justify-center">
              <span className="text-lg">🏆</span>
            </div>
            <div>
              <h4 className="text-base font-semibold text-gray-900">Top Verified Users</h4>
              <p className="text-xs text-gray-500">Most verifications</p>
            </div>
          </div>

          <ResponsiveContainer width="100%" height={280}>
            <BarChart data={userData}>
              <defs>
                <linearGradient id="barGradient" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stopColor="#8b5cf6" stopOpacity={0.9} />
                  <stop offset="100%" stopColor="#a78bfa" stopOpacity={0.7} />
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" stroke="#d1d5db" strokeOpacity={0.3} />
              <XAxis
                dataKey="username"
                tick={{ fontSize: 10, fill: '#6b7280' }}
                stroke="#9ca3af"
                strokeWidth={0.5}
                tickLine={false}
                axisLine={{ stroke: '#e5e7eb' }}
                angle={-15}
                textAnchor="end"
                height={60}
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
                cursor={{ fill: 'rgba(139, 92, 246, 0.1)' }}
              />
              <Bar
                dataKey="count"
                fill="url(#barGradient)"
                radius={[12, 12, 0, 0]}
                maxBarSize={60}
              />
            </BarChart>
          </ResponsiveContainer>
        </motion.div>
      </div>
    </motion.div>
  );
}
