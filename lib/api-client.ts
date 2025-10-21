// API Client utility with proper error handling

export class ApiError extends Error {
  constructor(
    public status: number,
    message: string,
    public data?: any
  ) {
    super(message);
    this.name = 'ApiError';
  }
}

export async function apiFetch<T = any>(
  url: string,
  options?: RequestInit
): Promise<T> {
  try {
    const response = await fetch(url, options);

    // Check if response is ok (status 200-299)
    if (!response.ok) {
      // Try to parse error as JSON
      let errorMessage = `HTTP ${response.status}: ${response.statusText}`;
      let errorData;

      try {
        const contentType = response.headers.get('content-type');
        if (contentType && contentType.includes('application/json')) {
          errorData = await response.json();
          errorMessage = errorData.error || errorMessage;
        } else {
          // If not JSON, get text
          const text = await response.text();
          errorMessage = text || errorMessage;
        }
      } catch (parseError) {
        // Failed to parse error response, use default message
      }

      throw new ApiError(response.status, errorMessage, errorData);
    }

    // Check if response is JSON
    const contentType = response.headers.get('content-type');
    if (!contentType || !contentType.includes('application/json')) {
      throw new ApiError(
        500,
        'Server returned non-JSON response. This might indicate a server error.',
        { contentType }
      );
    }

    // Parse and return JSON
    const data = await response.json();
    return data as T;
  } catch (error) {
    // Re-throw ApiError as-is
    if (error instanceof ApiError) {
      throw error;
    }

    // Handle network errors
    if (error instanceof TypeError && error.message.includes('fetch')) {
      throw new ApiError(0, 'Network error. Please check your connection.');
    }

    // Handle JSON parse errors
    if (error instanceof SyntaxError) {
      throw new ApiError(
        500,
        'Server returned invalid JSON. This might indicate a server error.'
      );
    }

    // Unknown error
    throw new ApiError(
      500,
      error instanceof Error ? error.message : 'An unknown error occurred'
    );
  }
}

// Convenience methods
export const apiClient = {
  get: <T = any>(url: string) => apiFetch<T>(url, { method: 'GET' }),

  post: <T = any>(url: string, data?: any) =>
    apiFetch<T>(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: data ? JSON.stringify(data) : undefined,
    }),

  patch: <T = any>(url: string, data?: any) =>
    apiFetch<T>(url, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
      },
      body: data ? JSON.stringify(data) : undefined,
    }),

  delete: <T = any>(url: string) => apiFetch<T>(url, { method: 'DELETE' }),
};
