'use client';

import Image from 'next/image';
import { useTranslations } from 'next-intl';
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
  const t = useTranslations('cookingStyles');
  const tCommon = useTranslations('common');

  if (!localeCode) return null;

  const { flagUrl, name } = getCookingStyleDisplay(localeCode, t);

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
      className={`relative group/badge inline-flex items-center gap-1.5 bg-[var(--background)] text-[var(--text-secondary)] rounded border border-[var(--border)] ${sizeClasses[size]}`}
    >
      <Image
        src={flagUrl}
        alt={name}
        width={flagSizes[size].width}
        height={flagSizes[size].height}
        className="rounded-sm"
        unoptimized
      />
      {showLabel && <span className="font-medium">{tCommon('style')}</span>}

      {/* Styled Tooltip */}
      <span className="absolute bottom-full left-1/2 -translate-x-1/2 mb-2 px-2 py-1 bg-[var(--text-primary)] text-[var(--background)] text-xs rounded whitespace-nowrap opacity-0 invisible group-hover/badge:opacity-100 group-hover/badge:visible transition-opacity duration-200 pointer-events-none z-10">
        {name}
      </span>
    </span>
  );
}
