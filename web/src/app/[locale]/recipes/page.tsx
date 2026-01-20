import type { Metadata } from 'next';
import { getTranslations } from 'next-intl/server';
import { getRecipes, type CookingTimeFilter } from '@/lib/api/recipes';
import { RecipeGrid } from '@/components/recipe/RecipeGrid';
import { RecipeFilters } from '@/components/common/RecipeFilters';
import { Pagination } from '@/components/common/Pagination';
import { siteConfig } from '@/config/site';

interface Props {
  params: Promise<{ locale: string }>;
  searchParams: Promise<{
    page?: string;
    sort?: 'recent' | 'popular' | 'trending' | 'mostForked';
    type?: 'all' | 'original' | 'variants';
    style?: string;
    cookingTime?: string;
    servings?: string;
    minServings?: string;
    maxServings?: string;
  }>;
}

export async function generateMetadata({ params, searchParams }: Props): Promise<Metadata> {
  const { locale } = await params;
  const queryParams = await searchParams;
  const t = await getTranslations({ locale, namespace: 'recipes' });

  // Check if there are any filters applied
  const hasFilters = queryParams.sort || queryParams.type || queryParams.style ||
    queryParams.cookingTime || queryParams.page || queryParams.minServings || queryParams.maxServings;

  return {
    title: t('title'),
    description: t('subtitle'),
    alternates: {
      canonical: `${siteConfig.url}/${locale}/recipes`,
    },
    // Add noindex for filtered/paginated pages to prevent duplicate content
    robots: hasFilters ? { index: false, follow: true } : undefined,
  };
}

export default async function RecipesPage({ params, searchParams }: Props) {
  const { locale: pageLocale } = await params;
  const queryParams = await searchParams;
  const t = await getTranslations('recipes');
  const page = parseInt(queryParams.page || '0', 10);
  const sort = queryParams.sort || 'recent';
  const typeFilter = queryParams.type === 'original' || queryParams.type === 'variants'
    ? queryParams.type
    : undefined;

  // Parse cooking style filter (maps to backend locale parameter)
  const locale = queryParams.style && queryParams.style !== 'any'
    ? queryParams.style
    : undefined;

  // Parse cooking time filter
  const cookingTime = queryParams.cookingTime && queryParams.cookingTime !== 'any'
    ? [queryParams.cookingTime as CookingTimeFilter]
    : undefined;

  // Parse servings filter
  const minServings = queryParams.minServings ? parseInt(queryParams.minServings, 10) : undefined;
  const maxServings = queryParams.maxServings ? parseInt(queryParams.maxServings, 10) : undefined;

  const recipes = await getRecipes({
    page,
    size: 12,
    sort,
    typeFilter,
    locale,
    onlyRoot: queryParams.type === 'original' ? true : undefined,
    cookingTime,
    minServings,
    maxServings,
    contentLocale: pageLocale, // Pass page locale for content translation
  });

  // Build base URL with current filters for pagination
  const filterParams = new URLSearchParams();
  if (sort !== 'recent') filterParams.set('sort', sort);
  if (queryParams.type && queryParams.type !== 'all') filterParams.set('type', queryParams.type);
  if (queryParams.style && queryParams.style !== 'any') filterParams.set('style', queryParams.style);
  if (queryParams.cookingTime && queryParams.cookingTime !== 'any') filterParams.set('cookingTime', queryParams.cookingTime);
  if (queryParams.servings && queryParams.servings !== 'any') filterParams.set('servings', queryParams.servings);
  if (queryParams.minServings) filterParams.set('minServings', queryParams.minServings);
  if (queryParams.maxServings) filterParams.set('maxServings', queryParams.maxServings);
  const baseUrl = filterParams.toString()
    ? `/recipes?${filterParams.toString()}`
    : '/recipes';

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      {/* Page header */}
      <div className="mb-6">
        <h1 className="text-3xl font-bold text-[var(--text-primary)]">
          {t('title')}
        </h1>
        <p className="text-[var(--text-secondary)] mt-2">
          {t('subtitle')}
        </p>
      </div>

      {/* Filters */}
      <RecipeFilters baseUrl="/recipes" />

      {/* Results count */}
      {recipes.totalElements !== null && recipes.totalElements > 0 && (
        <p className="text-sm text-[var(--text-secondary)] mb-4">
          {t('found', { count: recipes.totalElements.toLocaleString() })}
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
