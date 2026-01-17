'use client';

import Image from 'next/image';
import Link from 'next/link';
import { getImageUrl } from '@/lib/utils/image';

interface LogSummary {
  publicId: string;
  title: string;
  outcome: string;
  thumbnailUrl?: string | null;
  userName?: string;
}

interface RecentLogsGalleryProps {
  logs: LogSummary[];
  recipePublicId: string;
}

const OUTCOME_CONFIG = {
  SUCCESS: { emoji: '✓', bgColor: 'bg-green-100', textColor: 'text-green-600' },
  PARTIAL: { emoji: '~', bgColor: 'bg-amber-100', textColor: 'text-amber-600' },
  FAILED: { emoji: '✗', bgColor: 'bg-red-100', textColor: 'text-red-600' },
} as const;

export function RecentLogsGallery({ logs, recipePublicId }: RecentLogsGalleryProps) {
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
            Write a Log
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
      <div className="relative">
        <div className="flex gap-4 overflow-x-auto pb-4 scrollbar-hide">
          {displayLogs.map((log) => {
            const thumbUrl = getImageUrl(log.thumbnailUrl);
            const outcome = OUTCOME_CONFIG[log.outcome as keyof typeof OUTCOME_CONFIG] || OUTCOME_CONFIG.SUCCESS;

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

                  {/* Outcome Badge */}
                  <div
                    className={`absolute bottom-2 right-2 w-6 h-6 rounded-full flex items-center justify-center text-sm font-bold shadow-md ${outcome.bgColor} ${outcome.textColor}`}
                  >
                    {outcome.emoji}
                  </div>
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
      <div className="mt-4 text-center">
        <Link
          href={`/logs/create?recipe=${recipePublicId}`}
          className="inline-flex items-center gap-2 px-4 py-2 text-sm text-[var(--primary)] hover:bg-[var(--primary-light)] rounded-lg transition-colors"
        >
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
          Share your cooking experience
        </Link>
      </div>
    </section>
  );
}
