'use client';

import Image from 'next/image';
import { Link } from '@/i18n/navigation';
import { useTranslations } from 'next-intl';
import type { HashtaggedContentItem } from '@/lib/types';
import { getImageUrl } from '@/lib/utils/image';
import { StarRating } from '@/components/log/StarRating';

interface HashtaggedFeedProps {
  items: HashtaggedContentItem[];
  emptyMessage?: string;
}

export function HashtaggedFeed({
  items,
  emptyMessage,
}: HashtaggedFeedProps) {
  const t = useTranslations('hashtagsPage');

  if (items.length === 0) {
    return (
      <div className="text-center py-12">
        <p className="text-[var(--text-secondary)]">{emptyMessage ?? t('noContent')}</p>
      </div>
    );
  }

  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
      {items.map((item) => (
        <HashtaggedContentCard key={`${item.type}-${item.publicId}`} item={item} />
      ))}
    </div>
  );
}

interface HashtaggedContentCardProps {
  item: HashtaggedContentItem;
}

function HashtaggedContentCard({ item }: HashtaggedContentCardProps) {
  const t = useTranslations('card');
  const isRecipe = item.type === 'recipe';
  const href = isRecipe ? `/recipes/${item.publicId}` : `/logs/${item.publicId}`;

  return (
    <Link
      href={href}
      className="block bg-[var(--surface)] rounded-2xl shadow-sm border border-[var(--border)] overflow-hidden hover:shadow-md hover:border-[var(--primary-light)] transition-all group"
    >
      {/* Thumbnail */}
      <div className="relative aspect-[4/3] bg-[var(--background)]">
        {getImageUrl(item.thumbnailUrl) ? (
          <Image
            src={getImageUrl(item.thumbnailUrl)!}
            alt={item.title}
            fill
            className="object-cover group-hover:scale-105 transition-transform duration-300"
            sizes="(max-width: 640px) 100vw, (max-width: 1024px) 50vw, 33vw"
            unoptimized
          />
        ) : (
          <div className="w-full h-full flex items-center justify-center text-4xl">
            {isRecipe ? '🍳' : (
              <svg
                className="w-12 h-12 text-[var(--text-secondary)] opacity-50"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
                />
              </svg>
            )}
          </div>
        )}

        {/* Type badge */}
        <span className={`absolute top-3 left-3 px-2 py-1 text-white text-xs font-medium rounded-full ${
          isRecipe ? 'bg-[var(--primary)]' : 'bg-[var(--secondary)]'
        }`}>
          {isRecipe ? t('recipe') : t('cookingLog')}
        </span>

        {/* Private indicator */}
        {item.isPrivate && (
          <span className="absolute top-3 right-3 p-1.5 bg-black/60 rounded-full" title={t('private')}>
            <svg className="w-4 h-4 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
            </svg>
          </span>
        )}
      </div>

      {/* Content */}
      <div className="p-4">
        {/* Food name (for recipes) */}
        {item.foodName && (
          <p className="text-sm font-medium text-[var(--primary)]">
            {item.foodName}
          </p>
        )}

        {/* Star rating (for logs) */}
        {item.rating && (
          <div className="mt-1">
            <StarRating rating={item.rating} size="sm" />
          </div>
        )}

        {/* Title */}
        <h3 className="font-semibold text-[var(--text-primary)] mt-1 line-clamp-1 group-hover:text-[var(--primary)] transition-colors">
          {item.title}
        </h3>

        {/* Recipe title for logs */}
        {item.recipeTitle && (
          <p className="text-sm text-[var(--text-secondary)] mt-1 line-clamp-1">
            {item.recipeTitle}
          </p>
        )}

        {/* Creator */}
        {item.userName && (
          <div className="flex items-center gap-1.5 mt-2">
            <div className="w-5 h-5 rounded-full bg-[var(--primary-light)] flex items-center justify-center flex-shrink-0">
              <span className="text-[var(--primary)] text-xs font-medium">
                {item.userName.charAt(0).toUpperCase()}
              </span>
            </div>
            <span className="text-sm text-[var(--text-secondary)]">{item.userName}</span>
          </div>
        )}

        {/* Hashtags */}
        {item.hashtags.length > 0 && (
          <div className="flex flex-wrap gap-1 mt-2">
            {item.hashtags.slice(0, 3).map((tag) => (
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
