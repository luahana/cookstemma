'use client';

import { useRouter, useSearchParams } from 'next/navigation';
import { useTranslations } from 'next-intl';

interface VisibilityFilterProps {
  profilePublicId: string;
  currentTab: string;
  currentVisibility: 'all' | 'public' | 'private';
}

export function VisibilityFilter({
  profilePublicId,
  currentTab,
  currentVisibility,
}: VisibilityFilterProps) {
  const router = useRouter();
  const searchParams = useSearchParams();
  const t = useTranslations('visibility');

  const handleVisibilityChange = (newVisibility: 'all' | 'public' | 'private') => {
    const params = new URLSearchParams(searchParams.toString());
    params.set('tab', currentTab);
    params.set('visibility', newVisibility);
    router.push(`/users/${profilePublicId}?${params.toString()}`);
  };

  const visibilityOptions = [
    { value: 'all' as const, label: t('all') },
    { value: 'public' as const, label: t('public') },
    { value: 'private' as const, label: t('private') },
  ];

  return (
    <div className="flex gap-2 mb-4">
      {visibilityOptions.map((option) => (
        <button
          key={option.value}
          onClick={() => handleVisibilityChange(option.value)}
          className={`px-3 py-1.5 text-sm font-medium rounded-lg transition-colors ${
            currentVisibility === option.value
              ? 'bg-[var(--primary)] text-white'
              : 'bg-[var(--surface)] text-[var(--text-secondary)] hover:bg-[var(--border)]'
          }`}
        >
          {option.label}
        </button>
      ))}
    </div>
  );
}
