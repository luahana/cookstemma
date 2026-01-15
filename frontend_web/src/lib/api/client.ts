import Cookies from 'js-cookie';
import { siteConfig } from '@/config/site';

export class ApiError extends Error {
  constructor(
    public status: number,
    message: string,
  ) {
    super(message);
    this.name = 'ApiError';
  }
}

interface FetchOptions extends RequestInit {
  next?: {
    revalidate?: number | false;
    tags?: string[];
  };
  skipAuth?: boolean;
}

// Track if we're currently refreshing to avoid multiple refresh calls
let isRefreshing = false;
let refreshPromise: Promise<boolean> | null = null;

async function refreshTokens(): Promise<boolean> {
  try {
    const response = await fetch(`${siteConfig.apiUrl}/auth/web/reissue`, {
      method: 'POST',
      credentials: 'include',
      headers: {
        'X-CSRF-Token': Cookies.get('csrf_token') || '',
      },
    });
    return response.ok;
  } catch {
    return false;
  }
}

async function ensureValidToken(): Promise<boolean> {
  if (isRefreshing) {
    return refreshPromise || Promise.resolve(false);
  }

  isRefreshing = true;
  refreshPromise = refreshTokens().finally(() => {
    isRefreshing = false;
    refreshPromise = null;
  });

  return refreshPromise;
}

function getCsrfHeader(method: string | undefined): Record<string, string> {
  // Only add CSRF token for write operations
  const writeOps = ['POST', 'PUT', 'DELETE', 'PATCH'];
  if (method && writeOps.includes(method.toUpperCase())) {
    const csrfToken = Cookies.get('csrf_token');
    if (csrfToken) {
      return { 'X-CSRF-Token': csrfToken };
    }
  }
  return {};
}

export async function apiFetch<T>(
  endpoint: string,
  options: FetchOptions = {},
): Promise<T> {
  const url = `${siteConfig.apiUrl}${endpoint}`;
  const { skipAuth, ...fetchOptions } = options;

  const makeRequest = async () => {
    return fetch(url, {
      ...fetchOptions,
      credentials: 'include',
      headers: {
        'Content-Type': 'application/json',
        ...getCsrfHeader(fetchOptions.method),
        ...fetchOptions.headers,
      },
    });
  };

  let response = await makeRequest();

  // If 401 and not skipping auth, try refreshing token and retry once
  if (response.status === 401 && !skipAuth) {
    const refreshed = await ensureValidToken();
    if (refreshed) {
      response = await makeRequest();
    }
  }

  if (!response.ok) {
    let errorMessage = `API Error ${response.status}`;
    try {
      const errorBody = await response.text();
      if (errorBody) {
        errorMessage += `: ${errorBody}`;
      }
    } catch {
      // Ignore error reading body
    }
    throw new ApiError(response.status, errorMessage);
  }

  return response.json();
}

// Helper to build query string from params object
export function buildQueryString(
  params: Record<string, string | number | boolean | undefined>,
): string {
  const searchParams = new URLSearchParams();

  Object.entries(params).forEach(([key, value]) => {
    if (value !== undefined && value !== null && value !== '') {
      searchParams.set(key, String(value));
    }
  });

  const queryString = searchParams.toString();
  return queryString ? `?${queryString}` : '';
}
