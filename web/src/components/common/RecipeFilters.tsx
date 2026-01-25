'use client';

import { useRouter, useSearchParams } from 'next/navigation';
import { useCallback, useTransition, useEffect } from 'react';
import { useTranslations } from 'next-intl';
import { useNavigationProgress } from '@/contexts/NavigationProgressContext';
import { CookingStyleSelect, useCookingStyleFilterOptions } from './CookingStyleSelect';

interface RecipeFiltersProps {
  baseUrl: string;
}

const SERVINGS_OPTIONS = [
  { value: 'any', min: undefined, max: undefined },
  { value: '1-2', min: 1, max: 2 },
  { value: '3-4', min: 3, max: 4 },
  { value: '5-6', min: 5, max: 6 },
  { value: '7+', min: 7, max: undefined },
] as const;

export function RecipeFilters({ baseUrl }: RecipeFiltersProps) {
  const t = useTranslations('filters');
  const router = useRouter();
  const searchParams = useSearchParams();
  const cookingStyleOptions = useCookingStyleFilterOptions();
  const [isPending, startTransition] = useTransition();
  const { startLoading, stopLoading } = useNavigationProgress();

  const currentSort = searchParams.get('sort') || 'recent';
  const currentType = searchParams.get('type') || 'all';
  const currentCookingStyle = searchParams.get('style') || 'any';
  const currentCookingTime = searchParams.get('cookingTime') || 'any';
  const currentServings = searchParams.get('servings') || 'any';

  // Stop loading when transition completes
  useEffect(() => {
    if (!isPending) {
      stopLoading();
    }
  }, [isPending, stopLoading]);

  const updateFilters = useCallback(
    (key: string, value: string) => {
      const params = new URLSearchParams(searchParams.toString());

      if (value === 'recent' || value === 'all' || value === 'any') {
        params.delete(key);
        // For servings, also clean up min/max params
        if (key === 'servings') {
          params.delete('minServings');
          params.delete('maxServings');
        }
      } else {
        params.set(key, value);
        // For servings, set min/max params
        if (key === 'servings') {
          const option = SERVINGS_OPTIONS.find((o) => o.value === value);
          if (option) {
            if (option.min !== undefined) {
              params.set('minServings', String(option.min));
            } else {
              params.delete('minServings');
            }
            if (option.max !== undefined) {
              params.set('maxServings', String(option.max));
            } else {
              params.delete('maxServings');
            }
          }
        }
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

  const hasActiveFilters =
    currentSort !== 'recent' ||
    currentType !== 'all' ||
    currentCookingStyle !== 'any' ||
    currentCookingTime !== 'any' ||
    currentServings !== 'any';

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
          <option value="mostForked">{t('sortMostForked')}</option>
        </select>
      </div>

      {/* Type filter */}
      <div className="flex items-center gap-2">
        <label htmlFor="type" className="text-sm text-[var(--text-secondary)]">
          {t('type')}
        </label>
        <select
          id="type"
          value={currentType}
          onChange={(e) => updateFilters('type', e.target.value)}
          className="px-3 py-1.5 text-sm bg-[var(--surface)] border border-[var(--border)] rounded-lg focus:outline-none focus:border-[var(--primary)]"
        >
          <option value="all">{t('typeAll')}</option>
          <option value="original">{t('typeOriginals')}</option>
          <option value="variants">{t('typeVariants')}</option>
        </select>
      </div>

      {/* Cooking Style filter */}
      <div className="flex items-center gap-2">
        <label className="text-sm text-[var(--text-secondary)]">
          {t('cookingStyle')}
        </label>
        <CookingStyleSelect
          value={currentCookingStyle}
          onChange={(value) => updateFilters('style', value)}
          options={cookingStyleOptions}
          className="w-44"
        />
      </div>

      {/* Cooking Time filter */}
      <div className="flex items-center gap-2">
        <label htmlFor="cookingTime" className="text-sm text-[var(--text-secondary)]">
          {t('time')}
        </label>
        <select
          id="cookingTime"
          value={currentCookingTime}
          onChange={(e) => updateFilters('cookingTime', e.target.value)}
          className="px-3 py-1.5 text-sm bg-[var(--surface)] border border-[var(--border)] rounded-lg focus:outline-none focus:border-[var(--primary)]"
        >
          <option value="any">{t('timeAny')}</option>
          <option value="UNDER_15_MIN">{t('timeUnder15')}</option>
          <option value="MIN_15_TO_30">{t('time15to30')}</option>
          <option value="MIN_30_TO_60">{t('time30to60')}</option>
          <option value="HOUR_1_TO_2">{t('time1to2hours')}</option>
          <option value="OVER_2_HOURS">{t('timeOver2hours')}</option>
        </select>
      </div>

      {/* Servings filter */}
      <div className="flex items-center gap-2">
        <label htmlFor="servings" className="text-sm text-[var(--text-secondary)]">
          {t('servings')}
        </label>
        <select
          id="servings"
          value={currentServings}
          onChange={(e) => updateFilters('servings', e.target.value)}
          className="px-3 py-1.5 text-sm bg-[var(--surface)] border border-[var(--border)] rounded-lg focus:outline-none focus:border-[var(--primary)]"
        >
          <option value="any">{t('servingsAny')}</option>
          <option value="1-2">{t('servings1to2')}</option>
          <option value="3-4">{t('servings3to4')}</option>
          <option value="5-6">{t('servings5to6')}</option>
          <option value="7+">{t('servings7plus')}</option>
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
