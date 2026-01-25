import { apiFetch } from './client';

export type ReportReason =
  | 'SPAM'
  | 'HARASSMENT'
  | 'INAPPROPRIATE_CONTENT'
  | 'IMPERSONATION'
  | 'OTHER';

export interface BlockStatus {
  isBlocked: boolean;
  amBlocked: boolean;
}

/**
 * Block a user
 */
export async function blockUser(userPublicId: string): Promise<void> {
  return apiFetch<void>(`/users/${userPublicId}/block`, {
    method: 'POST',
  });
}

/**
 * Unblock a user
 */
export async function unblockUser(userPublicId: string): Promise<void> {
  return apiFetch<void>(`/users/${userPublicId}/block`, {
    method: 'DELETE',
  });
}

/**
 * Get block status between current user and target user
 */
export async function getBlockStatus(
  userPublicId: string,
): Promise<BlockStatus> {
  return apiFetch<BlockStatus>(`/users/${userPublicId}/block-status`, {
    cache: 'no-store',
  });
}

/**
 * Report a user
 */
export async function reportUser(
  userPublicId: string,
  reason: ReportReason,
  description?: string,
): Promise<void> {
  return apiFetch<void>(`/users/${userPublicId}/report`, {
    method: 'POST',
    body: JSON.stringify({ reason, description }),
  });
}
