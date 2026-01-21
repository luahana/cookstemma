'use client';

import { useRouter, useSearchParams } from 'next/navigation';
import { useTransition, useEffect } from 'react';
import { useTranslations } from 'next-intl';
import { useNavigationProgress } from '@/contexts/NavigationProgressContext';
import type { SearchCounts, SearchTypeFilter } from '@/lib/types';

interface SearchChipsProps {
  counts: SearchCounts;
  selected: SearchTypeFilter;
  query: string;
}

const CHIP_KEYS: Array<{ key: SearchTypeFilter; labelKey: string; countKey: keyof SearchCounts }> = [
  { key: 'all', labelKey: 'all', countKey: 'total' },
  { key: 'recipes', labelKey: 'recipes', countKey: 'recipes' },
  { key: 'logs', labelKey: 'logs', countKey: 'logs' },
  { key: 'hashtags', labelKey: 'hashtags', countKey: 'hashtags' },
];

export function SearchChips({ counts, selected, query }: SearchChipsProps) {
  const t = useTranslations('search');
  const router = useRouter();
  const searchParams = useSearchParams();
  const [isPending, startTransition] = useTransition();
  const { startLoading, stopLoading } = useNavigationProgress();

  // Stop loading when transition completes
  useEffect(() => {
    if (!isPending) {
      stopLoading();
    }
  }, [isPending, stopLoading]);

  const handleSelect = (type: SearchTypeFilter) => {
    const params = new URLSearchParams(searchParams.toString());
    params.set('q', query);
    if (type === 'all') {
      params.delete('type');
    } else {
      params.set('type', type);
    }
    params.delete('page'); // Reset to first page on filter change
    startLoading();
    startTransition(() => {
      router.push(`/search?${params.toString()}`);
    });
  };

  return (
    <div className="flex flex-wrap gap-2 mb-6">
      {CHIP_KEYS.map(({ key, labelKey, countKey }) => {
        const count = counts[countKey];
        const isSelected = selected === key;

        return (
          <button
            key={key}
            onClick={() => handleSelect(key)}
            className={`
              inline-flex items-center px-4 py-2 rounded-full text-sm font-medium
              transition-all duration-200 border
              ${
                isSelected
                  ? 'bg-[var(--primary)] text-white border-[var(--primary)]'
                  : 'bg-[var(--surface)] text-[var(--text-secondary)] border-[var(--border)] hover:border-[var(--primary)] hover:text-[var(--text-primary)]'
              }
            `}
          >
            <span>{t(labelKey)}</span>
            <span
              className={`
                ml-2 px-2 py-0.5 rounded-full text-xs font-semibold
                ${
                  isSelected
                    ? 'bg-white/20 text-white'
                    : 'bg-[var(--hover-bg)] text-[var(--text-secondary)]'
                }
              `}
            >
              {count.toLocaleString()}
            </span>
          </button>
        );
      })}
    </div>
  );
}
