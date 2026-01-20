import { apiFetch, buildQueryString } from './client';
import type {
  LogPostSummary,
  LogPostDetail,
  CreateLogRequest,
  UpdateLogRequest,
  UnifiedPageResponse,
  PaginationParams,
} from '@/lib/types';

interface LogSearchParams extends PaginationParams {
  q?: string;
  minRating?: number; // 1-5
  maxRating?: number; // 1-5
  sort?: 'recent' | 'popular' | 'trending';
}

/**
 * Get paginated list of log posts with optional search/filter
 */
export async function getLogs(
  params: LogSearchParams = {},
  locale?: string,
): Promise<UnifiedPageResponse<LogPostSummary>> {
  const queryString = buildQueryString({
    page: params.page ?? 0,
    size: params.size ?? 20,
    q: params.q,
    minRating: params.minRating,
    maxRating: params.maxRating,
    sort: params.sort,
  });

  return apiFetch<UnifiedPageResponse<LogPostSummary>>(`/log_posts${queryString}`, {
    next: { revalidate: 60 },
    locale,
  });
}

/**
 * Get log post detail by publicId
 */
export async function getLogDetail(
  publicId: string,
  locale?: string,
): Promise<LogPostDetail> {
  return apiFetch<LogPostDetail>(`/log_posts/${publicId}`, {
    next: { revalidate: 300 },
    locale,
  });
}

/**
 * Get logs for a specific recipe
 */
export async function getLogsByRecipe(
  recipePublicId: string,
  params: PaginationParams = {},
): Promise<UnifiedPageResponse<LogPostSummary>> {
  const queryString = buildQueryString({
    page: params.page ?? 0,
    size: params.size ?? 20,
  });

  return apiFetch<UnifiedPageResponse<LogPostSummary>>(
    `/log_posts/recipe/${recipePublicId}${queryString}`,
    {
      next: { revalidate: 60 },
    },
  );
}

/**
 * Get all log IDs for sitemap generation
 */
export async function getAllLogIds(): Promise<string[]> {
  const result = await apiFetch<UnifiedPageResponse<LogPostSummary>>(
    '/log_posts?page=0&size=500',
    {
      next: { revalidate: 3600 },
    },
  );
  return result.content.map((l) => l.publicId);
}

/**
 * Update an existing log post
 * Requires ownership (images are read-only after creation)
 */
export async function updateLog(
  publicId: string,
  data: UpdateLogRequest,
): Promise<LogPostDetail> {
  return apiFetch<LogPostDetail>(`/log_posts/${publicId}`, {
    method: 'PUT',
    body: JSON.stringify(data),
    cache: 'no-store',
  });
}

/**
 * Delete a log post (soft delete)
 * Requires ownership
 */
export async function deleteLog(publicId: string): Promise<void> {
  await apiFetch<void>(`/log_posts/${publicId}`, {
    method: 'DELETE',
    cache: 'no-store',
  });
}

/**
 * Create a new log post
 * Requires authentication
 */
export async function createLog(data: CreateLogRequest): Promise<LogPostDetail> {
  return apiFetch<LogPostDetail>('/log_posts', {
    method: 'POST',
    body: JSON.stringify(data),
    cache: 'no-store',
  });
}
