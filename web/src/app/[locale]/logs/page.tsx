import type { Metadata } from 'next';
import { getTranslations } from 'next-intl/server';
import { getLogs } from '@/lib/api/logs';
import { LogGrid } from '@/components/log/LogGrid';
import { LogFilters } from '@/components/common/LogFilters';
import { Pagination } from '@/components/common/Pagination';
import { siteConfig } from '@/config/site';

interface Props {
  params: Promise<{ locale: string }>;
  searchParams: Promise<{
    page?: string;
    sort?: 'recent' | 'popular' | 'trending';
    minRating?: string;
    maxRating?: string;
  }>;
}

export async function generateMetadata({ params, searchParams }: Props): Promise<Metadata> {
  const { locale } = await params;
  const queryParams = await searchParams;
  const t = await getTranslations({ locale, namespace: 'logs' });

  // Check if there are any filters applied
  const hasFilters = queryParams.sort || queryParams.page || queryParams.minRating || queryParams.maxRating;

  return {
    title: t('title'),
    description: t('subtitle'),
    alternates: {
      canonical: `${siteConfig.url}/${locale}/logs`,
    },
    // Add noindex for filtered/paginated pages to prevent duplicate content
    robots: hasFilters ? { index: false, follow: true } : undefined,
  };
}

export default async function LogsPage({ searchParams }: Props) {
  const queryParams = await searchParams;
  const t = await getTranslations('logs');
  const page = parseInt(queryParams.page || '0', 10);
  const sort = queryParams.sort || 'recent';
  const minRating = queryParams.minRating ? parseInt(queryParams.minRating, 10) : undefined;
  const maxRating = queryParams.maxRating ? parseInt(queryParams.maxRating, 10) : undefined;

  const logs = await getLogs({
    page,
    size: 12,
    sort,
    minRating,
    maxRating,
  });

  // Build base URL with current filters for pagination
  const filterParams = new URLSearchParams();
  if (sort !== 'recent') filterParams.set('sort', sort);
  if (minRating) filterParams.set('minRating', String(minRating));
  if (maxRating) filterParams.set('maxRating', String(maxRating));
  const baseUrl = filterParams.toString()
    ? `/logs?${filterParams.toString()}`
    : '/logs';

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
      <LogFilters baseUrl="/logs" />

      {/* Results count */}
      {logs.totalElements !== null && logs.totalElements > 0 && (
        <p className="text-sm text-[var(--text-secondary)] mb-4">
          {t('found', { count: logs.totalElements.toLocaleString() })}
        </p>
      )}

      {/* Log grid */}
      <LogGrid logs={logs.content} />

      {/* Pagination */}
      {logs.totalPages !== null && logs.totalPages > 1 && (
        <Pagination
          currentPage={logs.currentPage || 0}
          totalPages={logs.totalPages}
          baseUrl={baseUrl}
        />
      )}
    </div>
  );
}
