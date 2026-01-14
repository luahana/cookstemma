import type { Metadata } from 'next';
import { getRecipes } from '@/lib/api/recipes';
import { RecipeGrid } from '@/components/recipe/RecipeGrid';
import { RecipeFilters } from '@/components/common/RecipeFilters';
import { Pagination } from '@/components/common/Pagination';
import { siteConfig } from '@/config/site';

export const metadata: Metadata = {
  title: 'Recipes',
  description: 'Browse and discover delicious recipes from our community',
  alternates: {
    canonical: `${siteConfig.url}/recipes`,
  },
};

interface Props {
  searchParams: Promise<{
    page?: string;
    sort?: 'recent' | 'trending' | 'mostForked';
    type?: 'all' | 'original' | 'variants';
  }>;
}

export default async function RecipesPage({ searchParams }: Props) {
  const params = await searchParams;
  const page = parseInt(params.page || '0', 10);
  const sort = params.sort || 'recent';
  const typeFilter = params.type === 'original' || params.type === 'variants'
    ? params.type
    : undefined;

  const recipes = await getRecipes({
    page,
    size: 12,
    sort,
    typeFilter,
    onlyRoot: params.type === 'original' ? true : undefined,
  });

  // Build base URL with current filters for pagination
  const filterParams = new URLSearchParams();
  if (sort !== 'recent') filterParams.set('sort', sort);
  if (params.type && params.type !== 'all') filterParams.set('type', params.type);
  const baseUrl = filterParams.toString()
    ? `/recipes?${filterParams.toString()}`
    : '/recipes';

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      {/* Page header */}
      <div className="mb-6">
        <h1 className="text-3xl font-bold text-[var(--text-primary)]">
          Recipes
        </h1>
        <p className="text-[var(--text-secondary)] mt-2">
          Discover recipes from our community of home cooks
        </p>
      </div>

      {/* Filters */}
      <RecipeFilters baseUrl="/recipes" />

      {/* Results count */}
      {recipes.totalElements !== null && recipes.totalElements > 0 && (
        <p className="text-sm text-[var(--text-secondary)] mb-4">
          {recipes.totalElements.toLocaleString()} recipes found
        </p>
      )}

      {/* Recipe grid */}
      <RecipeGrid recipes={recipes.content} />

      {/* Pagination */}
      {recipes.totalPages !== null && recipes.totalPages > 1 && (
        <Pagination
          currentPage={recipes.currentPage || 0}
          totalPages={recipes.totalPages}
          baseUrl={baseUrl}
        />
      )}
    </div>
  );
}
