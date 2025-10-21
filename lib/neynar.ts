// Neynar API Integration for Farcaster data
const NEYNAR_API_BASE = 'https://api.neynar.com/v2';

export interface NeynarUser {
  fid: number;
  username: string;
  display_name: string;
  pfp_url: string;
  profile: {
    bio: {
      text: string;
    };
  };
  follower_count: number;
  following_count: number;
  verifications?: string[];
}

export interface NeynarFollowing {
  users: NeynarUser[];
}

export interface NeynarCast {
  hash: string;
  author: NeynarUser;
  text: string;
  timestamp: string;
  reactions: {
    likes_count: number;
    recasts_count: number;
  };
}

class NeynarAPI {
  private apiKey: string;

  constructor() {
    this.apiKey = process.env.NEYNAR_API_KEY || '';
    if (!this.apiKey) {
      console.warn('NEYNAR_API_KEY not set. Neynar API calls will fail.');
    }
  }

  private async fetch(endpoint: string, options: RequestInit = {}) {
    const url = `${NEYNAR_API_BASE}${endpoint}`;

    const response = await fetch(url, {
      ...options,
      headers: {
        'x-api-key': this.apiKey,
        'Content-Type': 'application/json',
        ...options.headers,
      },
    });

    if (!response.ok) {
      const error = await response.text();
      throw new Error(
        `Neynar API error (${response.status}): ${error}`
      );
    }

    return response.json();
  }

  // Get user by FID
  async getUserByFid(fid: number): Promise<NeynarUser> {
    const data = await this.fetch(`/farcaster/user/bulk?fids=${fid}`);
    return data.users[0];
  }

  // Get user by username
  async getUserByUsername(username: string): Promise<NeynarUser> {
    const data = await this.fetch(`/farcaster/user/by_username?username=${username}`);
    return data;
  }

  // Get bulk users by FIDs
  async getBulkUsers(fids: number[]): Promise<NeynarUser[]> {
    if (fids.length === 0) return [];

    const fidsParam = fids.join(',');
    const data = await this.fetch(`/farcaster/user/bulk?fids=${fidsParam}`);
    return data.users || [];
  }

  // Get user's following list
  async getUserFollowing(fid: number, limit: number = 100): Promise<NeynarUser[]> {
    try {
      const data = await this.fetch(
        `/farcaster/following?fid=${fid}&limit=${limit}`
      );
      return data.users || [];
    } catch (error) {
      console.error('Error fetching following:', error);
      return [];
    }
  }

  // Get user's followers
  async getUserFollowers(fid: number, limit: number = 100): Promise<NeynarUser[]> {
    try {
      const data = await this.fetch(
        `/farcaster/followers?fid=${fid}&limit=${limit}`
      );
      return data.users || [];
    } catch (error) {
      console.error('Error fetching followers:', error);
      return [];
    }
  }

  // Get user's recent casts
  async getUserCasts(fid: number, limit: number = 25): Promise<NeynarCast[]> {
    try {
      const data = await this.fetch(
        `/farcaster/casts?fid=${fid}&limit=${limit}`
      );
      return data.casts || [];
    } catch (error) {
      console.error('Error fetching casts:', error);
      return [];
    }
  }

  // Search users by query
  async searchUsers(query: string, limit: number = 10): Promise<NeynarUser[]> {
    try {
      const data = await this.fetch(
        `/farcaster/user/search?q=${encodeURIComponent(query)}&limit=${limit}`
      );
      return data.result?.users || [];
    } catch (error) {
      console.error('Error searching users:', error);
      return [];
    }
  }

  // Get user's feed
  async getUserFeed(fid: number, limit: number = 25): Promise<NeynarCast[]> {
    try {
      const data = await this.fetch(
        `/farcaster/feed?fid=${fid}&limit=${limit}`
      );
      return data.casts || [];
    } catch (error) {
      console.error('Error fetching feed:', error);
      return [];
    }
  }
}

// Export singleton instance
export const neynarAPI = new NeynarAPI();

// Helper function to convert Neynar user to our User type
export function convertNeynarUserToUser(neynarUser: NeynarUser) {
  return {
    fid: neynarUser.fid,
    username: neynarUser.username,
    display_name: neynarUser.display_name,
    avatar_url: neynarUser.pfp_url,
    bio: neynarUser.profile?.bio?.text || '',
  };
}
