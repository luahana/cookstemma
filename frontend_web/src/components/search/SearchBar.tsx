'use client';

import { useRouter, useSearchParams } from 'next/navigation';
import { useState, useCallback } from 'react';

interface SearchBarProps {
  placeholder?: string;
  defaultValue?: string;
  autoFocus?: boolean;
}

export function SearchBar({
  placeholder = 'Search recipes...',
  defaultValue = '',
  autoFocus = false,
}: SearchBarProps) {
  const router = useRouter();
  const searchParams = useSearchParams();
  const [query, setQuery] = useState(defaultValue || searchParams.get('q') || '');

  const handleSubmit = useCallback(
    (e: React.FormEvent) => {
      e.preventDefault();
      const trimmed = query.trim();
      if (trimmed) {
        router.push(`/search?q=${encodeURIComponent(trimmed)}`);
      }
    },
    [query, router],
  );

  return (
    <form onSubmit={handleSubmit} className="w-full">
      <div className="relative">
        <input
          type="search"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder={placeholder}
          autoFocus={autoFocus}
          className="w-full px-4 py-3 pl-12 bg-[var(--surface)] border border-[var(--border)] rounded-xl text-[var(--text-primary)] placeholder-[var(--text-secondary)] focus:outline-none focus:border-[var(--primary)] focus:ring-2 focus:ring-[var(--primary-light)] transition-colors"
        />
        <svg
          className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-[var(--text-secondary)]"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth={2}
            d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
          />
        </svg>
        {query && (
          <button
            type="button"
            onClick={() => setQuery('')}
            className="absolute right-14 top-1/2 -translate-y-1/2 p-1 text-[var(--text-secondary)] hover:text-[var(--text-primary)]"
          >
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M6 18L18 6M6 6l12 12"
              />
            </svg>
          </button>
        )}
        <button
          type="submit"
          className="absolute right-2 top-1/2 -translate-y-1/2 px-4 py-1.5 bg-[var(--primary)] text-white rounded-lg hover:bg-[var(--primary-dark)] transition-colors text-sm font-medium"
        >
          Search
        </button>
      </div>
    </form>
  );
}
