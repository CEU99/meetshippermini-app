'use client';

import { Achievement } from '@/lib/constants/achievements';

interface AchievementCardProps {
  achievement: Achievement;
  earned: boolean;
  locked: boolean;
}

export function AchievementCard({ achievement, earned, locked }: AchievementCardProps) {
  return (
    <div
      className={`
        group relative rounded-2xl p-5 transition-all duration-300
        ${
          earned
            ? 'backdrop-blur-xl bg-gradient-to-br from-emerald-50/90 to-green-50/90 border-2 border-emerald-300/60 shadow-lg hover:shadow-xl hover:-translate-y-1'
            : locked
            ? 'backdrop-blur-sm bg-gradient-to-br from-gray-100/50 to-gray-50/40 border border-gray-300/40 opacity-60'
            : 'backdrop-blur-xl bg-gradient-to-br from-white/90 via-purple-50/70 to-blue-50/70 border border-purple-200/60 shadow-md hover:shadow-xl hover:-translate-y-1'
        }
        ${locked ? 'cursor-not-allowed' : 'cursor-default'}
      `}
    >
      {/* Glow Effect for Earned */}
      {earned && (
        <div className="absolute inset-0 bg-gradient-to-br from-emerald-400/20 to-green-400/20 rounded-2xl blur-xl opacity-50 group-hover:opacity-75 transition-opacity duration-300"></div>
      )}

      <div className="relative z-10">
        {/* Icon */}
        <div className={`text-5xl mb-3 text-center transition-transform duration-300 ${!locked && 'group-hover:scale-110'}`}>
          {achievement.icon}
        </div>

        {/* Title */}
        <h3 className={`font-bold text-center text-sm mb-2 ${earned ? 'text-emerald-900' : locked ? 'text-gray-500' : 'text-gray-900'}`}>
          {achievement.title}
        </h3>

        {/* Description */}
        <p className={`text-xs text-center mb-3 leading-relaxed ${earned ? 'text-emerald-700' : locked ? 'text-gray-400' : 'text-gray-600'}`}>
          {achievement.description}
        </p>

        {/* Points Badge */}
        <div className={`text-center mb-3`}>
          <span className={`inline-flex items-center gap-1 px-3 py-1.5 rounded-xl text-sm font-bold ${
            earned
              ? 'bg-emerald-100/80 text-emerald-700 border border-emerald-300/60'
              : locked
              ? 'bg-gray-100/60 text-gray-400 border border-gray-200/60'
              : 'bg-gradient-to-r from-purple-100 to-blue-100 text-purple-700 border border-purple-200/60'
          }`}>
            <svg className="w-3.5 h-3.5" fill="currentColor" viewBox="0 0 20 20">
              <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"/>
            </svg>
            +{achievement.points} pts
          </span>
        </div>

        {/* Status */}
        {earned && (
          <div className="flex items-center justify-center gap-1.5 px-3 py-2 bg-emerald-100/60 backdrop-blur-sm rounded-xl border border-emerald-200/60">
            <svg
              className="w-4 h-4 text-emerald-600"
              fill="currentColor"
              viewBox="0 0 20 20"
            >
              <path
                fillRule="evenodd"
                d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
                clipRule="evenodd"
              />
            </svg>
            <span className="text-xs font-semibold text-emerald-700">Completed</span>
          </div>
        )}

        {!earned && !locked && (
          <div className="pt-3 mt-3 border-t border-purple-200/40">
            <p className="text-[10px] font-bold text-purple-700 uppercase tracking-wider mb-1.5 text-center">How to earn:</p>
            <p className="text-xs text-gray-600 text-center leading-relaxed">{achievement.howToEarn}</p>
          </div>
        )}

        {locked && (
          <div className="flex items-center justify-center gap-1.5 px-3 py-2 bg-gray-100/50 backdrop-blur-sm rounded-xl border border-gray-200/50">
            <svg
              className="w-4 h-4 text-gray-400"
              fill="currentColor"
              viewBox="0 0 20 20"
            >
              <path
                fillRule="evenodd"
                d="M5 9V7a5 5 0 0110 0v2a2 2 0 012 2v5a2 2 0 01-2 2H5a2 2 0 01-2-2v-5a2 2 0 012-2zm8-2v2H7V7a3 3 0 016 0z"
                clipRule="evenodd"
              />
            </svg>
            <span className="text-xs font-semibold text-gray-400">Locked</span>
          </div>
        )}
      </div>
    </div>
  );
}
