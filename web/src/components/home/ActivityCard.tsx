'use client';

import Image from 'next/image';
import Link from 'next/link';
import { useTranslations } from 'next-intl';
import { StarRating } from '@/components/log/StarRating';
import { BookmarkButton } from '@/components/common/BookmarkButton';
import { getImageUrl } from '@/lib/utils/image';

interface Activity {
  logPublicId: string;
  foodName: string;
  recipeTitle: string;
  userName?: string;
  thumbnailUrl?: string;
  rating?: number;
}

interface ActivityCardProps {
  activity: Activity;
}

export function ActivityCard({ activity }: ActivityCardProps) {
  const tCommon = useTranslations('common');

  return (
    <Link
      href={`/logs/${activity.logPublicId}`}
      className="bg-[var(--background)] rounded-xl p-4 hover:shadow-md transition-shadow border border-[var(--border)]"
    >
      <div className="flex gap-4">
        {getImageUrl(activity.thumbnailUrl) && (
          <div className="relative w-20 h-20 rounded-lg overflow-hidden flex-shrink-0">
            <Image
              src={getImageUrl(activity.thumbnailUrl)!}
              alt={activity.recipeTitle}
              fill
              className="object-cover"
              sizes="80px"
            />
          </div>
        )}
        <div className="flex-1 min-w-0">
          <div className="mb-1">
            <div className="flex items-center justify-between">
              <span className="text-sm font-medium text-[var(--primary)]">
                {activity.foodName}
              </span>
              <BookmarkButton
                publicId={activity.logPublicId}
                type="log"
                size="sm"
                variant="inline"
              />
            </div>
            {activity.rating && (
              <div className="mt-1">
                <StarRating rating={activity.rating} size="sm" />
              </div>
            )}
          </div>
          <p className="font-medium text-[var(--text-primary)] truncate">
            {activity.recipeTitle}
          </p>
          <div className="flex items-center gap-1.5 text-sm">
            <div className="w-5 h-5 rounded-full bg-[var(--primary-light)] flex items-center justify-center flex-shrink-0">
              <span className="text-[var(--primary)] text-xs font-medium">
                {(activity.userName || tCommon('anonymous')).charAt(0).toUpperCase()}
              </span>
            </div>
            <span className="text-[var(--text-secondary)]">
              {activity.userName || tCommon('anonymous')}
            </span>
          </div>
        </div>
      </div>
    </Link>
  );
}
