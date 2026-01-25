'use client';

import Image from 'next/image';
import { Link } from '@/i18n/navigation';
import { useTranslations } from 'next-intl';
import { getImageUrl } from '@/lib/utils/image';
import { useDragScroll } from '@/hooks/useDragScroll';
import { StarRating } from '@/components/log/StarRating';

interface LogSummary {
  publicId: string;
  title: string;
  content: string | null;
  rating: number | null;
  thumbnailUrl?: string | null;
  userName?: string | null;
}

interface RecentLogsGalleryProps {
  logs: LogSummary[];
  recipePublicId: string;
}

export function RecentLogsGallery({ logs, recipePublicId }: RecentLogsGalleryProps) {
  const t = useTranslations('logs');
  const tCommon = useTranslations('common');
  const scrollRef = useDragScroll<HTMLDivElement>();
  const displayLogs = logs.slice(0, 8);
  const hasMore = logs.length > 8;

  if (logs.length === 0) {
    return (
      <section className="mb-8">
        <h2 className="text-2xl font-bold text-[var(--text-primary)] mb-4">
          {t('title')}
        </h2>
        <div className="bg-[var(--surface)] border border-[var(--border)] rounded-xl p-8 text-center">
          <div className="w-16 h-16 mx-auto mb-4 rounded-full bg-[var(--primary-light)] flex items-center justify-center">
            <svg
              className="w-8 h-8 text-[var(--primary)]"
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
          <h3 className="text-lg font-medium text-[var(--text-primary)] mb-2">
            {t('noCookingLogs')}
          </h3>
          <p className="text-[var(--text-secondary)] mb-4">
            {t('beFirst')}
          </p>
          <Link
            href={`/logs/create?recipeId=${recipePublicId}`}
            className="inline-flex items-center gap-2 px-4 py-2 bg-[var(--primary)] dark:bg-[var(--secondary)] text-white [&>*]:text-white rounded-lg hover:bg-[var(--primary-dark)] dark:hover:bg-[#6D4C41] transition-colors"
          >
            <svg
              className="w-5 h-5"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M12 4v16m8-8H4"
              />
            </svg>
            <span className="text-white">{t('cookingLog')}</span>
          </Link>
        </div>
      </section>
    );
  }

  return (
    <section className="mb-8">
      {/* Header */}
      <div className="flex items-center justify-between mb-4">
        <h2 className="text-2xl font-bold text-[var(--text-primary)]">
          {t('title')} ({logs.length})
        </h2>
        {hasMore && (
          <Link
            href={`/search?type=logs&recipe=${recipePublicId}`}
            className="text-sm text-[var(--primary)] hover:underline flex items-center gap-1"
          >
            {t('viewMore')}
            <svg
              className="w-4 h-4"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M9 5l7 7-7 7"
              />
            </svg>
          </Link>
        )}
      </div>

      {/* Horizontal Scrolling Gallery */}
      <div className="relative -mx-4 px-4 sm:-mx-6 sm:px-6 lg:-mx-8 lg:px-8">
        <div
          ref={scrollRef}
          className="flex gap-4 pb-4 scrollbar-hide"
          style={{ overflowX: 'auto' }}
        >
          {displayLogs.map((log) => {
            const thumbUrl = getImageUrl(log.thumbnailUrl);

            return (
              <Link
                key={log.publicId}
                href={`/logs/${log.publicId}`}
                className="flex-shrink-0 group"
              >
                {/* Card */}
                <div className="relative w-28 h-28 rounded-xl overflow-hidden bg-[var(--surface)] border border-[var(--border)] group-hover:border-[var(--primary-light)] transition-colors">
                  {thumbUrl ? (
                    <Image
                      src={thumbUrl}
                      alt={log.title}
                      fill
                      className="object-cover"
                      sizes="112px"
                      unoptimized
                    />
                  ) : (
                    <div className="w-full h-full flex items-center justify-center bg-[var(--surface)]">
                      <svg
                        className="w-10 h-10 text-[var(--text-secondary)]"
                        fill="none"
                        stroke="currentColor"
                        viewBox="0 0 24 24"
                      >
                        <path
                          strokeLinecap="round"
                          strokeLinejoin="round"
                          strokeWidth={1.5}
                          d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"
                        />
                      </svg>
                    </div>
                  )}

                </div>

                {/* Star Rating - below photo */}
                {log.rating && (
                  <div className="mt-1.5 flex justify-center">
                    <StarRating rating={log.rating} size="sm" />
                  </div>
                )}

                {/* Cooking Notes - 2 lines with ellipsis */}
                {log.content && (
                  <p className="mt-1 text-xs text-[var(--text-primary)] w-28 line-clamp-2">
                    {log.content}
                  </p>
                )}

                {/* Username */}
                <div className="mt-1 flex items-center justify-center gap-1 w-28">
                  <div className="w-4 h-4 rounded-full bg-[var(--primary-light)] flex items-center justify-center flex-shrink-0">
                    <span className="text-[var(--primary)] text-[10px] font-medium">
                      {(log.userName || tCommon('anonymous')).charAt(0).toUpperCase()}
                    </span>
                  </div>
                  <span className="text-xs text-[var(--text-secondary)] truncate">{log.userName || tCommon('anonymous')}</span>
                </div>
              </Link>
            );
          })}

          {/* "View More" Card */}
          {hasMore && (
            <Link
              href={`/search?type=logs&recipe=${recipePublicId}`}
              className="flex-shrink-0"
            >
              <div className="w-28 h-28 rounded-xl border-2 border-dashed border-[var(--border)] hover:border-[var(--primary)] flex flex-col items-center justify-center gap-2 transition-colors">
                <span className="text-2xl font-bold text-[var(--text-secondary)]">
                  +{logs.length - 8}
                </span>
                <span className="text-xs text-[var(--text-secondary)]">
                  {t('moreLogs', { count: logs.length - 8 })}
                </span>
              </div>
            </Link>
          )}
        </div>
      </div>

      {/* Write Log CTA */}
      <div className="mt-6">
        <Link
          href={`/logs/create?recipeId=${recipePublicId}`}
          className="flex items-center justify-between gap-4 px-5 py-4 bg-[var(--surface)] border border-[var(--border)] border-l-4 border-l-[var(--primary)] dark:border-l-[var(--secondary)] rounded-xl hover:bg-[var(--background)] transition-colors"
        >
          <div>
            <p className="font-semibold text-[var(--text-primary)]">{t('madeRecipe')}</p>
            <p className="text-sm text-[var(--text-secondary)]">{t('shareExperience')}</p>
          </div>
          <div className="flex items-center gap-2 px-4 py-2 bg-[var(--primary)] dark:bg-[var(--secondary)] font-medium rounded-lg shrink-0 text-sm text-white [&>*]:text-white">
            <svg
              className="w-4 h-4"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M12 4v16m8-8H4"
              />
            </svg>
            <span className="hidden sm:inline text-white">{t('cookingLog')}</span>
          </div>
        </Link>
      </div>
    </section>
  );
}
