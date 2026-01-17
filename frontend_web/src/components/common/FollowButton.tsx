'use client';

import { useState, useCallback, useEffect } from 'react';
import { useAuth } from '@/contexts/AuthContext';
import { followUser, unfollowUser, getFollowStatus } from '@/lib/api/follows';

interface FollowButtonProps {
  targetUserPublicId: string;
  initialFollowing?: boolean;
  onFollowChange?: (isFollowing: boolean) => void;
  className?: string;
}

export function FollowButton({
  targetUserPublicId,
  initialFollowing,
  onFollowChange,
  className = '',
}: FollowButtonProps) {
  const { user, isAuthenticated } = useAuth();
  const [isFollowing, setIsFollowing] = useState(initialFollowing ?? false);
  const [isLoading, setIsLoading] = useState(initialFollowing === undefined);
  const [isUpdating, setIsUpdating] = useState(false);

  // Fetch follow status on mount if not provided
  useEffect(() => {
    if (initialFollowing === undefined && isAuthenticated) {
      getFollowStatus(targetUserPublicId)
        .then((status) => {
          setIsFollowing(status.isFollowing);
        })
        .catch(console.error)
        .finally(() => setIsLoading(false));
    }
  }, [targetUserPublicId, initialFollowing, isAuthenticated]);

  const handleClick = useCallback(async () => {
    if (!isAuthenticated || isUpdating) return;

    setIsUpdating(true);
    try {
      if (isFollowing) {
        await unfollowUser(targetUserPublicId);
        setIsFollowing(false);
        onFollowChange?.(false);
      } else {
        await followUser(targetUserPublicId);
        setIsFollowing(true);
        onFollowChange?.(true);
      }
    } catch (error) {
      console.error('Failed to toggle follow:', error);
    } finally {
      setIsUpdating(false);
    }
  }, [isAuthenticated, isUpdating, isFollowing, targetUserPublicId, onFollowChange]);

  // Don't render if not authenticated or viewing own profile
  if (!isAuthenticated || user?.publicId === targetUserPublicId) {
    return null;
  }

  if (isLoading) {
    return (
      <button
        disabled
        className={`px-4 py-2 rounded-lg text-sm font-medium bg-[var(--background)] text-[var(--text-secondary)] ${className}`}
      >
        Loading...
      </button>
    );
  }

  return (
    <button
      onClick={handleClick}
      disabled={isUpdating}
      className={`
        px-4 py-2 rounded-lg text-sm font-medium transition-colors
        disabled:opacity-50 disabled:cursor-not-allowed
        ${
          isFollowing
            ? 'bg-[var(--background)] text-[var(--text-primary)] border border-[var(--border)] hover:bg-[var(--border)] hover:text-[var(--error)]'
            : 'bg-[var(--primary)] text-white hover:bg-[var(--primary-dark)]'
        }
        ${className}
      `}
    >
      {isUpdating ? (
        <span className="flex items-center gap-2">
          <svg className="animate-spin w-4 h-4" viewBox="0 0 24 24">
            <circle
              className="opacity-25"
              cx="12"
              cy="12"
              r="10"
              stroke="currentColor"
              strokeWidth="4"
              fill="none"
            />
            <path
              className="opacity-75"
              fill="currentColor"
              d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
            />
          </svg>
          {isFollowing ? 'Unfollowing...' : 'Following...'}
        </span>
      ) : isFollowing ? (
        'Following'
      ) : (
        'Follow'
      )}
    </button>
  );
}
