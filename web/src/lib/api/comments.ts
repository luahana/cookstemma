import { apiFetch, buildQueryString } from './client';
import type {
  Comment,
  CommentWithReplies,
  CommentsPage,
  RepliesPage,
  CreateCommentRequest,
  PaginationParams,
} from '@/lib/types';

/**
 * Get paginated comments for a log post with preview replies
 */
export async function getComments(
  logPublicId: string,
  params: PaginationParams = {},
): Promise<CommentsPage> {
  const queryString = buildQueryString({
    page: params.page ?? 0,
    size: params.size ?? 20,
  });

  return apiFetch<CommentsPage>(`/log_posts/${logPublicId}/comments${queryString}`, {
    cache: 'no-store',
  });
}

/**
 * Create a top-level comment on a log post
 * Requires authentication
 */
export async function createComment(
  logPublicId: string,
  content: string,
): Promise<Comment> {
  return apiFetch<Comment>(`/log_posts/${logPublicId}/comments`, {
    method: 'POST',
    body: JSON.stringify({ content } as CreateCommentRequest),
    cache: 'no-store',
  });
}

/**
 * Get paginated replies for a comment
 */
export async function getReplies(
  commentPublicId: string,
  params: PaginationParams = {},
): Promise<RepliesPage> {
  const queryString = buildQueryString({
    page: params.page ?? 0,
    size: params.size ?? 20,
  });

  return apiFetch<RepliesPage>(`/comments/${commentPublicId}/replies${queryString}`, {
    cache: 'no-store',
  });
}

/**
 * Create a reply to a comment
 * Requires authentication
 */
export async function createReply(
  commentPublicId: string,
  content: string,
): Promise<Comment> {
  return apiFetch<Comment>(`/comments/${commentPublicId}/replies`, {
    method: 'POST',
    body: JSON.stringify({ content } as CreateCommentRequest),
    cache: 'no-store',
  });
}

/**
 * Edit a comment
 * Requires ownership
 */
export async function editComment(
  commentPublicId: string,
  content: string,
): Promise<Comment> {
  return apiFetch<Comment>(`/comments/${commentPublicId}`, {
    method: 'PUT',
    body: JSON.stringify({ content } as CreateCommentRequest),
    cache: 'no-store',
  });
}

/**
 * Delete a comment (soft delete)
 * Requires ownership
 */
export async function deleteComment(commentPublicId: string): Promise<void> {
  await apiFetch<void>(`/comments/${commentPublicId}`, {
    method: 'DELETE',
    cache: 'no-store',
  });
}

/**
 * Like a comment
 * Requires authentication
 */
export async function likeComment(commentPublicId: string): Promise<void> {
  await apiFetch<void>(`/comments/${commentPublicId}/like`, {
    method: 'POST',
    cache: 'no-store',
  });
}

/**
 * Unlike a comment
 * Requires authentication
 */
export async function unlikeComment(commentPublicId: string): Promise<void> {
  await apiFetch<void>(`/comments/${commentPublicId}/like`, {
    method: 'DELETE',
    cache: 'no-store',
  });
}
