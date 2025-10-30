// API Client utility with proper error handling

export class ApiError extends Error {
  constructor(
    public status: number,
    message: string,
    public data?: unknown
  ) {
    super(message);
    this.name = 'ApiError';
  }
}

export async function apiFetch<T = unknown>(
  url: string,
  options?: RequestInit
): Promise<T | null> {
  try {
    const response = await fetch(url, options);

    // Check if response is ok (status 200-299)
    if (!response.ok) {
      let errorMessage = `HTTP ${response.status}: ${response.statusText}`;
      let errorData;

      try {
        const contentType = response.headers.get('content-type');
        if (contentType && contentType.includes('application/json')) {
          errorData = await response.json();
          errorMessage = errorData.error || errorMessage;
        } else {
          const text = await response.text();
          errorMessage = text || errorMessage;
        }
      } catch {
        // ignore parsing errors
      }

      if (response.status === 404 || errorMessage.toLowerCase().includes('user not found')) {
        console.log(`[API] User not found (404): ${url}`);
        return null;
      }

      throw new ApiError(response.status, errorMessage, errorData);
    }

    const contentType = response.headers.get('content-type');
    if (!contentType || !contentType.includes('application/json')) {
      throw new ApiError(
        500,
        'Server returned non-JSON response. This might indicate a server error.',
        { contentType }
      );
    }

    const data = await response.json();
    return data as T;
  } catch (error) {
    if (error instanceof ApiError) throw error;

    if (error instanceof TypeError && error.message.includes('fetch')) {
      throw new ApiError(0, 'Network error. Please check your connection.');
    }

    if (error instanceof SyntaxError) {
      throw new ApiError(
        500,
        'Server returned invalid JSON. This might indicate a server error.'
      );
    }

    throw new ApiError(
      500,
      error instanceof Error ? error.message : 'An unknown error occurred'
    );
  }
}

// Convenience methods
export const apiClient = {
  get: <T = unknown>(url: string) => apiFetch<T>(url, { method: 'GET' }),

  post: <T = unknown>(url: string, data?: unknown) =>
    apiFetch<T>(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: data ? JSON.stringify(data) : undefined,
    }),

  patch: <T = unknown>(url: string, data?: unknown) =>
    apiFetch<T>(url, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
      },
      body: data ? JSON.stringify(data) : undefined,
    }),

  delete: <T = unknown>(url: string) => apiFetch<T>(url, { method: 'DELETE' }),
};

/**
 * Decline a match for both participants (bilateral decline)
 * This is the new permanent fix for the cooldown conflict issue
 */
export async function declineAllMatch(matchId: string): Promise<{
  success: boolean;
  reason?: string;
  message?: string;
  match?: unknown;
}> {
  const response = await apiClient.post<{
    success: boolean;
    reason?: string;
    message?: string;
    match?: unknown;
  }>(`/api/matches/${matchId}/decline-all`);

  if (!response) {
    return {
      success: false,
      reason: 'No response from API',
      message: 'Server returned null',
      match: null,
    };
  }

  // ensure required field exists even if server forgets to include it
  return {
    success: (response as any).success ?? true,
    reason: (response as any).reason,
    message: (response as any).message,
    match: (response as any).match,
  };
}

/**
 * Fetch MeetShipper conversation rooms for given match IDs
 */
export async function fetchMeetshipperRooms(
  matchIds: string[]
): Promise<Map<string, string>> {
  if (matchIds.length === 0) {
    return new Map();
  }

  const response = await apiClient.get<{
    success: boolean;
    data: Array<{ id: string; match_id: string }>;
  }>(`/api/meetshipper-rooms/by-matches?matchIds=${matchIds.join(',')}`);

  if (!response || !response.data) {
    return new Map();
  }

  const roomMap = new Map<string, string>();
  response.data.forEach((room) => {
    roomMap.set(room.match_id, room.id);
  });

  return roomMap;
}

/**
 * Close a MeetShipper conversation room permanently
 */
export async function closeMeetshipperRoom(
  roomId: string
): Promise<{
  success: boolean;
  room?: unknown;
  error?: string;
}> {
  const response = await apiClient.post<{
    success: boolean;
    room?: unknown;
    error?: string;
  }>(`/api/meetshipper-rooms/${roomId}/close`);

  if (!response) {
    return {
      success: false,
      error: 'No response from API',
    };
  }

  return {
    success: response.success ?? false,
    room: response.room,
    error: response.error,
  };
}