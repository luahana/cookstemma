'use client';

import Image from 'next/image';
import { getCookingStyleDisplay } from '@/lib/utils/cookingStyle';

interface CookingStyleBadgeProps {
  localeCode: string | null | undefined;
  size?: 'sm' | 'md' | 'lg';
  showLabel?: boolean;
}

export function CookingStyleBadge({
  localeCode,
  size = 'sm',
  showLabel = true,
}: CookingStyleBadgeProps) {
  if (!localeCode) return null;

  const { flagUrl, name } = getCookingStyleDisplay(localeCode);

  const sizeClasses = {
    sm: 'text-xs px-2 py-0.5',
    md: 'text-sm px-2.5 py-1',
    lg: 'text-base px-3 py-1.5',
  };

  const flagSizes = {
    sm: { width: 16, height: 12 },
    md: { width: 20, height: 15 },
    lg: { width: 24, height: 18 },
  };

  return (
    <span
      className={`inline-flex items-center gap-1.5 bg-[var(--background)] text-[var(--text-secondary)] rounded border border-[var(--border)] ${sizeClasses[size]}`}
      title={`${name} Style`}
    >
      <Image
        src={flagUrl}
        alt={name}
        width={flagSizes[size].width}
        height={flagSizes[size].height}
        className="rounded-sm"
        unoptimized
      />
      {showLabel && <span className="font-medium">Style</span>}
    </span>
  );
}
