'use client';

import { useState, useEffect, useCallback } from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { useTranslations } from 'next-intl';
import {
  getViewHistory,
  clearViewHistory as clearLocalViewHistory,
  type ViewHistoryItem,
} from '@/lib/utils/viewHistory';
import { getImageUrl } from '@/lib/utils/image';
import { StarRating } from '@/components/log/StarRating';

export function RecentlyViewedCompact() {
  const t = useTranslations('search');
  // Initialize with null to detect if we've loaded from localStorage yet
  const [items, setItems] = useState<ViewHistoryItem[] | null>(null);
  const [isClearing, setIsClearing] = useState(false);

  const loadHistory = useCallback(() => {
    setItems(getViewHistory());
  }, []);

  useEffect(() => {
    // eslint-disable-next-line react-hooks/set-state-in-effect -- valid for client-only hydration from localStorage
    loadHistory();
  }, [loadHistory]);

  const handleClearAll = () => {
    if (isClearing) return;
    setIsClearing(true);
    clearLocalViewHistory();
    setItems([]);
    setIsClearing(false);
  };

  // Don't render on server or if no items
  if (items === null || items.length === 0) {
    return null;
  }

  return (
    <div className="mb-8">
      <div className="flex items-center justify-between mb-3">
        <h2 className="text-lg font-semibold text-[var(--text-primary)]">
          {t('recentlyViewed')}
        </h2>
        <button
          onClick={handleClearAll}
          disabled={isClearing}
          className="text-sm text-[var(--text-secondary)] hover:text-[var(--text-primary)] transition-colors disabled:opacity-50"
        >
          {isClearing ? t('clearing') : t('clearAll')}
        </button>
      </div>
      <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-4">
        {items.map((item) => {
          if (item.type === 'recipe') {
            return (
              <Link
                key={`recipe-${item.publicId}`}
                href={`/recipes/${item.publicId}`}
                className="group"
              >
                <div className="relative aspect-square rounded-lg overflow-hidden bg-[var(--surface)] border-2 border-[var(--primary)] mb-2">
                  {getImageUrl(item.thumbnail) ? (
                    <Image
                      src={getImageUrl(item.thumbnail)!}
                      alt={item.title}
                      fill
                      className="object-cover group-hover:scale-105 transition-transform duration-200"
                      sizes="(max-width: 640px) 50vw, (max-width: 768px) 33vw, 25vw"
                    />
                  ) : (
                    <div className="w-full h-full flex items-center justify-center bg-[var(--highlight-bg)]">
                      <svg
                        className="w-8 h-8 text-[var(--text-secondary)]"
                        fill="none"
                        stroke="currentColor"
                        viewBox="0 0 24 24"
                      >
                        <path
                          strokeLinecap="round"
                          strokeLinejoin="round"
                          strokeWidth={1.5}
                          d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"
                        />
                      </svg>
                    </div>
                  )}
                  {/* Recipe badge */}
                  <span className="absolute top-1 left-1 px-1.5 py-0.5 bg-[var(--primary)] text-white text-xs font-medium rounded">
                    {t('recipe')}
                  </span>
                </div>
                <p className="text-sm text-[var(--text-primary)] font-medium truncate group-hover:text-[var(--primary)] transition-colors">
                  {item.title}
                </p>
                <p className="text-xs text-[var(--text-secondary)] truncate">
                  {item.foodName}
                </p>
              </Link>
            );
          } else {
            return (
              <Link
                key={`log-${item.publicId}`}
                href={`/logs/${item.publicId}`}
                className="group"
              >
                <div className="relative aspect-square rounded-lg overflow-hidden bg-[var(--surface)] border-2 border-[var(--secondary)] mb-2">
                  {getImageUrl(item.thumbnail) ? (
                    <Image
                      src={getImageUrl(item.thumbnail)!}
                      alt={item.title}
                      fill
                      className="object-cover group-hover:scale-105 transition-transform duration-200"
                      sizes="(max-width: 640px) 50vw, (max-width: 768px) 33vw, 25vw"
                    />
                  ) : (
                    <div className="w-full h-full flex items-center justify-center bg-[var(--highlight-bg)]">
                      <svg
                        className="w-8 h-8 text-[var(--text-secondary)]"
                        fill="none"
                        stroke="currentColor"
                        viewBox="0 0 24 24"
                      >
                        <path
                          strokeLinecap="round"
                          strokeLinejoin="round"
                          strokeWidth={1.5}
                          d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
                        />
                      </svg>
                    </div>
                  )}
                  {/* Log badge */}
                  <span className="absolute top-1 left-1 px-1.5 py-0.5 bg-[var(--secondary)] text-white text-xs font-medium rounded">
                    {t('log')}
                  </span>
                </div>
                <p className="text-sm text-[var(--text-primary)] font-medium truncate group-hover:text-[var(--secondary)] transition-colors">
                  {item.title}
                </p>
                {/* Star rating above food name */}
                {item.rating && (
                  <div className="mt-0.5">
                    <StarRating rating={item.rating} size="sm" />
                  </div>
                )}
                <p className="text-xs text-[var(--text-secondary)] truncate">
                  {item.foodName}
                </p>
              </Link>
            );
          }
        })}
      </div>
    </div>
  );
}
