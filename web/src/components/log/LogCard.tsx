'use client';

import Image from 'next/image';
import { Link } from '@/i18n/navigation';
import { useTranslations } from 'next-intl';
import type { LogPostSummary } from '@/lib/types';
import { getImageUrl } from '@/lib/utils/image';
import { BookmarkButton } from '@/components/common/BookmarkButton';
import { StarRating } from './StarRating';

interface LogCardProps {
  log: LogPostSummary;
  isSaved?: boolean;
  showTypeLabel?: boolean;
}

export function LogCard({ log, isSaved = false, showTypeLabel = false }: LogCardProps) {
  const tCommon = useTranslations('common');
  const tCard = useTranslations('card');

  return (
    <Link
      href={`/logs/${log.publicId}`}
      className="block bg-[var(--surface)] rounded-2xl shadow-sm border border-[var(--border)] overflow-hidden hover:shadow-md hover:border-[var(--primary-light)] transition-all group"
    >
      {/* Thumbnail */}
      <div className="relative aspect-[4/3] bg-[var(--background)]">
        {getImageUrl(log.thumbnailUrl) ? (
          <Image
            src={getImageUrl(log.thumbnailUrl)!}
            alt={log.title}
            fill
            className="object-cover group-hover:scale-105 transition-transform duration-300"
            sizes="(max-width: 640px) 100vw, (max-width: 1024px) 50vw, 33vw"
          />
        ) : (
          <div className="w-full h-full flex items-center justify-center text-4xl">
            <svg
              className="w-12 h-12 text-[var(--text-secondary)] opacity-50"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
              />
            </svg>
          </div>
        )}

        {/* Variant indicator */}
        {log.isVariant && (
          <span className="absolute top-3 left-3 px-2 py-1 bg-[var(--secondary)] text-white text-xs font-medium rounded-full">
            {tCard('variant')}
          </span>
        )}

        {/* Private indicator */}
        {log.isPrivate && (
          <span className="absolute top-3 right-3 p-1.5 bg-black/60 rounded-full" title={tCard('private')}>
            <svg className="w-4 h-4 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
            </svg>
          </span>
        )}
      </div>

      {/* Content */}
      <div className="p-4">
        {/* Type label for search results */}
        {showTypeLabel && (
          <span className="inline-flex items-center gap-1 text-xs px-2 py-0.5 bg-[var(--secondary)]/10 text-[var(--secondary)] rounded-full mb-2">
            <svg className="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
            </svg>
            {tCard('cookingLog')}
          </span>
        )}

        {/* Food name with bookmark button */}
        <div className="flex items-center justify-between">
          {log.foodName && (
            <p className="text-sm font-medium text-[var(--primary)]">
              {log.foodName}
            </p>
          )}
          <BookmarkButton
            publicId={log.publicId}
            type="log"
            initialSaved={isSaved}
            size="sm"
            variant="inline"
          />
        </div>
        {/* Star rating */}
        {log.rating && (
          <div className="mt-1">
            <StarRating rating={log.rating} size="sm" />
          </div>
        )}

        {/* Recipe Title */}
        {log.recipeTitle && (
          <h3 className="font-semibold text-[var(--text-primary)] mt-1 line-clamp-1 group-hover:text-[var(--primary)] transition-colors">
            {log.recipeTitle}
          </h3>
        )}

        {/* Cooking Notes - 2 lines with ellipsis */}
        {log.content && (
          <p className="text-sm text-[var(--text-secondary)] mt-1 line-clamp-2">
            {log.content}
          </p>
        )}

        {/* Creator */}
        {log.userName && (
          <div className="flex items-center gap-1.5 mt-2">
            <div className="w-5 h-5 rounded-full bg-[var(--primary-light)] flex items-center justify-center flex-shrink-0">
              <span className="text-[var(--primary)] text-xs font-medium">
                {log.userName.charAt(0).toUpperCase()}
              </span>
            </div>
            <span className="text-sm text-[var(--text-secondary)]">{log.userName}</span>
          </div>
        )}

        {/* Hashtags */}
        {log.hashtags.length > 0 && (
          <div className="flex flex-wrap gap-1 mt-2">
            {log.hashtags.slice(0, 3).map((tag) => (
              <span
                key={tag}
                className="text-xs hover:underline text-hashtag"
              >
                #{tag}
              </span>
            ))}
          </div>
        )}
      </div>
    </Link>
  );
}
