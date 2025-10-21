// Shared type definitions for the application

import type { Trait } from './constants/traits';

export interface FarcasterUser {
  fid: number;
  username: string;
  displayName: string;
  pfpUrl: string;
  bio?: string;
  userCode?: string;
  traits?: Trait[];
}

export interface AuthState {
  isAuthenticated: boolean;
  user: FarcasterUser | null;
  loading: boolean;
}

export interface CreateMatchFormData {
  userAFid: number;
  userBFid: number;
  message?: string;
}

export interface MatchWithUsers {
  id: string;
  userA: {
    fid: number;
    username: string;
    displayName: string;
    avatarUrl: string;
  };
  userB: {
    fid: number;
    username: string;
    displayName: string;
    avatarUrl: string;
  };
  creator: {
    fid: number;
    username: string;
    displayName: string;
    avatarUrl: string;
  };
  status: 'pending' | 'accepted' | 'declined' | 'cancelled';
  message?: string;
  aAccepted: boolean;
  bAccepted: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface ChatMessage {
  id: string;
  matchId: string;
  sender: {
    fid: number;
    username: string;
    displayName: string;
    avatarUrl: string;
  };
  content: string;
  isSystemMessage: boolean;
  createdAt: string;
}

// Database types
export type MatchStatus = 'proposed' | 'accepted_by_a' | 'accepted_by_b' | 'accepted' | 'declined' | 'cancelled' | 'completed';
export type MeetingState = 'scheduled' | 'in_progress' | 'closed';

export interface Match {
  id: string;
  user_a_fid: number;
  user_b_fid: number;
  created_by_fid: number;
  created_by: string;
  status: MatchStatus;
  rationale?: MatchRationale;
  a_accepted: boolean;
  b_accepted: boolean;
  a_completed: boolean;
  b_completed: boolean;
  meeting_link?: string;
  scheduled_at?: string;
  completed_at?: string;
  meeting_state?: MeetingState;
  meeting_started_at?: string;
  meeting_expires_at?: string;
  meeting_closed_at?: string;
  created_at: string;
  updated_at: string;
}

export interface MatchRationale {
  traitOverlap: Trait[];
  bioKeywords: string[];
  score: number;
  traitSimilarity: number;
  bioSimilarity: number;
}

export interface Achievement {
  id: string;
  user_fid: number;
  achievement_type: string;
  achieved_at: string;
  metadata?: Record<string, unknown>;
}

export interface LevelState {
  currentLevel: number;
  currentXP: number;
  xpForNextLevel: number;
  progress: number;
}

export interface UserStats {
  totalMatches: number;
  completedMatches: number;
  activeMatches: number;
  successRate: number;
  totalMeetings: number;
}

export interface AutoMatchRun {
  id: string;
  started_at: string;
  completed_at?: string;
  users_processed?: number;
  matches_created?: number;
  status: 'running' | 'completed' | 'failed';
  error_message?: string;
}

export interface ErrorResponse {
  error: string;
  details?: string;
}

export interface SuccessResponse<T = Record<string, unknown>> {
  success: boolean;
  data?: T;
  message?: string;
}
