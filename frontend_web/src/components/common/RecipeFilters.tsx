'use client';

import { useRouter, useSearchParams } from 'next/navigation';
import { useCallback } from 'react';

interface RecipeFiltersProps {
  baseUrl: string;
}

export function RecipeFilters({ baseUrl }: RecipeFiltersProps) {
  const router = useRouter();
  const searchParams = useSearchParams();

  const currentSort = searchParams.get('sort') || 'recent';
  const currentType = searchParams.get('type') || 'all';

  const updateFilters = useCallback(
    (key: string, value: string) => {
      const params = new URLSearchParams(searchParams.toString());

      if (value === 'recent' || value === 'all') {
        params.delete(key);
      } else {
        params.set(key, value);
      }

      // Reset to first page when filters change
      params.delete('page');

      const queryString = params.toString();
      router.push(`${baseUrl}${queryString ? `?${queryString}` : ''}`);
    },
    [router, searchParams, baseUrl]
  );

  return (
    <div className="flex flex-wrap items-center gap-4 mb-6">
      {/* Sort */}
      <div className="flex items-center gap-2">
        <label htmlFor="sort" className="text-sm text-[var(--text-secondary)]">
          Sort by:
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
          Show:
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

      {/* Active filters indicator */}
      {(currentSort !== 'recent' || currentType !== 'all') && (
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
