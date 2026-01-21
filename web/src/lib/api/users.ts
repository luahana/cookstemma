import { apiFetch, buildQueryString } from './client';
import type {
  UserProfile,
  RecipeSummary,
  LogPostSummary,
  UnifiedPageResponse,
  PaginationParams,
  MyProfileResponse,
  UpdateProfileRequest,
} from '@/lib/types';

// Backend returns Slice for user recipes/logs
interface SliceResponse<T> {
  content: T[];
  last: boolean;
  size: number;
  number: number;
}

/**
 * Get user profile by publicId
 */
export async function getUserProfile(publicId: string): Promise<UserProfile> {
  return apiFetch<UserProfile>(`/users/${publicId}`, {
    next: { revalidate: 300 },
  });
}

/**
 * Get user's recipes
 */
export async function getUserRecipes(
  userId: string,
  params: PaginationParams & {
    typeFilter?: 'original' | 'variants';
    visibility?: 'all' | 'public' | 'private';
    contentLocale?: string;
  } = {},
): Promise<SliceResponse<RecipeSummary>> {
  const queryString = buildQueryString({
    page: params.page ?? 0,
    size: params.size ?? 20,
    typeFilter: params.typeFilter,
    visibility: params.visibility ?? 'public',
  });

  return apiFetch<SliceResponse<RecipeSummary>>(
    `/users/${userId}/recipes${queryString}`,
    {
      next: { revalidate: 60 },
      locale: params.contentLocale,
    },
  );
}

/**
 * Get user's logs
 */
export async function getUserLogs(
  userId: string,
  params: PaginationParams & {
    visibility?: 'all' | 'public' | 'private';
    contentLocale?: string;
  } = {},
): Promise<SliceResponse<LogPostSummary>> {
  const queryString = buildQueryString({
    page: params.page ?? 0,
    size: params.size ?? 20,
    visibility: params.visibility ?? 'public',
  });

  return apiFetch<SliceResponse<LogPostSummary>>(
    `/users/${userId}/logs${queryString}`,
    {
      next: { revalidate: 60 },
      locale: params.contentLocale,
    },
  );
}

/**
 * Get current user's profile (authenticated)
 */
export async function getMyProfile(): Promise<MyProfileResponse> {
  return apiFetch<MyProfileResponse>('/users/me', {
    cache: 'no-store',
  });
}

/**
 * Update current user's profile
 */
export async function updateUserProfile(
  data: UpdateProfileRequest,
): Promise<UserProfile> {
  return apiFetch<UserProfile>('/users/me', {
    method: 'PATCH',
    body: JSON.stringify(data),
  });
}

/**
 * Get all user IDs for sitemap generation
 */
export async function getAllUserIds(): Promise<string[]> {
  return apiFetch<string[]>('/users/sitemap', {
    next: { revalidate: 3600 }, // Cache for 1 hour
  });
}

/**
 * Check if a username is available for use
 */
export async function checkUsernameAvailability(
  username: string,
): Promise<boolean> {
  const response = await apiFetch<{ available: boolean }>(
    `/users/check-username?username=${encodeURIComponent(username)}`,
    {
      cache: 'no-store',
    },
  );
  return response.available;
}
