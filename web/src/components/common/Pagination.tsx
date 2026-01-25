'use client';

import { Link } from '@/i18n/navigation';
import { useTranslations } from 'next-intl';

export interface PaginationProps { 
  currentPage: number;
  totalPages: number;
  baseUrl: string;
  onPageChange?: (page: number) => void;
}

/**
 * Generate page numbers to display
 * Shows: first, last, current, and 1 page on each side of current
 */
function generatePageNumbers(
  current: number,
  total: number,
): (number | 'ellipsis')[] {
  if (total <= 7) {
    return Array.from({ length: total }, (_, i) => i);
  }

  const pages: (number | 'ellipsis')[] = [];

  // Always show first page
  pages.push(0);

  // Show ellipsis if current page is far from start
  if (current > 3) {
    pages.push('ellipsis');
  }

  // Show pages around current
  const start = Math.max(1, current - 1);
  const end = Math.min(total - 2, current + 1);

  for (let i = start; i <= end; i++) {
    if (!pages.includes(i)) {
      pages.push(i);
    }
  }

  // Show ellipsis if current page is far from end
  if (current < total - 4) {
    pages.push('ellipsis');
  }

  // Always show last page
  if (!pages.includes(total - 1)) {
    pages.push(total - 1);
  }

  return pages;
}

/**
 * Build URL with page parameter
 */
function buildPageUrl(baseUrl: string, page: number): string {
  const separator = baseUrl.includes('?') ? '&' : '?';
  return `${baseUrl}${separator}page=${page + 1}`;
}

export function Pagination({ currentPage, totalPages, baseUrl, onPageChange }: PaginationProps) {
  const t = useTranslations('accessibility');

  if (totalPages <= 1) {
    return null;
  }

  const pages = generatePageNumbers(currentPage, totalPages);

  const handleClick = (page: number, e: React.MouseEvent) => {
    if (onPageChange) {
      e.preventDefault();
      onPageChange(page);
    }
  };

  return (
    <nav
      className="flex justify-center items-center gap-1 mt-8"
      aria-label={t('pagination')}
    >
      {/* Previous button */}
      {currentPage > 0 ? (
        <Link
          href={buildPageUrl(baseUrl, currentPage - 1)}
          onClick={(e) => handleClick(currentPage - 1, e)}
          className="px-3 py-2 rounded-lg border border-[var(--border)] text-[var(--text-secondary)] hover:bg-[var(--primary-light)] hover:border-[var(--primary)] hover:text-[var(--primary)] transition-colors"
          aria-label={t('previousPage')}
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
              d="M15 19l-7-7 7-7"
            />
          </svg>
        </Link>
      ) : (
        <span className="px-3 py-2 rounded-lg border border-[var(--border)] text-[var(--text-secondary)] opacity-50 cursor-not-allowed">
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
              d="M15 19l-7-7 7-7"
            />
          </svg>
        </span>
      )}

      {/* Page numbers */}
      {pages.map((page, idx) =>
        page === 'ellipsis' ? (
          <span
            key={`ellipsis-${idx}`}
            className="px-3 py-2 text-[var(--text-secondary)]"
          >
            ...
          </span>
        ) : (
          <Link
            key={page}
            href={buildPageUrl(baseUrl, page)}
            onClick={(e) => handleClick(page, e)}
            className={`px-4 py-2 rounded-lg border transition-colors ${
              page === currentPage
                ? 'bg-[var(--primary)] text-white border-[var(--primary)]'
                : 'border-[var(--border)] text-[var(--text-secondary)] hover:bg-[var(--primary-light)] hover:border-[var(--primary)] hover:text-[var(--primary)]'
            }`}
            aria-label={t('page', { number: page + 1 })}
            aria-current={page === currentPage ? 'page' : undefined}
          >
            {page + 1}
          </Link>
        ),
      )}

      {/* Next button */}
      {currentPage < totalPages - 1 ? (
        <Link
          href={buildPageUrl(baseUrl, currentPage + 1)}
          onClick={(e) => handleClick(currentPage + 1, e)}
          className="px-3 py-2 rounded-lg border border-[var(--border)] text-[var(--text-secondary)] hover:bg-[var(--primary-light)] hover:border-[var(--primary)] hover:text-[var(--primary)] transition-colors"
          aria-label={t('nextPage')}
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
              d="M9 5l7 7-7 7"
            />
          </svg>
        </Link>
      ) : (
        <span className="px-3 py-2 rounded-lg border border-[var(--border)] text-[var(--text-secondary)] opacity-50 cursor-not-allowed">
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
              d="M9 5l7 7-7 7"
            />
          </svg>
        </span>
      )}
    </nav>
  );
}
