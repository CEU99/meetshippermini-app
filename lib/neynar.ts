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

  // Get user's following list with pagination support
  async getUserFollowing(
    fid: number,
    limit: number = 100,
    cursor?: string
  ): Promise<{ users: NeynarUser[]; next_cursor?: string }> {
    try {
      // Clamp limit between 1 and 100 (Neynar's max)
      const clampedLimit = Math.max(1, Math.min(100, limit));

      let url = `/farcaster/following?fid=${fid}&limit=${clampedLimit}`;
      if (cursor) {
        url += `&cursor=${cursor}`;
      }

      const data = await this.fetch(url);
      return {
        users: data.users || [],
        next_cursor: data.next?.cursor,
      };
    } catch (error) {
      console.error('Error fetching following:', error);
      return { users: [] };
    }
  }

  // Get ALL user's following (handles pagination automatically)
  async getAllUserFollowing(fid: number, maxLimit: number = 500): Promise<NeynarUser[]> {
    try {
      const allUsers: NeynarUser[] = [];
      let cursor: string | undefined;
      let hasMore = true;

      while (hasMore && allUsers.length < maxLimit) {
        const remaining = maxLimit - allUsers.length;
        const batchLimit = Math.min(100, remaining);

        const result = await this.getUserFollowing(fid, batchLimit, cursor);
        allUsers.push(...result.users);

        cursor = result.next_cursor;
        hasMore = !!cursor && allUsers.length < maxLimit;

        // Small delay to avoid rate limiting
        if (hasMore) {
          await new Promise(resolve => setTimeout(resolve, 100));
        }
      }

      return allUsers;
    } catch (error) {
      console.error('Error fetching all following:', error);
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

  /**
   * Check the status of a signer
   * Returns signer details including approval status
   */
  async checkSignerStatus(signerUuid: string): Promise<{
    success: boolean;
    status?: 'generated' | 'pending_approval' | 'approved' | 'revoked';
    publicKey?: string;
    fid?: number;
    error?: string;
  }> {
    try {
      console.log('[Neynar] Checking signer status:', signerUuid);

      const response = await this.fetch(`/farcaster/signer?signer_uuid=${signerUuid}`, {
        method: 'GET',
      });

      console.log('[Neynar] Signer status retrieved:', response.status);

      return {
        success: true,
        status: response.status,
        publicKey: response.public_key,
        fid: response.fid,
      };
    } catch (error) {
      console.error('[Neynar] Error checking signer status:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to check signer status',
      };
    }
  }

  // Send a direct cast (requires signer UUID)
  // Returns: { success: true, cast: <Neynar response with nested cast.hash> }
  async sendDirectCast(params: {
    signerUuid: string;
    text: string;
    recipientFid: number;
  }): Promise<{ success: boolean; cast?: any; error?: string }> {
    try {
      console.log('[Neynar] Sending direct cast to FID:', params.recipientFid);

      const response = await this.fetch('/farcaster/cast', {
        method: 'POST',
        body: JSON.stringify({
          signer_uuid: params.signerUuid,
          text: params.text,
          parent: {
            fid: params.recipientFid,
          },
        }),
      });

      console.log('[Neynar] Direct cast sent successfully');
      // Note: Neynar response structure is { cast: { hash: "...", ... } }
      return { success: true, cast: response };
    } catch (error) {
      console.error('[Neynar] Error sending direct cast:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to send direct cast',
      };
    }
  }

  // Publish a cast (public post)
  // Returns: { success: true, cast: <Neynar response with nested cast.hash> }
  async publishCast(params: {
    signerUuid: string;
    text: string;
    embeds?: Array<{ url: string }>;
    mentions?: number[]; // FIDs to mention
  }): Promise<{ success: boolean; cast?: any; error?: string }> {
    try {
      console.log('[Neynar] Publishing cast:', { text: params.text.substring(0, 50) + '...' });

      const body: any = {
        signer_uuid: params.signerUuid,
        text: params.text,
        embeds: params.embeds || [],
      };

      // Add mentions if provided
      if (params.mentions && params.mentions.length > 0) {
        body.mentions = params.mentions;
        console.log('[Neynar] Including mentions:', params.mentions);
      }

      const response = await this.fetch('/farcaster/cast', {
        method: 'POST',
        body: JSON.stringify(body),
      });

      console.log('[Neynar] Cast published successfully');
      // Note: Neynar response structure is { cast: { hash: "...", ... } }
      return { success: true, cast: response };
    } catch (error) {
      console.error('[Neynar] Error publishing cast:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to publish cast',
      };
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
