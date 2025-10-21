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
