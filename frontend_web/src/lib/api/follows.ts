import { apiFetch, buildQueryString } from './client';
import type { PaginationParams } from '@/lib/types';

/**
 * Follower/Following user summary
 */
export interface FollowerDto {
  publicId: string;
  username: string;
  profileImageUrl: string | null;
  isFollowingBack: boolean;
  followedAt: string;
}

/**
 * Follow list response
 */
export interface FollowListResponse {
  content: FollowerDto[];
  hasNext: boolean;
  page: number;
  size: number;
}

/**
 * Follow status response
 */
export interface FollowStatusResponse {
  isFollowing: boolean;
}

/**
 * Follow a user
 */
export async function followUser(publicId: string): Promise<void> {
  await apiFetch<void>(`/users/${publicId}/follow`, {
    method: 'POST',
    cache: 'no-store',
  });
}

/**
 * Unfollow a user
 */
export async function unfollowUser(publicId: string): Promise<void> {
  await apiFetch<void>(`/users/${publicId}/follow`, {
    method: 'DELETE',
    cache: 'no-store',
  });
}

/**
 * Get follow status for a user
 */
export async function getFollowStatus(publicId: string): Promise<FollowStatusResponse> {
  return apiFetch<FollowStatusResponse>(`/users/${publicId}/follow-status`, {
    cache: 'no-store',
  });
}

/**
 * Get followers of a user
 */
export async function getFollowers(
  publicId: string,
  params: PaginationParams = {}
): Promise<FollowListResponse> {
  const queryString = buildQueryString({
    page: params.page ?? 0,
    size: params.size ?? 20,
  });

  return apiFetch<FollowListResponse>(`/users/${publicId}/followers${queryString}`, {
    next: { revalidate: 60 },
  });
}

/**
 * Get users that a user is following
 */
export async function getFollowing(
  publicId: string,
  params: PaginationParams = {}
): Promise<FollowListResponse> {
  const queryString = buildQueryString({
    page: params.page ?? 0,
    size: params.size ?? 20,
  });

  return apiFetch<FollowListResponse>(`/users/${publicId}/following${queryString}`, {
    next: { revalidate: 60 },
  });
}
