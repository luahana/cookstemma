import type { Metadata } from 'next';
import { Link } from '@/i18n/navigation';
import { getTranslations } from 'next-intl/server';
import { getHashtaggedFeed } from '@/lib/api/hashtags';
import { HashtaggedFeed } from '@/components/hashtag/HashtaggedFeed';
import { PopularHashtagsList } from '@/components/hashtag/PopularHashtagsList';
import { Pagination } from '@/components/common/Pagination';
import { BreadcrumbJsonLd } from '@/components/seo/BreadcrumbJsonLd';
import { siteConfig } from '@/config/site';

interface Props {
  params: Promise<{ locale: string }>;
  searchParams: Promise<{ tab?: string; page?: string }>;
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations('hashtagsPage');

  return {
    title: t('metaTitle'),
    description: t('metaDescription'),
    alternates: {
      canonical: `${siteConfig.url}/${locale}/hashtags`,
    },
    openGraph: {
      title: t('metaTitle'),
      description: t('metaDescription'),
      type: 'website',
    },
  };
}

export default async function HashtagsPage({ params, searchParams }: Props) {
  const { locale } = await params;
  const { tab = 'all', page: pageParam = '0' } = await searchParams;
  const page = parseInt(pageParam, 10);
  const t = await getTranslations('hashtagsPage');
  const tNav = await getTranslations('nav');

  const tabs = [
    { id: 'all', label: t('allTab') },
    { id: 'popular', label: t('popularTab') },
  ];

  // Fetch content based on active tab
  const feed = tab === 'all'
    ? await getHashtaggedFeed({ page, size: 12 })
    : null;

  return (
    <>
      <BreadcrumbJsonLd
        locale={locale}
        items={[
          { name: tNav('home') || 'Home', href: '/' },
          { name: t('title'), href: '/hashtags' },
        ]}
      />

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Header */}
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-[var(--text-primary)]">
            {t('title')}
          </h1>
          <p className="text-[var(--text-secondary)] mt-2">
            {t('subtitle')}
          </p>
        </div>

        {/* Tabs */}
        <div className="border-b border-[var(--border)] mb-6">
          <nav className="flex gap-8">
            {tabs.map((tabItem) => (
              <Link
                key={tabItem.id}
                href={`/hashtags?tab=${tabItem.id}`}
                className={`pb-4 px-1 border-b-2 font-medium transition-colors ${
                  tab === tabItem.id
                    ? 'border-[var(--primary)] text-[var(--primary)]'
                    : 'border-transparent text-[var(--text-secondary)] hover:text-[var(--text-primary)]'
                }`}
              >
                {tabItem.label}
              </Link>
            ))}
          </nav>
        </div>

        {/* Content */}
        {tab === 'all' && feed && (
          <>
            <HashtaggedFeed
              items={feed.content}
              emptyMessage={t('noContent')}
            />
            {feed.totalPages !== null && feed.totalPages > 1 && (
              <Pagination
                currentPage={feed.currentPage || 0}
                totalPages={feed.totalPages}
                baseUrl="/hashtags?tab=all"
              />
            )}
          </>
        )}

        {tab === 'popular' && (
          <PopularHashtagsList />
        )}
      </div>
    </>
  );
}
