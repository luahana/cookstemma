'use client';

import Image from 'next/image';
import { useRouter } from 'next/navigation';
import { useTransition, useEffect } from 'react';
import { useTranslations } from 'next-intl';
import { useNavigationProgress } from '@/contexts/NavigationProgressContext';
import type { HashtagSearchResult } from '@/lib/types';
import { getImageUrl } from '@/lib/utils/image';

interface HashtagCardProps {
  hashtag: HashtagSearchResult;
}

export function HashtagCard({ hashtag }: HashtagCardProps) {
  const t = useTranslations('hashtagCard');
  const router = useRouter();
  const [isPending, startTransition] = useTransition();
  const { startLoading, stopLoading } = useNavigationProgress();
  const totalCount = hashtag.recipeCount + hashtag.logCount;

  // Stop loading when transition completes
  useEffect(() => {
    if (!isPending) {
      stopLoading();
    }
  }, [isPending, stopLoading]);

  const handleClick = () => {
    startLoading();
    startTransition(() => {
      router.push(`/hashtags/${encodeURIComponent(hashtag.name)}`);
    });
  };

  return (
    <button
      onClick={handleClick}
      disabled={isPending}
      className="relative block w-full text-left bg-[var(--surface)] rounded-2xl shadow-sm border border-[var(--border)] overflow-hidden hover:shadow-md hover:border-[var(--primary-light)] transition-all group disabled:cursor-wait"
    >
      {/* Thumbnail grid */}
      <div className="relative aspect-[4/3] bg-[var(--background)]">
        {hashtag.sampleThumbnails.length > 0 ? (
          <div className="grid grid-cols-2 grid-rows-2 w-full h-full">
            {hashtag.sampleThumbnails.slice(0, 4).map((thumbnail, idx) => (
              <div key={idx} className="relative overflow-hidden">
                <Image
                  src={getImageUrl(thumbnail)!}
                  alt={`${hashtag.name} sample ${idx + 1}`}
                  fill
                  className="object-cover group-hover:scale-105 transition-transform duration-300"
                  sizes="(max-width: 640px) 50vw, (max-width: 1024px) 25vw, 16vw"
                />
              </div>
            ))}
            {/* Fill empty spots with placeholder */}
            {Array(Math.max(0, 4 - hashtag.sampleThumbnails.length))
              .fill(null)
              .map((_, idx) => (
                <div
                  key={`empty-${idx}`}
                  className="bg-[var(--hover-bg)] flex items-center justify-center"
                >
                  <span className="text-2xl opacity-30">#</span>
                </div>
              ))}
          </div>
        ) : (
          <div className="w-full h-full flex items-center justify-center">
            <span className="text-6xl text-[var(--text-secondary)] opacity-30">#</span>
          </div>
        )}

        {/* Hashtag badge overlay */}
        <div className="absolute inset-0 bg-gradient-to-t from-black/60 to-transparent" />
        <div className="absolute bottom-3 left-3 right-3">
          <h3 className="text-lg font-bold text-white truncate">#{hashtag.name}</h3>
        </div>
      </div>

      {/* Content */}
      <div className="p-4">
        {/* Counts */}
        <div className="flex items-center gap-4 text-sm text-[var(--text-secondary)]">
          <span className="flex items-center gap-1">
            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"
              />
            </svg>
            {hashtag.recipeCount} {t(hashtag.recipeCount === 1 ? 'recipe' : 'recipes')}
          </span>
          <span className="flex items-center gap-1">
            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
              />
            </svg>
            {hashtag.logCount} {t(hashtag.logCount === 1 ? 'log' : 'logs')}
          </span>
        </div>

        {/* Top contributors */}
        {hashtag.topContributors.length > 0 && (
          <div className="flex items-center gap-2 mt-3">
            <span className="text-xs text-[var(--text-secondary)]">{t('topContributors')}</span>
            <div className="flex -space-x-2">
              {hashtag.topContributors.map((contributor) => (
                <div
                  key={contributor.publicId}
                  className="relative w-6 h-6 rounded-full border-2 border-[var(--surface)] overflow-hidden bg-[var(--hover-bg)]"
                  title={contributor.username}
                >
                  {contributor.avatarUrl ? (
                    <Image
                      src={getImageUrl(contributor.avatarUrl)!}
                      alt={contributor.username}
                      fill
                      className="object-cover"
                      sizes="24px"
                    />
                  ) : (
                    <div className="w-full h-full flex items-center justify-center text-xs text-[var(--text-secondary)]">
                      {contributor.username.charAt(0).toUpperCase()}
                    </div>
                  )}
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Total count */}
        <div className="mt-3 pt-3 border-t border-[var(--border)]">
          <p className="text-sm text-[var(--text-primary)] font-medium">
            {t('postsTaggedCount', { count: totalCount })}
          </p>
        </div>
      </div>

    </button>
  );
}
