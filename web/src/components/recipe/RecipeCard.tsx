'use client';

import Image from 'next/image';
import Link from 'next/link';
import { useTranslations } from 'next-intl';
import type { RecipeSummary } from '@/lib/types';
import { COOKING_TIME_TRANSLATION_KEYS } from '@/lib/types';
import { getImageUrl } from '@/lib/utils/image';
import { CookingStyleBadge } from '@/components/common/CookingStyleBadge';
import { BookmarkButton } from '@/components/common/BookmarkButton';

interface RecipeCardProps {
  recipe: RecipeSummary;
  isSaved?: boolean;
  showTypeLabel?: boolean;
}

export function RecipeCard({ recipe, isSaved = false, showTypeLabel = false }: RecipeCardProps) {
  const t = useTranslations('recipes');
  const tCommon = useTranslations('common');
  const tCard = useTranslations('card');
  const tFilters = useTranslations('filters');
  // title and description are pre-localized by the backend based on Accept-Language header
  const cookingTimeKey = COOKING_TIME_TRANSLATION_KEYS[recipe.cookingTimeRange];
  const cookingTime = cookingTimeKey ? tFilters(cookingTimeKey) : recipe.cookingTimeRange;

  return (
    <Link
      href={`/recipes/${recipe.publicId}`}
      className="block bg-[var(--surface)] rounded-2xl shadow-sm border border-[var(--border)] overflow-hidden hover:shadow-md hover:border-[var(--primary-light)] transition-all group"
    >
      {/* Thumbnail */}
      <div className="relative aspect-[4/3] bg-[var(--background)]">
        {getImageUrl(recipe.thumbnail) ? (
          <Image
            src={getImageUrl(recipe.thumbnail)!}
            alt={recipe.title}
            fill
            className="object-cover group-hover:scale-105 transition-transform duration-300"
            sizes="(max-width: 640px) 100vw, (max-width: 1024px) 50vw, 33vw"
          />
        ) : (
          <div className="w-full h-full flex items-center justify-center text-4xl">
            🍳
          </div>
        )}

        {/* Variant badge */}
        {recipe.rootPublicId && (
          <span className="absolute top-3 left-3 px-2 py-1 bg-[var(--primary)] text-white text-xs font-medium rounded-full">
            {tCard('variant')}
          </span>
        )}

        {/* Bookmark button */}
        <div className="absolute top-3 right-3">
          <BookmarkButton
            publicId={recipe.publicId}
            type="recipe"
            initialSaved={isSaved}
            size="sm"
          />
        </div>
      </div>

      {/* Content */}
      <div className="p-4">
        {/* Type label for search results */}
        {showTypeLabel && (
          <span className="inline-flex items-center gap-1 text-xs px-2 py-0.5 bg-[var(--primary)]/10 text-[var(--primary)] rounded-full mb-2">
            <svg className="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
            </svg>
            {tCard('recipe')}
          </span>
        )}

        {/* Food name */}
        <p className="text-sm font-medium text-[var(--primary)]">
          {recipe.foodName}
        </p>

        {/* Title */}
        <h3 className="font-semibold text-[var(--text-primary)] mt-1 line-clamp-1 group-hover:text-[var(--primary)] transition-colors">
          {recipe.title}
        </h3>

        {/* Description */}
        <p className="text-sm text-[var(--text-secondary)] mt-1 line-clamp-2">
          {recipe.description}
        </p>

        {/* Meta info */}
        <div className="flex items-center justify-between mt-3 text-sm">
          {recipe.userName && (
            <span className="text-[var(--text-secondary)]">
              {tCommon('by')} {recipe.userName}
            </span>
          )}
          <div className="flex items-center gap-3 text-xs text-[var(--text-secondary)]">
            {recipe.variantCount > 0 && (
              <span className="flex items-center gap-1">
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" />
                </svg>
                {recipe.variantCount}
              </span>
            )}
            {recipe.logCount > 0 && (
              <span className="flex items-center gap-1">
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                </svg>
                {recipe.logCount}
              </span>
            )}
          </div>
        </div>

        {/* Tags row */}
        <div className="flex items-center gap-2 mt-3 flex-wrap">
          <CookingStyleBadge localeCode={recipe.cookingStyle} size="sm" />
          <span className="text-xs px-2 py-1 bg-[var(--background)] text-[var(--text-secondary)] rounded">
            {cookingTime}
          </span>
          <span className="text-xs px-2 py-1 bg-[var(--background)] text-[var(--text-secondary)] rounded">
            {t('servingsCount', { count: recipe.servings })}
          </span>
        </div>

        {/* Hashtags */}
        {recipe.hashtags.length > 0 && (
          <div className="flex flex-wrap gap-1 mt-2">
            {recipe.hashtags.slice(0, 3).map((tag) => (
              <span
                key={tag}
                className="text-xs hover:underline text-hashtag"
              >
                #{tag}
              </span>
            ))}
          </div>
        )}
      </div>
    </Link>
  );
}
