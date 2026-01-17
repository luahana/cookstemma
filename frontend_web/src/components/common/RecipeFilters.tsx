'use client';

import { useRouter, useSearchParams } from 'next/navigation';
import { useCallback } from 'react';
import { CookingStyleSelect, COOKING_STYLE_FILTER_OPTIONS } from './CookingStyleSelect';

interface RecipeFiltersProps {
  baseUrl: string;
}

const COOKING_TIME_OPTIONS = [
  { value: 'any', label: 'Any Time' },
  { value: 'UNDER_15_MIN', label: 'Under 15 min' },
  { value: 'MIN_15_TO_30', label: '15-30 min' },
  { value: 'MIN_30_TO_60', label: '30-60 min' },
  { value: 'HOUR_1_TO_2', label: '1-2 hours' },
  { value: 'OVER_2_HOURS', label: '2+ hours' },
] as const;

const SERVINGS_OPTIONS = [
  { value: 'any', label: 'Any Servings', min: undefined, max: undefined },
  { value: '1-2', label: '1-2', min: 1, max: 2 },
  { value: '3-4', label: '3-4', min: 3, max: 4 },
  { value: '5-6', label: '5-6', min: 5, max: 6 },
  { value: '7+', label: '7+', min: 7, max: undefined },
] as const;

export function RecipeFilters({ baseUrl }: RecipeFiltersProps) {
  const router = useRouter();
  const searchParams = useSearchParams();

  const currentSort = searchParams.get('sort') || 'recent';
  const currentType = searchParams.get('type') || 'all';
  const currentCookingStyle = searchParams.get('style') || 'any';
  const currentCookingTime = searchParams.get('cookingTime') || 'any';
  const currentServings = searchParams.get('servings') || 'any';

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
      router.push(`${baseUrl}${queryString ? `?${queryString}` : ''}`);
    },
    [router, searchParams, baseUrl]
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
          Sort:
        </label>
        <select
          id="sort"
          value={currentSort}
          onChange={(e) => updateFilters('sort', e.target.value)}
          className="px-3 py-1.5 text-sm bg-[var(--surface)] border border-[var(--border)] rounded-lg focus:outline-none focus:border-[var(--primary)]"
        >
          <option value="recent">Most Recent</option>
          <option value="trending">Trending</option>
          <option value="mostForked">Most Forked</option>
        </select>
      </div>

      {/* Type filter */}
      <div className="flex items-center gap-2">
        <label htmlFor="type" className="text-sm text-[var(--text-secondary)]">
          Type:
        </label>
        <select
          id="type"
          value={currentType}
          onChange={(e) => updateFilters('type', e.target.value)}
          className="px-3 py-1.5 text-sm bg-[var(--surface)] border border-[var(--border)] rounded-lg focus:outline-none focus:border-[var(--primary)]"
        >
          <option value="all">All Recipes</option>
          <option value="original">Originals Only</option>
          <option value="variants">Variants Only</option>
        </select>
      </div>

      {/* Cooking Style filter */}
      <div className="flex items-center gap-2">
        <label className="text-sm text-[var(--text-secondary)]">
          Cooking Style:
        </label>
        <CookingStyleSelect
          value={currentCookingStyle}
          onChange={(value) => updateFilters('style', value)}
          options={COOKING_STYLE_FILTER_OPTIONS}
          className="w-44"
        />
      </div>

      {/* Cooking Time filter */}
      <div className="flex items-center gap-2">
        <label htmlFor="cookingTime" className="text-sm text-[var(--text-secondary)]">
          Time:
        </label>
        <select
          id="cookingTime"
          value={currentCookingTime}
          onChange={(e) => updateFilters('cookingTime', e.target.value)}
          className="px-3 py-1.5 text-sm bg-[var(--surface)] border border-[var(--border)] rounded-lg focus:outline-none focus:border-[var(--primary)]"
        >
          {COOKING_TIME_OPTIONS.map((option) => (
            <option key={option.value} value={option.value}>
              {option.label}
            </option>
          ))}
        </select>
      </div>

      {/* Servings filter */}
      <div className="flex items-center gap-2">
        <label htmlFor="servings" className="text-sm text-[var(--text-secondary)]">
          Servings:
        </label>
        <select
          id="servings"
          value={currentServings}
          onChange={(e) => updateFilters('servings', e.target.value)}
          className="px-3 py-1.5 text-sm bg-[var(--surface)] border border-[var(--border)] rounded-lg focus:outline-none focus:border-[var(--primary)]"
        >
          {SERVINGS_OPTIONS.map((option) => (
            <option key={option.value} value={option.value}>
              {option.label}
            </option>
          ))}
        </select>
      </div>

      {/* Active filters indicator */}
      {hasActiveFilters && (
        <button
          onClick={() => {
            router.push(baseUrl);
          }}
          className="text-sm text-[var(--primary)] hover:underline"
        >
          Clear filters
        </button>
      )}
    </div>
  );
}
