'use client';

import { useRouter } from 'next/navigation';
import { useNavigationProgress } from '@/contexts/NavigationProgressContext';
import { SearchHistory } from './SearchHistory';
import { RecentlyViewedCompact } from './RecentlyViewedCompact';

export function SearchEmptyState() {
  const router = useRouter();
  const { startLoading } = useNavigationProgress();

  const handleHistorySelect = (query: string) => {
    startLoading();
    router.push(`/search?q=${encodeURIComponent(query)}`);
  };

  return (
    <div>
      {/* Search History */}
      <SearchHistory onSelect={handleHistorySelect} />

      {/* Recently Viewed */}
      <RecentlyViewedCompact />
    </div>
  );
}
