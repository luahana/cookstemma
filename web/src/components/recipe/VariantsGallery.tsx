'use client';

import Image from 'next/image';
import Link from 'next/link';
import { useLocale } from 'next-intl';
import type { RecipeSummary } from '@/lib/types';
import { getImageUrl } from '@/lib/utils/image';
import { getLocalizedContent } from '@/lib/utils/localization';
import { useDragScroll } from '@/hooks/useDragScroll';

interface VariantsGalleryProps {
  variants: RecipeSummary[];
  rootRecipePublicId: string;
}

export function VariantsGallery({ variants, rootRecipePublicId }: VariantsGalleryProps) {
  const locale = useLocale();
  const scrollRef = useDragScroll<HTMLDivElement>();
  const displayVariants = variants.slice(0, 8);
  const hasMore = variants.length > 8;

  if (variants.length === 0) {
    return null;
  }

  return (
    <section className="mb-8">
      {/* Header */}
      <div className="flex items-center justify-between mb-4">
        <h2 className="text-2xl font-bold text-[var(--text-primary)]">
          Variations ({variants.length})
        </h2>
        {hasMore && (
          <Link
            href={`/search?type=recipes&root=${rootRecipePublicId}`}
            className="text-sm text-[var(--primary)] hover:underline flex items-center gap-1"
          >
            View All
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
                d="M9 5l7 7-7 7"
              />
            </svg>
          </Link>
        )}
      </div>

      {/* Horizontal Scrolling Gallery */}
      <div className="relative -mx-4 px-4 sm:-mx-6 sm:px-6 lg:-mx-8 lg:px-8">
        <div
          ref={scrollRef}
          className="flex gap-4 pb-4 scrollbar-hide"
          style={{ overflowX: 'auto' }}
        >
          {displayVariants.map((variant) => {
            const thumbUrl = getImageUrl(variant.thumbnail);

            return (
              <Link
                key={variant.publicId}
                href={`/recipes/${variant.publicId}`}
                className="flex-shrink-0 group"
              >
                {/* Card */}
                <div className="relative w-36 h-36 rounded-xl overflow-hidden bg-[var(--surface)] border border-[var(--border)] group-hover:border-[var(--primary-light)] transition-colors">
                  {thumbUrl ? (
                    <Image
                      src={thumbUrl}
                      alt={variant.title}
                      fill
                      className="object-cover group-hover:scale-105 transition-transform duration-300"
                      sizes="144px"
                    />
                  ) : (
                    <div className="w-full h-full flex items-center justify-center bg-[var(--surface)]">
                      <span className="text-4xl">🍳</span>
                    </div>
                  )}

                  {/* Variant Badge */}
                  <div className="absolute top-2 left-2 px-2 py-0.5 bg-[var(--primary)] text-white text-[10px] font-medium rounded-full">
                    Variant
                  </div>
                </div>

                {/* Title & Author */}
                <div className="mt-2 w-36">
                  <p className="text-sm font-medium text-[var(--text-primary)] truncate group-hover:text-[var(--primary)] transition-colors">
                    {getLocalizedContent(variant.titleTranslations, locale, variant.title)}
                  </p>
                  {variant.userName && (
                    <p className="text-xs text-[var(--text-secondary)] truncate">
                      by {variant.userName}
                    </p>
                  )}
                </div>
              </Link>
            );
          })}

          {/* "View More" Card */}
          {hasMore && (
            <Link
              href={`/search?type=recipes&root=${rootRecipePublicId}`}
              className="flex-shrink-0"
            >
              <div className="w-36 h-36 rounded-xl border-2 border-dashed border-[var(--border)] hover:border-[var(--primary)] flex flex-col items-center justify-center gap-2 transition-colors">
                <span className="text-2xl font-bold text-[var(--text-secondary)]">
                  +{variants.length - 8}
                </span>
                <span className="text-xs text-[var(--text-secondary)]">
                  more variations
                </span>
              </div>
            </Link>
          )}
        </div>
      </div>
    </section>
  );
}
