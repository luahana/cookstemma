import Image from 'next/image';
import Link from 'next/link';
import type { LogPostSummary } from '@/lib/types';
import { OutcomeBadge } from './OutcomeBadge';
import { getImageUrl } from '@/lib/utils/image';
import { BookmarkButton } from '@/components/common/BookmarkButton';

interface LogCardProps {
  log: LogPostSummary;
  isSaved?: boolean;
}

export function LogCard({ log, isSaved = false }: LogCardProps) {
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

        {/* Outcome badge */}
        <div className="absolute top-3 left-3">
          <OutcomeBadge outcome={log.outcome} size="sm" />
        </div>

        {/* Variant indicator - shift left if bookmark button is present */}
        {log.isVariant && (
          <span className="absolute top-3 right-12 px-2 py-1 bg-[var(--secondary)] text-white text-xs font-medium rounded-full">
            Variant
          </span>
        )}

        {/* Bookmark button */}
        <div className="absolute top-3 right-3">
          <BookmarkButton
            publicId={log.publicId}
            type="log"
            initialSaved={isSaved}
            size="sm"
          />
        </div>
      </div>

      {/* Content */}
      <div className="p-4">
        {/* Food name */}
        {log.foodName && (
          <p className="text-sm font-medium text-[var(--primary)]">{log.foodName}</p>
        )}

        {/* Title */}
        <h3 className="font-semibold text-[var(--text-primary)] mt-1 line-clamp-2 group-hover:text-[var(--primary)] transition-colors">
          {log.title}
        </h3>

        {/* Creator */}
        {log.userName && (
          <p className="text-sm text-[var(--text-secondary)] mt-2">
            by {log.userName}
          </p>
        )}

        {/* Hashtags */}
        {log.hashtags.length > 0 && (
          <div className="flex flex-wrap gap-1 mt-2">
            {log.hashtags.slice(0, 3).map((tag) => (
              <span
                key={tag}
                className="text-xs text-[var(--success)] hover:underline"
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
