/**
 * CooldownCard Component
 * Reusable UI component for displaying cooldown information across the app
 */

import React from 'react';
import { CooldownInfo, formatCooldownExpiry } from '@/lib/utils/cooldown';

interface CooldownCardProps {
  cooldownInfo: CooldownInfo;
  message: string;
  context?: 'match' | 'suggestion';
}

export function CooldownCard({ cooldownInfo, message, context = 'match' }: CooldownCardProps) {
  const { remainingDays, remainingHours, expiresAt } = cooldownInfo;

  return (
    <div className="backdrop-blur-xl bg-gradient-to-r from-orange-50/90 to-amber-50/90 border border-orange-300/60 rounded-xl p-5">
      <div className="flex items-start gap-3">
        <div className="flex-shrink-0 text-2xl">⏳</div>
        <div className="flex-1">
          <p className="text-sm font-bold mb-2 text-orange-900">{message}</p>

          <div className="space-y-2">
            {/* Countdown Display */}
            <div className="backdrop-blur-sm bg-white/40 rounded-lg p-3 border border-orange-200">
              <div className="flex items-center justify-between mb-2">
                <span className="text-xs font-semibold text-orange-800">
                  Time Remaining:
                </span>
                <span className="text-xs text-orange-700">
                  {formatCooldownExpiry(expiresAt)}
                </span>
              </div>
              <div className="flex gap-3">
                <div className="flex-1 text-center p-2 bg-orange-100/50 rounded-md">
                  <div className="text-xl font-bold text-orange-900">
                    {remainingDays}
                  </div>
                  <div className="text-[10px] text-orange-700 font-medium">
                    {remainingDays === 1 ? 'Day' : 'Days'}
                  </div>
                </div>
                <div className="flex-1 text-center p-2 bg-orange-100/50 rounded-md">
                  <div className="text-xl font-bold text-orange-900">
                    {remainingHours}
                  </div>
                  <div className="text-[10px] text-orange-700 font-medium">
                    {remainingHours === 1 ? 'Hour' : 'Hours'}
                  </div>
                </div>
              </div>
            </div>

            {/* Explanatory Note */}
            <p className="text-xs text-orange-800 leading-relaxed">
              💡 <strong>Why cooldowns?</strong> Cooldowns help ensure balanced,
              meaningful interactions. You can try again once the cooldown expires.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
