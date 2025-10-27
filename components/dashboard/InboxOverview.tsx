'use client';

import { motion } from 'framer-motion';

interface InboxOverviewProps {
  stats: {
    total: number;
    pending: number;
    accepted: number;
    asCreator: number;
  };
  loading?: boolean;
}

export default function InboxOverview({ stats, loading = false }: InboxOverviewProps) {
  if (loading) {
    return (
      <div className="backdrop-blur-xl bg-gradient-to-br from-purple-50/80 via-blue-50/80 to-indigo-50/80 rounded-2xl border border-purple-200/60 shadow-lg p-6 h-full">
        <div className="text-center mb-4">
          <h3 className="text-sm font-bold text-purple-700 uppercase tracking-wider flex items-center justify-center gap-2">
            <span>📥</span> Inbox Overview
          </h3>
          <p className="text-xs text-purple-600 mt-1">Your recent match status summary</p>
        </div>
        <div className="grid grid-cols-2 gap-3">
          {[1, 2, 3, 4].map((i) => (
            <div
              key={i}
              className="h-24 bg-gradient-to-r from-gray-100 to-gray-50 rounded-xl animate-pulse"
            ></div>
          ))}
        </div>
      </div>
    );
  }

  const statCards = [
    {
      label: 'Total Matches',
      value: stats.total,
      icon: (
        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth={2}
            d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"
          />
        </svg>
      ),
      gradient: 'from-purple-50/80 to-violet-50/80',
      textGradient: 'from-purple-700 to-violet-700',
      iconBg: 'from-purple-100 to-violet-100',
      iconColor: 'text-purple-600',
    },
    {
      label: 'Pending',
      value: stats.pending,
      icon: (
        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth={2}
            d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
          />
        </svg>
      ),
      gradient: 'from-yellow-50/80 to-amber-50/80',
      textGradient: 'from-yellow-700 to-amber-700',
      iconBg: 'from-yellow-100 to-amber-100',
      iconColor: 'text-yellow-600',
    },
    {
      label: 'Accepted',
      value: stats.accepted,
      icon: (
        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth={2}
            d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
          />
        </svg>
      ),
      gradient: 'from-emerald-50/80 to-green-50/80',
      textGradient: 'from-emerald-700 to-green-700',
      iconBg: 'from-emerald-100 to-green-100',
      iconColor: 'text-emerald-600',
    },
    {
      label: 'Created',
      value: stats.asCreator,
      icon: (
        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth={2}
            d="M12 6v6m0 0v6m0-6h6m-6 0H6"
          />
        </svg>
      ),
      gradient: 'from-blue-50/80 to-cyan-50/80',
      textGradient: 'from-blue-700 to-cyan-700',
      iconBg: 'from-blue-100 to-cyan-100',
      iconColor: 'text-blue-600',
    },
  ];

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.6, ease: [0.22, 1, 0.36, 1] }}
      className="backdrop-blur-xl bg-gradient-to-br from-purple-50/80 via-blue-50/80 to-indigo-50/80 rounded-2xl border border-purple-200/60 shadow-lg hover:shadow-xl transition-all duration-300 p-6 h-full"
    >
      {/* Header */}
      <div className="text-center mb-4">
        <h3 className="text-sm font-bold text-purple-700 uppercase tracking-wider flex items-center justify-center gap-2">
          <span>📥</span> Inbox Overview
        </h3>
        <p className="text-xs text-purple-600 mt-1">Your recent match status summary</p>
      </div>

      {/* Stats Grid - 2x2 */}
      <div className="grid grid-cols-2 gap-3">
        {statCards.map((card, index) => (
          <motion.div
            key={card.label}
            initial={{ opacity: 0, scale: 0.95 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ duration: 0.4, delay: index * 0.05 }}
            className={`backdrop-blur-xl bg-gradient-to-br ${card.gradient} rounded-xl border border-white/60 shadow-sm hover:shadow-md transition-all duration-200 p-4 group`}
          >
            <div className="flex flex-col items-center text-center gap-2">
              {/* Icon */}
              <div
                className={`w-10 h-10 bg-gradient-to-br ${card.iconBg} rounded-lg flex items-center justify-center group-hover:scale-110 transition-transform duration-300 shadow-sm ${card.iconColor}`}
              >
                {card.icon}
              </div>

              {/* Label */}
              <p className="text-xs font-semibold text-gray-600 uppercase tracking-wide">
                {card.label}
              </p>

              {/* Value */}
              <p
                className={`text-2xl font-bold bg-gradient-to-r ${card.textGradient} bg-clip-text text-transparent`}
              >
                {card.value}
              </p>
            </div>
          </motion.div>
        ))}
      </div>
    </motion.div>
  );
}
