import type { Metadata } from 'next';
import { Link } from '@/i18n/navigation';
import { getTranslations } from 'next-intl/server';
import { getHashtagCounts, getRecipesByHashtag, getLogsByHashtag, getContentByHashtag } from '@/lib/api/hashtags';
import { RecipeGrid } from '@/components/recipe/RecipeGrid';
import { LogGrid } from '@/components/log/LogGrid';
import { HashtaggedFeed } from '@/components/hashtag/HashtaggedFeed';
import { Pagination } from '@/components/common/Pagination';
import { BreadcrumbJsonLd } from '@/components/seo/BreadcrumbJsonLd';
import { siteConfig } from '@/config/site';

interface Props {
  params: Promise<{ name: string; locale: string }>;
  searchParams: Promise<{ tab?: string; page?: string }>;
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { name, locale } = await params;
  const decodedName = decodeURIComponent(name);

  return {
    title: `#${decodedName}`,
    description: `Recipes and cooking logs tagged with #${decodedName} on Cookstemma`,
    alternates: {
      canonical: `${siteConfig.url}/${locale}/hashtags/${encodeURIComponent(decodedName)}`,
    },
    openGraph: {
      title: `#${decodedName} | Cookstemma`,
      description: `Recipes and cooking logs tagged with #${decodedName}`,
      type: 'website',
    },
  };
}

export default async function HashtagPage({ params, searchParams }: Props) {
  const { name, locale } = await params;
  const { tab = 'all', page: pageParam = '1' } = await searchParams;
  const page = Math.max(0, parseInt(pageParam, 10) - 1);
  const decodedName = decodeURIComponent(name);
  const t = await getTranslations('hashtags');
  const tNav = await getTranslations('nav');

  let counts;
  try {
    counts = await getHashtagCounts(decodedName, locale);
  } catch {
    counts = { exists: false, normalizedName: decodedName, recipeCount: 0, logPostCount: 0 };
  }

  const totalCount = counts.recipeCount + counts.logPostCount;
  const tabs = [
    { id: 'all', label: t('allTab'), count: totalCount },
    { id: 'recipes', label: t('recipesTab'), count: counts.recipeCount },
    { id: 'logs', label: t('logsTab'), count: counts.logPostCount },
  ];

  // Fetch content based on active tab
  const allContent = tab === 'all'
    ? await getContentByHashtag(decodedName, { page, size: 12, locale })
    : null;
  const recipes = tab === 'recipes'
    ? await getRecipesByHashtag(decodedName, { page, size: 12, locale })
    : null;
  const logs = tab === 'logs'
    ? await getLogsByHashtag(decodedName, { page, size: 12, locale })
    : null;

  return (
    <>
      <BreadcrumbJsonLd
        locale={locale}
        items={[
          { name: tNav('home') || 'Home', href: '/' },
          { name: `#${decodedName}`, href: `/hashtags/${encodeURIComponent(decodedName)}` },
        ]}
      />

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Header */}
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-hashtag">
            #{decodedName}
          </h1>
          <p className="text-[var(--text-secondary)] mt-2">
            {t('postsWithTag', { count: counts.recipeCount + counts.logPostCount })}
          </p>
        </div>

        {/* Tabs */}
        <div className="border-b border-[var(--border)] mb-6">
          <nav className="flex gap-8">
            {tabs.map((tabItem) => (
              <Link
                key={tabItem.id}
                href={`/hashtags/${encodeURIComponent(decodedName)}?tab=${tabItem.id}`}
                className={`pb-4 px-1 border-b-2 font-medium transition-colors ${
                  tab === tabItem.id
                    ? 'border-[var(--primary)] text-[var(--primary)]'
                    : 'border-transparent text-[var(--text-secondary)] hover:text-[var(--text-primary)]'
                }`}
              >
                {tabItem.label} ({tabItem.count})
              </Link>
            ))}
          </nav>
        </div>

        {/* Content */}
        {tab === 'all' && allContent && (
          <>
            <HashtaggedFeed
              items={allContent.content}
              emptyMessage={t('noContent')}
            />
            {allContent.totalPages !== null && allContent.totalPages > 1 && (
              <Pagination
                currentPage={allContent.currentPage || 0}
                totalPages={allContent.totalPages}
                baseUrl={`/hashtags/${encodeURIComponent(decodedName)}?tab=all`}
              />
            )}
          </>
        )}

        {tab === 'recipes' && recipes && (
          <>
            <RecipeGrid
              recipes={recipes.content}
              emptyMessage={t('noRecipes')}
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
              emptyMessage={t('noLogs')}
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
