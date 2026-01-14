'use client';

import { useRouter, useSearchParams } from 'next/navigation';
import { useCallback } from 'react';

interface LogFiltersProps {
  baseUrl: string;
}

export function LogFilters({ baseUrl }: LogFiltersProps) {
  const router = useRouter();
  const searchParams = useSearchParams();

  const currentOutcome = searchParams.get('outcome') || 'all';

  const updateFilters = useCallback(
    (value: string) => {
      const params = new URLSearchParams(searchParams.toString());

      if (value === 'all') {
        params.delete('outcome');
      } else {
        params.set('outcome', value);
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
      {/* Outcome filter */}
      <div className="flex items-center gap-2">
        <label htmlFor="outcome" className="text-sm text-[var(--text-secondary)]">
          Outcome:
        </label>
        <select
          id="outcome"
          value={currentOutcome}
          onChange={(e) => updateFilters(e.target.value)}
          className="px-3 py-1.5 text-sm bg-[var(--surface)] border border-[var(--border)] rounded-lg focus:outline-none focus:border-[var(--primary)]"
        >
          <option value="all">All Outcomes</option>
          <option value="SUCCESS">Success</option>
          <option value="PARTIAL">Partial</option>
          <option value="FAILED">Failed</option>
        </select>
      </div>

      {/* Active filters indicator */}
      {currentOutcome !== 'all' && (
        <button
          onClick={() => {
            router.push(baseUrl);
          }}
          className="text-sm text-[var(--primary)] hover:underline"
        >
          Clear filter
        </button>
      )}
    </div>
  );
}
