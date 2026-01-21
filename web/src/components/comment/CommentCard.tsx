'use client';

import { useState, useCallback } from 'react';
import { useTranslations } from 'next-intl';
import { Link } from '@/i18n/navigation';
import { useAuth } from '@/contexts/AuthContext';
import { likeComment, unlikeComment, editComment, deleteComment } from '@/lib/api/comments';
import { CommentInput } from './CommentInput';
import type { Comment } from '@/lib/types';

interface CommentCardProps {
  comment: Comment;
  onReply?: (content: string) => Promise<void>;
  onUpdate?: (updatedComment: Comment) => void;
  onDelete?: () => void;
  showReplyButton?: boolean;
  className?: string;
}

export function CommentCard({
  comment,
  onReply,
  onUpdate,
  onDelete,
  showReplyButton = true,
  className = '',
}: CommentCardProps) {
  const t = useTranslations('comments');
  const { user, isAuthenticated } = useAuth();
  const [isLiked, setIsLiked] = useState(comment.isLikedByCurrentUser ?? false);
  const [likeCount, setLikeCount] = useState(comment.likeCount);
  const [isLiking, setIsLiking] = useState(false);
  const [isEditing, setIsEditing] = useState(false);
  const [isReplying, setIsReplying] = useState(false);
  const [isDeleting, setIsDeleting] = useState(false);
  const [showMenu, setShowMenu] = useState(false);

  const isOwner = isAuthenticated && user?.publicId === comment.creatorPublicId;

  const handleLike = useCallback(async () => {
    if (!isAuthenticated || isLiking || comment.isDeleted) return;

    setIsLiking(true);
    try {
      if (isLiked) {
        await unlikeComment(comment.publicId);
        setIsLiked(false);
        setLikeCount((prev) => Math.max(0, prev - 1));
      } else {
        await likeComment(comment.publicId);
        setIsLiked(true);
        setLikeCount((prev) => prev + 1);
      }
    } catch (error) {
      console.error('Failed to toggle like:', error);
    } finally {
      setIsLiking(false);
    }
  }, [isAuthenticated, isLiking, isLiked, comment.publicId, comment.isDeleted]);

  const handleEdit = useCallback(
    async (content: string) => {
      try {
        const updated = await editComment(comment.publicId, content);
        onUpdate?.(updated);
        setIsEditing(false);
      } catch (error) {
        console.error('Failed to edit comment:', error);
        throw error;
      }
    },
    [comment.publicId, onUpdate],
  );

  const handleDelete = useCallback(async () => {
    if (!window.confirm(t('deleteConfirm'))) return;

    setIsDeleting(true);
    try {
      await deleteComment(comment.publicId);
      onDelete?.();
    } catch (error) {
      console.error('Failed to delete comment:', error);
    } finally {
      setIsDeleting(false);
      setShowMenu(false);
    }
  }, [comment.publicId, onDelete, t]);

  const handleReply = useCallback(
    async (content: string) => {
      if (onReply) {
        await onReply(content);
        setIsReplying(false);
      }
    },
    [onReply],
  );

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    const now = new Date();
    const diffMs = now.getTime() - date.getTime();
    const diffMins = Math.floor(diffMs / 60000);
    const diffHours = Math.floor(diffMs / 3600000);
    const diffDays = Math.floor(diffMs / 86400000);

    if (diffMins < 1) return t('justNow');
    if (diffMins < 60) return t('minutesAgo', { count: diffMins });
    if (diffHours < 24) return t('hoursAgo', { count: diffHours });
    if (diffDays < 7) return t('daysAgo', { count: diffDays });

    return date.toLocaleDateString();
  };

  // Deleted comment placeholder
  if (comment.isDeleted) {
    return (
      <div className={`py-3 px-4 bg-[var(--surface)] rounded-lg ${className}`}>
        <p className="text-[var(--text-secondary)] italic">{t('deleted')}</p>
      </div>
    );
  }

  return (
    <div className={`py-3 ${className}`}>
      {/* Header */}
      <div className="flex items-start gap-3">
        {/* Avatar */}
        <Link href={`/users/${comment.creatorPublicId}`} className="flex-shrink-0">
          {comment.creatorProfileImageUrl ? (
            <img
              src={comment.creatorProfileImageUrl}
              alt={comment.creatorUsername}
              className="w-8 h-8 rounded-full object-cover"
            />
          ) : (
            <div className="w-8 h-8 rounded-full bg-[var(--border)] flex items-center justify-center">
              <span className="text-[var(--text-secondary)] text-sm">
                {comment.creatorUsername.charAt(0).toUpperCase()}
              </span>
            </div>
          )}
        </Link>

        {/* Content */}
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2">
            <Link
              href={`/users/${comment.creatorPublicId}`}
              className="font-medium text-[var(--text-primary)] hover:underline"
            >
              {comment.creatorUsername}
            </Link>
            <span className="text-xs text-[var(--text-secondary)]">
              {formatDate(comment.createdAt)}
            </span>
            {comment.isEdited && (
              <span className="text-xs text-[var(--text-secondary)]">({t('edited')})</span>
            )}
          </div>

          {/* Edit mode */}
          {isEditing ? (
            <div className="mt-2">
              <CommentInput
                onSubmit={handleEdit}
                placeholder={comment.content || ''}
                buttonText={t('save')}
                autoFocus
                onCancel={() => setIsEditing(false)}
              />
            </div>
          ) : (
            <p className="mt-1 text-[var(--text-primary)] whitespace-pre-wrap break-words">
              {comment.content}
            </p>
          )}

          {/* Actions */}
          {!isEditing && (
            <div className="flex items-center gap-4 mt-2">
              {/* Like button */}
              <button
                onClick={handleLike}
                disabled={isLiking || !isAuthenticated}
                className={`flex items-center gap-1 text-sm transition-colors ${
                  isLiked
                    ? 'text-[var(--error)]'
                    : 'text-[var(--text-secondary)] hover:text-[var(--error)]'
                } disabled:opacity-50`}
              >
                <svg
                  className="w-4 h-4"
                  fill={isLiked ? 'currentColor' : 'none'}
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                  strokeWidth={2}
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z"
                  />
                </svg>
                {likeCount > 0 && <span>{likeCount}</span>}
              </button>

              {/* Reply button */}
              {showReplyButton && onReply && isAuthenticated && (
                <button
                  onClick={() => setIsReplying(!isReplying)}
                  className="text-sm text-[var(--text-secondary)] hover:text-[var(--primary)] transition-colors"
                >
                  {t('reply')}
                </button>
              )}

              {/* More actions (owner only) */}
              {isOwner && (
                <div className="relative">
                  <button
                    onClick={() => setShowMenu(!showMenu)}
                    className="text-sm text-[var(--text-secondary)] hover:text-[var(--text-primary)] transition-colors"
                  >
                    <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        strokeWidth={2}
                        d="M12 5v.01M12 12v.01M12 19v.01M12 6a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2z"
                      />
                    </svg>
                  </button>

                  {showMenu && (
                    <>
                      <div className="fixed inset-0 z-10" onClick={() => setShowMenu(false)} />
                      <div className="absolute right-0 top-6 z-20 bg-[var(--surface)] border border-[var(--border)] rounded-lg shadow-lg py-1 min-w-[120px]">
                        <button
                          onClick={() => {
                            setIsEditing(true);
                            setShowMenu(false);
                          }}
                          className="w-full px-4 py-2 text-left text-sm text-[var(--text-primary)] hover:bg-[var(--border)] transition-colors"
                        >
                          {t('edit')}
                        </button>
                        <button
                          onClick={handleDelete}
                          disabled={isDeleting}
                          className="w-full px-4 py-2 text-left text-sm text-[var(--error)] hover:bg-[var(--border)] transition-colors disabled:opacity-50"
                        >
                          {isDeleting ? t('deleting') : t('delete')}
                        </button>
                      </div>
                    </>
                  )}
                </div>
              )}
            </div>
          )}

          {/* Reply input */}
          {isReplying && (
            <div className="mt-3">
              <CommentInput
                onSubmit={handleReply}
                placeholder={t('replyPlaceholder')}
                autoFocus
                onCancel={() => setIsReplying(false)}
              />
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
