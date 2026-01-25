'use client';

import { useRouter, useSearchParams } from 'next/navigation';
import { useCallback, useTransition, useEffect } from 'react';
import { useTranslations } from 'next-intl';
import { useNavigationProgress } from '@/contexts/NavigationProgressContext';

interface LogFiltersProps {
  baseUrl: string;
}

export function LogFilters({ baseUrl }: LogFiltersProps) {
  const t = useTranslations('filters');
  const router = useRouter();
  const searchParams = useSearchParams();
  const [isPending, startTransition] = useTransition();
  const { startLoading, stopLoading } = useNavigationProgress();

  const currentSort = searchParams.get('sort') || 'recent';
  const currentRating = searchParams.get('rating') || 'all';

  // Stop loading when transition completes
  useEffect(() => {
    if (!isPending) {
      stopLoading();
    }
  }, [isPending, stopLoading]);

  const updateFilters = useCallback(
    (key: string, value: string) => {
      const params = new URLSearchParams(searchParams.toString());

      if (value === 'all' || value === 'recent') {
        params.delete(key);
        // Clear rating range params when 'all' is selected
        if (key === 'rating') {
          params.delete('minRating');
          params.delete('maxRating');
        }
      } else if (key === 'rating') {
        // Set rating range based on selection
        const [min, max] = value.split('-');
        params.set('minRating', min);
        params.set('maxRating', max);
        params.delete('rating');
      } else {
        params.set(key, value);
      }

      // Reset to first page when filters change
      params.delete('page');

      const queryString = params.toString();
      startLoading();
      startTransition(() => {
        router.push(`${baseUrl}${queryString ? `?${queryString}` : ''}`);
      });
    },
    [router, searchParams, baseUrl, startLoading]
  );

  // Determine current rating selection from params
  const getRatingSelection = () => {
    const minRating = searchParams.get('minRating');
    const maxRating = searchParams.get('maxRating');
    if (minRating && maxRating) {
      return `${minRating}-${maxRating}`;
    }
    return 'all';
  };

  const hasActiveFilters = currentSort !== 'recent' || getRatingSelection() !== 'all';

  return (
    <div className="flex flex-wrap items-center gap-4 mb-6">
      {/* Sort */}
      <div className="flex items-center gap-2">
        <label htmlFor="sort" className="text-sm text-[var(--text-secondary)]">
          {t('sort')}
        </label>
        <select
          id="sort"
          value={currentSort}
          onChange={(e) => updateFilters('sort', e.target.value)}
          className="px-3 py-1.5 text-sm bg-[var(--surface)] border border-[var(--border)] rounded-lg focus:outline-none focus:border-[var(--primary)]"
        >
          <option value="recent">{t('sortRecent')}</option>
          <option value="popular">{t('sortPopular')}</option>
          <option value="trending">{t('sortTrending')}</option>
        </select>
      </div>

      {/* Rating filter */}
      <div className="flex items-center gap-2">
        <label htmlFor="rating" className="text-sm text-[var(--text-secondary)]">
          {t('rating')}
        </label>
        <select
          id="rating"
          value={getRatingSelection()}
          onChange={(e) => updateFilters('rating', e.target.value)}
          className="px-3 py-1.5 text-sm bg-[var(--surface)] border border-[var(--border)] rounded-lg focus:outline-none focus:border-[var(--primary)]"
        >
          <option value="all">{t('ratingAll')}</option>
          <option value="5-5">{t('rating5Stars')}</option>
          <option value="4-5">{t('rating4to5Stars')}</option>
          <option value="3-5">{t('rating3PlusStars')}</option>
          <option value="1-2">{t('rating1to2Stars')}</option>
        </select>
      </div>

      {/* Active filters indicator */}
      {hasActiveFilters && (
        <button
          onClick={() => {
            startLoading();
            startTransition(() => {
              router.push(baseUrl);
            });
          }}
          className="text-sm text-[var(--primary)] hover:underline"
        >
          {t('clearFilters')}
        </button>
      )}
    </div>
  );
}
