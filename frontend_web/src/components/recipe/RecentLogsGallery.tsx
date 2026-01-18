'use client';

import Image from 'next/image';
import Link from 'next/link';
import { getImageUrl } from '@/lib/utils/image';
import { useDragScroll } from '@/hooks/useDragScroll';
import { StarRating } from '@/components/log/StarRating';

interface LogSummary {
  publicId: string;
  title: string;
  rating: number | null;
  thumbnailUrl?: string | null;
  userName?: string | null;
}

interface RecentLogsGalleryProps {
  logs: LogSummary[];
  recipePublicId: string;
}

export function RecentLogsGallery({ logs, recipePublicId }: RecentLogsGalleryProps) {
  const scrollRef = useDragScroll<HTMLDivElement>();
  const displayLogs = logs.slice(0, 8);
  const hasMore = logs.length > 8;

  if (logs.length === 0) {
    return (
      <section className="mb-8">
        <h2 className="text-2xl font-bold text-[var(--text-primary)] mb-4">
          Cooking Logs
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
            No cooking logs yet
          </h3>
          <p className="text-[var(--text-secondary)] mb-4">
            Be the first to share your cooking experience!
          </p>
          <Link
            href={`/logs/create?recipe=${recipePublicId}`}
            className="inline-flex items-center gap-2 px-4 py-2 bg-[var(--primary)] text-white rounded-lg hover:bg-[var(--primary-dark)] transition-colors"
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
            Cooking Log
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
          Cooking Logs ({logs.length})
        </h2>
        {hasMore && (
          <Link
            href={`/search?type=logs&recipe=${recipePublicId}`}
            className="text-sm text-[var(--primary)] hover:underline flex items-center gap-1"
          >
            View More
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

                  {/* Star Rating Badge */}
                  {log.rating && (
                    <div className="absolute bottom-2 right-2 bg-white/90 rounded-full px-1.5 py-0.5 shadow-md">
                      <StarRating rating={log.rating} size="sm" />
                    </div>
                  )}
                </div>

                {/* Username */}
                <p className="mt-2 text-xs text-[var(--text-secondary)] truncate w-28 text-center">
                  @{log.userName || 'anonymous'}
                </p>
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
                  more logs
                </span>
              </div>
            </Link>
          )}
        </div>
      </div>

      {/* Write Log CTA */}
      <div className="mt-6">
        <Link
          href={`/logs/create?recipe=${recipePublicId}`}
          className="flex items-center justify-between gap-4 px-5 py-4 bg-[var(--surface)] border border-[var(--border)] border-l-4 border-l-[var(--primary)] rounded-xl hover:bg-[var(--background)] transition-colors"
        >
          <div>
            <p className="font-semibold text-[var(--text-primary)]">Made this recipe?</p>
            <p className="text-sm text-[var(--text-secondary)]">Share your cooking experience with others</p>
          </div>
          <div className="flex items-center gap-2 px-4 py-2 bg-[var(--primary)] text-white font-medium rounded-lg shrink-0 text-sm">
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
            <span className="hidden sm:inline">Cooking Log</span>
          </div>
        </Link>
      </div>
    </section>
  );
}
