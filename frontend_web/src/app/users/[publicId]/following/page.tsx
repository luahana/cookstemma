'use client';

import { useState, useEffect, useCallback } from 'react';
import Image from 'next/image';
import Link from 'next/link';
import { useParams } from 'next/navigation';
import { getFollowing, type FollowerDto } from '@/lib/api/follows';
import { getUserProfile } from '@/lib/api/users';
import { FollowButton } from '@/components/common/FollowButton';
import { getImageUrl } from '@/lib/utils/image';
import type { UserProfile } from '@/lib/types';

export default function FollowingPage() {
  const params = useParams();
  const publicId = params.publicId as string;

  const [user, setUser] = useState<UserProfile | null>(null);
  const [following, setFollowing] = useState<FollowerDto[]>([]);
  const [page, setPage] = useState(0);
  const [hasNext, setHasNext] = useState(false);
  const [isLoading, setIsLoading] = useState(true);

  const loadData = useCallback(async () => {
    try {
      const [userData, followingData] = await Promise.all([
        getUserProfile(publicId),
        getFollowing(publicId, { page, size: 20 }),
      ]);

      setUser(userData);

      if (page === 0) {
        setFollowing(followingData.content);
      } else {
        setFollowing((prev) => [...prev, ...followingData.content]);
      }
      setHasNext(followingData.hasNext);
    } catch (error) {
      console.error('Failed to load following:', error);
    } finally {
      setIsLoading(false);
    }
  }, [publicId, page]);

  useEffect(() => {
    loadData();
  }, [loadData]);

  const loadMore = () => {
    if (hasNext && !isLoading) {
      setPage((prev) => prev + 1);
    }
  };

  if (isLoading && page === 0) {
    return (
      <div className="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="animate-pulse">
          <div className="h-8 bg-[var(--border)] rounded w-48 mb-4"></div>
          <div className="h-4 bg-[var(--border)] rounded w-64 mb-8"></div>
          {[...Array(5)].map((_, i) => (
            <div key={i} className="flex items-center gap-4 py-4 border-b border-[var(--border)]">
              <div className="w-12 h-12 bg-[var(--border)] rounded-full"></div>
              <div className="flex-1">
                <div className="h-5 bg-[var(--border)] rounded w-32 mb-2"></div>
                <div className="h-4 bg-[var(--border)] rounded w-24"></div>
              </div>
            </div>
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      {/* Header */}
      <div className="mb-6">
        <Link
          href={`/users/${publicId}`}
          className="text-sm text-[var(--text-secondary)] hover:text-[var(--primary)] mb-2 inline-block"
        >
          &larr; Back to {user?.username}&apos;s profile
        </Link>
        <h1 className="text-2xl font-bold text-[var(--text-primary)]">Following</h1>
        <p className="text-[var(--text-secondary)] mt-1">
          {user?.followingCount} following
        </p>
      </div>

      {/* Following list */}
      {following.length === 0 ? (
        <div className="text-center py-12">
          <svg
            className="w-16 h-16 mx-auto text-[var(--text-secondary)] opacity-50"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={1.5}
              d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"
            />
          </svg>
          <h3 className="mt-4 text-lg font-medium text-[var(--text-primary)]">
            Not following anyone
          </h3>
          <p className="mt-2 text-[var(--text-secondary)]">
            When {user?.username} follows people, they&apos;ll appear here.
          </p>
        </div>
      ) : (
        <div className="bg-[var(--surface)] border border-[var(--border)] rounded-2xl divide-y divide-[var(--border)]">
          {following.map((followedUser) => (
            <div key={followedUser.publicId} className="flex items-center gap-4 p-4">
              <Link
                href={`/users/${followedUser.publicId}`}
                className="flex-shrink-0"
              >
                <div className="relative w-12 h-12 rounded-full overflow-hidden bg-[var(--primary-light)]">
                  {getImageUrl(followedUser.profileImageUrl) ? (
                    <Image
                      src={getImageUrl(followedUser.profileImageUrl)!}
                      alt={followedUser.username}
                      fill
                      className="object-cover"
                      sizes="48px"
                    />
                  ) : (
                    <div className="w-full h-full flex items-center justify-center text-lg text-[var(--primary)]">
                      {followedUser.username[0].toUpperCase()}
                    </div>
                  )}
                </div>
              </Link>

              <div className="flex-1 min-w-0">
                <Link
                  href={`/users/${followedUser.publicId}`}
                  className="font-medium text-[var(--text-primary)] hover:text-[var(--primary)]"
                >
                  {followedUser.username}
                </Link>
                {followedUser.isFollowingBack && (
                  <p className="text-sm text-[var(--text-secondary)]">
                    Follows {user?.username} back
                  </p>
                )}
              </div>

              <FollowButton targetUserPublicId={followedUser.publicId} />
            </div>
          ))}
        </div>
      )}

      {/* Load more */}
      {hasNext && (
        <div className="mt-6 text-center">
          <button
            onClick={loadMore}
            disabled={isLoading}
            className="px-6 py-2 bg-[var(--background)] text-[var(--text-primary)] rounded-lg hover:bg-[var(--border)] transition-colors disabled:opacity-50"
          >
            {isLoading ? 'Loading...' : 'Load more'}
          </button>
        </div>
      )}
    </div>
  );
}
