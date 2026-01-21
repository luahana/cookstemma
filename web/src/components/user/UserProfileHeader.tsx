'use client';

import Image from 'next/image';
import { Link } from '@/i18n/navigation';
import { useState } from 'react';
import { useTranslations } from 'next-intl';
import type { UserProfile } from '@/lib/types';
import { getNextTierKey, getXpToNextTier } from '@/lib/types/user';
import { getImageUrl } from '@/lib/utils/image';
import { getAvatarInitial } from '@/lib/utils/string';
import { FollowButton } from '@/components/common/FollowButton';
import { UserActions } from '@/components/user/UserActions';
import { useAuth } from '@/contexts/AuthContext';

interface UserProfileHeaderProps {
  user: UserProfile;
  publicId: string;
}

export function UserProfileHeader({ user, publicId }: UserProfileHeaderProps) {
  const t = useTranslations('profile');
  const tLevels = useTranslations('levels');
  const { user: currentUser } = useAuth();
  const [followerCount, setFollowerCount] = useState(user.followerCount);
  const [imageError, setImageError] = useState(false);
  const isOwnProfile = currentUser?.publicId === publicId;

  const handleFollowChange = (isFollowing: boolean) => {
    setFollowerCount((prev) => (isFollowing ? prev + 1 : prev - 1));
  };

  const profileImageUrl = getImageUrl(user.profileImageUrl);
  // Only show image if URL is valid (starts with http) and hasn't errored
  const showImage = profileImageUrl && profileImageUrl.startsWith('http') && !imageError;

  return (
    <div className="bg-[var(--surface)] border border-[var(--border)] rounded-2xl p-6 sm:p-8 mb-8">
      <div className="flex flex-col sm:flex-row items-center sm:items-start gap-6">
        {/* Avatar */}
        <div className="relative w-24 h-24 sm:w-32 sm:h-32 rounded-full overflow-hidden bg-[var(--primary-light)] flex-shrink-0">
          {showImage ? (
            <Image
              src={profileImageUrl}
              alt={user.username}
              fill
              className="object-cover"
              sizes="128px"
              onError={() => setImageError(true)}
            />
          ) : (
            <div className="w-full h-full flex items-center justify-center text-4xl sm:text-5xl text-[var(--primary)]">
              {getAvatarInitial(user.username)}
            </div>
          )}
        </div>

        {/* Info */}
        <div className="flex-1 text-center sm:text-left">
          <div className="flex flex-col sm:flex-row sm:items-center gap-3">
            <h1 className="text-2xl sm:text-3xl font-bold text-[var(--text-primary)]">
              {user.username}
            </h1>
            {isOwnProfile ? (
              <Link
                href="/profile/edit"
                className="px-4 py-2 bg-[var(--surface)] border border-[var(--border)] text-[var(--text-primary)] rounded-xl font-medium hover:bg-[var(--highlight-bg)] transition-colors text-sm"
              >
                {t('editProfile')}
              </Link>
            ) : (
              <div className="flex items-center gap-2">
                <FollowButton
                  targetUserPublicId={publicId}
                  onFollowChange={handleFollowChange}
                />
                <UserActions
                  userPublicId={publicId}
                  username={user.username}
                />
              </div>
            )}
          </div>

          {/* Level Badge */}
          <div className="flex items-center justify-center sm:justify-start gap-3 mt-2">
            <span className="px-3 py-1 bg-[var(--primary-light)] text-[var(--primary)] text-sm font-medium rounded-full">
              {tLevels(user.levelName)}
            </span>
            <span className="text-[var(--text-secondary)]">{t('level', { level: user.level })}</span>
          </div>

          {/* XP Progress Bar */}
          {user.totalXp !== null && user.xpForCurrentLevel !== null && user.xpForNextLevel !== null && (
            <div className="mt-3 max-w-md">
              {/* Progress bar */}
              <div className="h-2 bg-[var(--border)] rounded-full overflow-hidden">
                <div
                  className="h-full bg-[var(--primary)] rounded-full transition-all duration-300"
                  style={{ width: `${Math.min(100, (user.levelProgress || 0) * 100)}%` }}
                />
              </div>
              {/* XP text */}
              <div className="flex justify-between items-center mt-1.5 text-xs text-[var(--text-secondary)]">
                <span>
                  {t('xpProgress', {
                    current: user.totalXp.toLocaleString(),
                    next: user.xpForNextLevel.toLocaleString(),
                  })}
                </span>
                {(() => {
                  const nextTierKey = getNextTierKey(user.level);
                  const xpToTier = getXpToNextTier(user.level, user.totalXp);
                  if (nextTierKey && xpToTier !== null && xpToTier > 0) {
                    return (
                      <span className="text-[var(--text-tertiary)]">
                        {t('xpToNextTier', { xp: xpToTier.toLocaleString(), tierName: tLevels(nextTierKey) })}
                      </span>
                    );
                  }
                  return null;
                })()}
              </div>
            </div>
          )}

          {user.bio && (
            <p className="text-[var(--text-secondary)] mt-4 max-w-xl">{user.bio}</p>
          )}

          {/* Social Links Pills */}
          {(user.youtubeUrl || user.instagramHandle) && (
            <div className="flex flex-wrap items-center justify-center sm:justify-start gap-2 mt-4">
              {user.youtubeUrl && (
                <a
                  href={user.youtubeUrl}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex items-center gap-2 px-4 py-2 bg-[#FF0000] text-white text-sm font-medium rounded-full hover:opacity-80 transition-opacity"
                  style={{ color: 'white' }}
                >
                  <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
                    <path d="M23.498 6.186a3.016 3.016 0 0 0-2.122-2.136C19.505 3.545 12 3.545 12 3.545s-7.505 0-9.377.505A3.017 3.017 0 0 0 .502 6.186C0 8.07 0 12 0 12s0 3.93.502 5.814a3.016 3.016 0 0 0 2.122 2.136c1.871.505 9.376.505 9.376.505s7.505 0 9.377-.505a3.015 3.015 0 0 0 2.122-2.136C24 15.93 24 12 24 12s0-3.93-.502-5.814zM9.545 15.568V8.432L15.818 12l-6.273 3.568z" />
                  </svg>
                  YouTube
                </a>
              )}
              {user.instagramHandle && (
                <a
                  href={`https://instagram.com/${user.instagramHandle.replace('@', '')}`}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex items-center gap-2 px-4 py-2 text-white text-sm font-medium rounded-full hover:opacity-80 transition-opacity"
                  style={{
                    background: 'linear-gradient(45deg, #f09433 0%, #e6683c 25%, #dc2743 50%, #cc2366 75%, #bc1888 100%)',
                    color: 'white',
                  }}
                >
                  <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
                    <path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zm0-2.163c-3.259 0-3.667.014-4.947.072-4.358.2-6.78 2.618-6.98 6.98-.059 1.281-.073 1.689-.073 4.948 0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98 1.281.058 1.689.072 4.948.072 3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98-1.281-.059-1.69-.073-4.949-.073zm0 5.838c-3.403 0-6.162 2.759-6.162 6.162s2.759 6.163 6.162 6.163 6.162-2.759 6.162-6.163c0-3.403-2.759-6.162-6.162-6.162zm0 10.162c-2.209 0-4-1.79-4-4 0-2.209 1.791-4 4-4s4 1.791 4 4c0 2.21-1.791 4-4 4zm6.406-11.845c-.796 0-1.441.645-1.441 1.44s.645 1.44 1.441 1.44c.795 0 1.439-.645 1.439-1.44s-.644-1.44-1.439-1.44z" />
                  </svg>
                  Instagram
                </a>
              )}
            </div>
          )}

          {/* Stats */}
          <div className="flex items-center justify-center sm:justify-start gap-6 mt-4">
            <div className="text-center">
              <p className="text-xl font-bold text-[var(--text-primary)]">
                {user.recipeCount}
              </p>
              <p className="text-sm text-[var(--text-secondary)]">{t('recipes')}</p>
            </div>
            <div className="text-center">
              <p className="text-xl font-bold text-[var(--text-primary)]">
                {user.logCount}
              </p>
              <p className="text-sm text-[var(--text-secondary)]">{t('logs')}</p>
            </div>
            <Link
              href={`/users/${publicId}/followers`}
              className="text-center hover:opacity-80 transition-opacity"
            >
              <p className="text-xl font-bold text-[var(--text-primary)]">
                {followerCount}
              </p>
              <p className="text-sm text-[var(--text-secondary)]">{t('followers')}</p>
            </Link>
            <Link
              href={`/users/${publicId}/following`}
              className="text-center hover:opacity-80 transition-opacity"
            >
              <p className="text-xl font-bold text-[var(--text-primary)]">
                {user.followingCount}
              </p>
              <p className="text-sm text-[var(--text-secondary)]">{t('following')}</p>
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
}
