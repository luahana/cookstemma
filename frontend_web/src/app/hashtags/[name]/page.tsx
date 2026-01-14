import type { Metadata } from 'next';
import Link from 'next/link';
import { getHashtagCounts, getRecipesByHashtag, getLogsByHashtag } from '@/lib/api/hashtags';
import { RecipeGrid } from '@/components/recipe/RecipeGrid';
import { LogGrid } from '@/components/log/LogGrid';
import { Pagination } from '@/components/common/Pagination';
import { BreadcrumbJsonLd } from '@/components/seo/BreadcrumbJsonLd';
import { siteConfig } from '@/config/site';

interface Props {
  params: Promise<{ name: string }>;
  searchParams: Promise<{ tab?: string; page?: string }>;
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { name } = await params;
  const decodedName = decodeURIComponent(name);

  return {
    title: `#${decodedName}`,
    description: `Recipes and cooking logs tagged with #${decodedName} on Pairing Planet`,
    alternates: {
      canonical: `${siteConfig.url}/hashtags/${encodeURIComponent(decodedName)}`,
    },
    openGraph: {
      title: `#${decodedName} | Pairing Planet`,
      description: `Recipes and cooking logs tagged with #${decodedName}`,
      type: 'website',
    },
  };
}

export default async function HashtagPage({ params, searchParams }: Props) {
  const { name } = await params;
  const { tab = 'recipes', page: pageParam = '0' } = await searchParams;
  const page = parseInt(pageParam, 10);
  const decodedName = decodeURIComponent(name);

  let counts;
  try {
    counts = await getHashtagCounts(decodedName);
  } catch {
    counts = { recipeCount: 0, logCount: 0 };
  }

  const tabs = [
    { id: 'recipes', label: 'Recipes', count: counts.recipeCount },
    { id: 'logs', label: 'Cooking Logs', count: counts.logCount },
  ];

  // Fetch content based on active tab
  const recipes = tab === 'recipes'
    ? await getRecipesByHashtag(decodedName, { page, size: 12 })
    : null;
  const logs = tab === 'logs'
    ? await getLogsByHashtag(decodedName, { page, size: 12 })
    : null;

  return (
    <>
      <BreadcrumbJsonLd
        items={[
          { name: 'Home', href: '/' },
          { name: `#${decodedName}`, href: `/hashtags/${encodeURIComponent(decodedName)}` },
        ]}
      />

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Header */}
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-[var(--success)]">
            #{decodedName}
          </h1>
          <p className="text-[var(--text-secondary)] mt-2">
            {counts.recipeCount + counts.logCount} posts with this hashtag
          </p>
        </div>

        {/* Tabs */}
        <div className="border-b border-[var(--border)] mb-6">
          <nav className="flex gap-8">
            {tabs.map((t) => (
              <Link
                key={t.id}
                href={`/hashtags/${encodeURIComponent(decodedName)}?tab=${t.id}`}
                className={`pb-4 px-1 border-b-2 font-medium transition-colors ${
                  tab === t.id
                    ? 'border-[var(--primary)] text-[var(--primary)]'
                    : 'border-transparent text-[var(--text-secondary)] hover:text-[var(--text-primary)]'
                }`}
              >
                {t.label} ({t.count})
              </Link>
            ))}
          </nav>
        </div>

        {/* Content */}
        {tab === 'recipes' && recipes && (
          <>
            <RecipeGrid
              recipes={recipes.content}
              emptyMessage={`No recipes found with #${decodedName}`}
            />
            {recipes.totalPages !== null && recipes.totalPages > 1 && (
              <Pagination
                currentPage={recipes.currentPage || 0}
                totalPages={recipes.totalPages}
                baseUrl={`/hashtags/${encodeURIComponent(decodedName)}?tab=recipes`}
              />
            )}
          </>
        )}

        {tab === 'logs' && logs && (
          <>
            <LogGrid
              logs={logs.content}
              emptyMessage={`No cooking logs found with #${decodedName}`}
            />
            {logs.totalPages !== null && logs.totalPages > 1 && (
              <Pagination
                currentPage={logs.currentPage || 0}
                totalPages={logs.totalPages}
                baseUrl={`/hashtags/${encodeURIComponent(decodedName)}?tab=logs`}
              />
            )}
          </>
        )}
      </div>
    </>
  );
}
