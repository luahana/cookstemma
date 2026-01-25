import type { Metadata } from 'next';
import { getTranslations } from 'next-intl/server';
import { unifiedSearch } from '@/lib/api/search';
import { Pagination } from '@/components/common/Pagination';
import { SearchBar } from '@/components/search/SearchBar';
import { SearchChips } from '@/components/search/SearchChips';
import { SearchResultCard } from '@/components/search/SearchResultCard';
import { SearchEmptyState } from '@/components/search/SearchEmptyState';
import type { SearchTypeFilter } from '@/lib/types';

interface Props {
  params: Promise<{ locale: string }>;
  searchParams: Promise<{ q?: string; type?: string; page?: string }>;
}

export async function generateMetadata({ searchParams }: Props): Promise<Metadata> {
  const params = await searchParams;
  const query = params.q;

  if (query) {
    return {
      title: `Search: ${query}`,
      description: `Search results for "${query}" - find recipes, cooking logs, and hashtags on Cookstemma`,
      robots: {
        index: false, // Don't index search result pages
      },
    };
  }

  return {
    title: 'Search',
    description: 'Search for recipes, cooking logs, and hashtags on Cookstemma',
  };
}

export default async function SearchPage({ params, searchParams }: Props) {
  const { locale } = await params;
  const t = await getTranslations('search');
  const resolvedSearchParams = await searchParams;
  const query = resolvedSearchParams.q || '';
  const type = (resolvedSearchParams.type as SearchTypeFilter) || 'all';
  const urlPage = parseInt(resolvedSearchParams.page || '1', 10);
  const page = Math.max(0, urlPage - 1);

  // Only fetch if there's a query
  const results = query
    ? await unifiedSearch({ q: query, type, page, size: 12, locale })
    : null;

  // Build base URL with current filters for pagination
  const filterParams = new URLSearchParams();
  if (query) filterParams.set('q', query);
  if (type !== 'all') filterParams.set('type', type);
  const baseUrl = filterParams.toString()
    ? `/search?${filterParams.toString()}`
    : '/search';

  // Helper to get translated result type label
  const getResultTypeLabel = (filterType: SearchTypeFilter): string => {
    switch (filterType) {
      case 'recipes':
        return t('recipes');
      case 'logs':
        return t('cookingLogs');
      case 'hashtags':
        return t('hashtags');
      default:
        return t('results');
    }
  };

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      {/* Page header */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-[var(--text-primary)] mb-4">
          {t('title')}
        </h1>
        <div className="max-w-2xl">
          <SearchBar defaultValue={query} autoFocus={!query} placeholder={t('searchPlaceholder')} />
        </div>
      </div>

      {/* Results */}
      {query ? (
        <>
          {/* Filter chips */}
          {results && (
            <SearchChips counts={results.counts} selected={type} query={query} />
          )}

          {/* Results count */}
          {results && (
            <p className="text-sm text-[var(--text-secondary)] mb-4">
              {results.totalElements === 0
                ? t('noResultsFor', { type: getResultTypeLabel(type), query })
                : t('resultsFor', { count: results.totalElements.toLocaleString(), type: getResultTypeLabel(type), query })}
            </p>
          )}

          {/* Results grid */}
          {results && results.content.length > 0 ? (
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
              {results.content.map((item, index) => (
                <SearchResultCard key={`${item.type}-${index}`} item={item} showTypeLabel={type === 'all'} />
              ))}
            </div>
          ) : (
            results && (
              <div className="text-center py-12">
                <div className="text-4xl mb-4 opacity-50">
                  <svg
                    className="w-16 h-16 mx-auto text-[var(--text-secondary)]"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={1.5}
                      d="M9.172 16.172a4 4 0 015.656 0M9 10h.01M15 10h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                    />
                  </svg>
                </div>
                <p className="text-[var(--text-secondary)]">
                  {t('noResultsFor', { type: getResultTypeLabel(type), query })} {t('tryDifferentFilter')}
                </p>
              </div>
            )
          )}

          {/* Pagination */}
          {results && results.totalPages > 1 && (
            <Pagination
              currentPage={results.page}
              totalPages={results.totalPages}
              baseUrl={baseUrl}
            />
          )}
        </>
      ) : (
        <SearchEmptyState />
      )}
    </div>
  );
}
