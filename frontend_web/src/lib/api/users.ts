import { apiFetch, buildQueryString } from './client';
import type {
  UserProfile,
  RecipeSummary,
  LogPostSummary,
  UnifiedPageResponse,
  PaginationParams,
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
  params: PaginationParams & { typeFilter?: 'original' | 'variants' } = {},
): Promise<SliceResponse<RecipeSummary>> {
  const queryString = buildQueryString({
    page: params.page ?? 0,
    size: params.size ?? 20,
    typeFilter: params.typeFilter,
  });

  return apiFetch<SliceResponse<RecipeSummary>>(
    `/users/${userId}/recipes${queryString}`,
    {
      next: { revalidate: 60 },
    },
  );
}

/**
 * Get user's logs
 */
export async function getUserLogs(
  userId: string,
  params: PaginationParams = {},
): Promise<SliceResponse<LogPostSummary>> {
  const queryString = buildQueryString({
    page: params.page ?? 0,
    size: params.size ?? 20,
  });

  return apiFetch<SliceResponse<LogPostSummary>>(
    `/users/${userId}/logs${queryString}`,
    {
      next: { revalidate: 60 },
    },
  );
}
