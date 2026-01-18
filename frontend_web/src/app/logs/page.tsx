import type { Metadata } from 'next';
import { getLogs } from '@/lib/api/logs';
import { LogGrid } from '@/components/log/LogGrid';
import { LogFilters } from '@/components/common/LogFilters';
import { Pagination } from '@/components/common/Pagination';
import { siteConfig } from '@/config/site';

export const metadata: Metadata = {
  title: 'Cooking Logs',
  description: 'Browse cooking logs and experiences from our community of home cooks',
  alternates: {
    canonical: `${siteConfig.url}/logs`,
  },
};

interface Props {
  searchParams: Promise<{
    page?: string;
    sort?: 'recent' | 'popular' | 'trending';
    minRating?: string;
    maxRating?: string;
  }>;
}

export default async function LogsPage({ searchParams }: Props) {
  const params = await searchParams;
  const page = parseInt(params.page || '0', 10);
  const sort = params.sort || 'recent';
  const minRating = params.minRating ? parseInt(params.minRating, 10) : undefined;
  const maxRating = params.maxRating ? parseInt(params.maxRating, 10) : undefined;

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
          Cooking Logs
        </h1>
        <p className="text-[var(--text-secondary)] mt-2">
          See what others are cooking and their experiences
        </p>
      </div>

      {/* Filters */}
      <LogFilters baseUrl="/logs" />

      {/* Results count */}
      {logs.totalElements !== null && logs.totalElements > 0 && (
        <p className="text-sm text-[var(--text-secondary)] mb-4">
          {logs.totalElements.toLocaleString()} cooking logs
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
