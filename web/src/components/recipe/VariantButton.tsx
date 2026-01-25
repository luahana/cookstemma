'use client';

import { useRouter } from 'next/navigation';
import { useTransition, useEffect } from 'react';
import { useTranslations } from 'next-intl';
import { useAuth } from '@/contexts/AuthContext';
import { useNavigationProgress } from '@/contexts/NavigationProgressContext';

interface VariantButtonProps {
  recipePublicId: string;
}

/**
 * CTA card to create a variant (fork) of an existing recipe.
 * Redirects to login if not authenticated, otherwise navigates to create page with parent param.
 */
export function VariantButton({ recipePublicId }: VariantButtonProps) {
  const { isAuthenticated } = useAuth();
  const router = useRouter();
  const t = useTranslations('variant');
  const [isPending, startTransition] = useTransition();
  const { startLoading, stopLoading } = useNavigationProgress();

  // Stop loading when transition completes
  useEffect(() => {
    if (!isPending) {
      stopLoading();
    }
  }, [isPending, stopLoading]);

  const handleClick = () => {
    const createUrl = `/recipes/create?parent=${recipePublicId}`;
    startLoading();
    startTransition(() => {
      if (!isAuthenticated) {
        router.push(`/login?redirect=${encodeURIComponent(createUrl)}`);
      } else {
        router.push(createUrl);
      }
    });
  };

  return (
    <button
      onClick={handleClick}
      className="w-full flex items-center justify-between gap-4 px-5 py-4 bg-[var(--surface)] border border-[var(--border)] border-l-4 border-l-[var(--secondary)] rounded-xl hover:bg-[var(--background)] transition-colors text-left cursor-pointer"
      title={t('createVariation')}
      aria-label={t('createVariation')}
    >
      <div>
        <p className="font-semibold text-[var(--text-primary)]">{t('madeItYourWay')}</p>
        <p className="text-sm text-[var(--text-secondary)]">{t('shareYourTwist')}</p>
      </div>
      <div className="flex items-center gap-2 px-4 py-2 bg-[var(--primary)] dark:bg-[var(--secondary)] text-white [&>*]:text-white font-medium text-sm rounded-lg shrink-0">
        <svg
          className="w-4 h-4"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth={2}
            d="M8 7v8a2 2 0 002 2h6M8 7V5a2 2 0 012-2h4.586a1 1 0 01.707.293l4.414 4.414a1 1 0 01.293.707V15a2 2 0 01-2 2h-2M8 7H6a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2v-2"
          />
        </svg>
        <span className="hidden sm:inline text-white">{t('createVariation')}</span>
        <span className="sm:hidden text-white">{t('vary')}</span>
      </div>
    </button>
  );
}
