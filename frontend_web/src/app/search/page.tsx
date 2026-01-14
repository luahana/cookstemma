import type { Metadata } from 'next';
import { getRecipes } from '@/lib/api/recipes';
import { RecipeGrid } from '@/components/recipe/RecipeGrid';
import { Pagination } from '@/components/common/Pagination';
import { SearchBar } from '@/components/search/SearchBar';

interface Props {
  searchParams: Promise<{ q?: string; page?: string }>;
}

export async function generateMetadata({ searchParams }: Props): Promise<Metadata> {
  const params = await searchParams;
  const query = params.q;

  if (query) {
    return {
      title: `Search: ${query}`,
      description: `Search results for "${query}" - find recipes on Pairing Planet`,
      robots: {
        index: false, // Don't index search result pages
      },
    };
  }

  return {
    title: 'Search Recipes',
    description: 'Search for recipes on Pairing Planet',
  };
}

export default async function SearchPage({ searchParams }: Props) {
  const params = await searchParams;
  const query = params.q || '';
  const page = parseInt(params.page || '0', 10);

  // Only fetch if there's a query
  const recipes = query
    ? await getRecipes({ q: query, page, size: 12 })
    : null;

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      {/* Page header */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-[var(--text-primary)] mb-4">
          Search Recipes
        </h1>
        <div className="max-w-2xl">
          <SearchBar defaultValue={query} autoFocus={!query} />
        </div>
      </div>

      {/* Results */}
      {query ? (
        <>
          {/* Results count */}
          {recipes && recipes.totalElements !== null && (
            <p className="text-sm text-[var(--text-secondary)] mb-4">
              {recipes.totalElements === 0
                ? `No recipes found for "${query}"`
                : `${recipes.totalElements.toLocaleString()} recipes found for "${query}"`}
            </p>
          )}

          {/* Recipe grid */}
          {recipes && (
            <RecipeGrid
              recipes={recipes.content}
              emptyMessage={`No recipes found for "${query}". Try a different search term.`}
            />
          )}

          {/* Pagination */}
          {recipes && recipes.totalPages !== null && recipes.totalPages > 1 && (
            <Pagination
              currentPage={recipes.currentPage || 0}
              totalPages={recipes.totalPages}
              baseUrl={`/search?q=${encodeURIComponent(query)}`}
            />
          )}
        </>
      ) : (
        <div className="text-center py-16">
          <div className="text-6xl mb-4">
            <svg
              className="w-24 h-24 mx-auto text-[var(--text-secondary)] opacity-50"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={1.5}
                d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
              />
            </svg>
          </div>
          <h2 className="text-xl font-semibold text-[var(--text-primary)] mb-2">
            Start searching
          </h2>
          <p className="text-[var(--text-secondary)] max-w-md mx-auto">
            Enter a keyword to find recipes. Try searching for ingredients, dish names, or cooking styles.
          </p>
        </div>
      )}
    </div>
  );
}
