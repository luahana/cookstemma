'use client';

import { useState, useCallback, useEffect } from 'react';
import { useTranslations } from 'next-intl';
import { getComments, createComment, createReply, getReplies } from '@/lib/api/comments';
import { CommentInput } from './CommentInput';
import { CommentCard } from './CommentCard';
import type { Comment, CommentWithReplies, CommentsPage } from '@/lib/types';

interface CommentSectionProps {
  logPublicId: string;
  initialCommentCount?: number;
  className?: string;
}

export function CommentSection({
  logPublicId,
  initialCommentCount = 0,
  className = '',
}: CommentSectionProps) {
  const t = useTranslations('comments');
  const [comments, setComments] = useState<CommentWithReplies[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [currentPage, setCurrentPage] = useState(0);
  const [totalPages, setTotalPages] = useState(0);
  const [totalComments, setTotalComments] = useState(initialCommentCount);
  const [error, setError] = useState<string | null>(null);
  const [blockedUserIds, setBlockedUserIds] = useState<Set<string>>(new Set());

  // Load comments
  const loadComments = useCallback(
    async (page: number, append = false) => {
      try {
        setError(null);
        const response: CommentsPage = await getComments(logPublicId, { page, size: 10 });
        setComments((prev) => (append ? [...prev, ...response.content] : response.content));
        setCurrentPage(response.number);
        setTotalPages(response.totalPages);
        setTotalComments(response.totalElements);
      } catch (err) {
        console.error('Failed to load comments:', err);
        setError(t('loadError'));
      } finally {
        setIsLoading(false);
      }
    },
    [logPublicId, t],
  );

  // Initial load
  useEffect(() => {
    loadComments(0);
  }, [loadComments]);

  // Handle new comment
  const handleCreateComment = useCallback(
    async (content: string) => {
      const newComment = await createComment(logPublicId, content);
      // Add to top of list
      setComments((prev) => [
        {
          comment: newComment,
          replies: [],
          hasMoreReplies: false,
        },
        ...prev,
      ]);
      setTotalComments((prev) => prev + 1);
    },
    [logPublicId],
  );

  // Handle reply
  const handleCreateReply = useCallback(
    async (parentComment: CommentWithReplies, content: string) => {
      const newReply = await createReply(parentComment.comment.publicId, content);
      // Add reply to the comment
      setComments((prev) =>
        prev.map((c) => {
          if (c.comment.publicId === parentComment.comment.publicId) {
            return {
              ...c,
              comment: {
                ...c.comment,
                replyCount: c.comment.replyCount + 1,
              },
              replies: [...c.replies, newReply],
            };
          }
          return c;
        }),
      );
      setTotalComments((prev) => prev + 1);
    },
    [],
  );

  // Handle load more replies
  const handleLoadMoreReplies = useCallback(async (commentWithReplies: CommentWithReplies) => {
    try {
      const response = await getReplies(commentWithReplies.comment.publicId, { page: 0, size: 50 });
      setComments((prev) =>
        prev.map((c) => {
          if (c.comment.publicId === commentWithReplies.comment.publicId) {
            return {
              ...c,
              replies: response.content,
              hasMoreReplies: false,
            };
          }
          return c;
        }),
      );
    } catch (err) {
      console.error('Failed to load replies:', err);
    }
  }, []);

  // Handle comment update
  const handleUpdateComment = useCallback(
    (commentPublicId: string, updatedComment: Comment, isReply = false, parentId?: string) => {
      setComments((prev) =>
        prev.map((c) => {
          if (isReply && parentId && c.comment.publicId === parentId) {
            return {
              ...c,
              replies: c.replies.map((r) =>
                r.publicId === commentPublicId ? updatedComment : r,
              ),
            };
          }
          if (!isReply && c.comment.publicId === commentPublicId) {
            return {
              ...c,
              comment: updatedComment,
            };
          }
          return c;
        }),
      );
    },
    [],
  );

  // Handle comment delete
  const handleDeleteComment = useCallback(
    (commentPublicId: string, isReply = false, parentId?: string) => {
      if (isReply && parentId) {
        setComments((prev) =>
          prev.map((c) => {
            if (c.comment.publicId === parentId) {
              return {
                ...c,
                comment: {
                  ...c.comment,
                  replyCount: Math.max(0, c.comment.replyCount - 1),
                },
                replies: c.replies.filter((r) => r.publicId !== commentPublicId),
              };
            }
            return c;
          }),
        );
      } else {
        setComments((prev) => prev.filter((c) => c.comment.publicId !== commentPublicId));
      }
      setTotalComments((prev) => Math.max(0, prev - 1));
    },
    [],
  );

  // Handle user blocked
  const handleUserBlocked = useCallback((blockedUserId: string) => {
    setBlockedUserIds((prev) => new Set(prev).add(blockedUserId));
  }, []);

  // Load more comments
  const handleLoadMore = useCallback(() => {
    if (currentPage < totalPages - 1) {
      loadComments(currentPage + 1, true);
    }
  }, [currentPage, totalPages, loadComments]);

  return (
    <section className={`${className}`}>
      {/* Header */}
      <h2 className="text-xl font-bold text-[var(--text-primary)] mb-4">
        {t('title')} {totalComments > 0 && <span className="text-[var(--text-secondary)]">({totalComments})</span>}
      </h2>

      {/* New comment input */}
      <CommentInput onSubmit={handleCreateComment} className="mb-6" />

      {/* Error message */}
      {error && (
        <div className="mb-4 p-3 bg-[var(--error)]/10 text-[var(--error)] rounded-lg text-sm">
          {error}
        </div>
      )}

      {/* Loading state */}
      {isLoading && (
        <div className="flex justify-center py-8">
          <div className="animate-spin w-6 h-6 border-2 border-[var(--primary)] border-t-transparent rounded-full" />
        </div>
      )}

      {/* Comments list */}
      {!isLoading && comments.length === 0 && (
        <div className="text-center py-8 text-[var(--text-secondary)]">{t('noComments')}</div>
      )}

      {!isLoading && comments.length > 0 && (
        <div className="divide-y divide-[var(--border)]">
          {comments
            .filter((c) => !blockedUserIds.has(c.comment.creatorPublicId))
            .map((commentWithReplies) => {
              const filteredReplies = commentWithReplies.replies.filter(
                (reply) => !blockedUserIds.has(reply.creatorPublicId),
              );
              return (
                <div key={commentWithReplies.comment.publicId}>
                  {/* Top-level comment */}
                  <CommentCard
                    comment={commentWithReplies.comment}
                    onReply={(content) => handleCreateReply(commentWithReplies, content)}
                    onUpdate={(updated) =>
                      handleUpdateComment(commentWithReplies.comment.publicId, updated)
                    }
                    onDelete={() => handleDeleteComment(commentWithReplies.comment.publicId)}
                    onBlock={handleUserBlocked}
                  />

                  {/* Replies */}
                  {filteredReplies.length > 0 && (
                    <div className="ml-11 border-l-2 border-[var(--border)] pl-4">
                      {filteredReplies.map((reply) => (
                        <CommentCard
                          key={reply.publicId}
                          comment={reply}
                          showReplyButton={false}
                          onUpdate={(updated) =>
                            handleUpdateComment(
                              reply.publicId,
                              updated,
                              true,
                              commentWithReplies.comment.publicId,
                            )
                          }
                          onDelete={() =>
                            handleDeleteComment(
                              reply.publicId,
                              true,
                              commentWithReplies.comment.publicId,
                            )
                          }
                          onBlock={handleUserBlocked}
                        />
                      ))}
                    </div>
                  )}

                  {/* Load more replies button */}
                  {commentWithReplies.hasMoreReplies && (
                    <button
                      onClick={() => handleLoadMoreReplies(commentWithReplies)}
                      className="ml-11 mb-3 text-sm text-[var(--primary)] hover:underline"
                    >
                      {t('viewReplies', {
                        count:
                          commentWithReplies.comment.replyCount - commentWithReplies.replies.length,
                      })}
                    </button>
                  )}
                </div>
              );
            })}
        </div>
      )}

      {/* Load more comments button */}
      {!isLoading && currentPage < totalPages - 1 && (
        <div className="mt-4 text-center">
          <button
            onClick={handleLoadMore}
            className="px-6 py-2 text-sm font-medium text-[var(--primary)] hover:bg-[var(--primary)]/10 rounded-lg transition-colors"
          >
            {t('loadMore')}
          </button>
        </div>
      )}
    </section>
  );
}
