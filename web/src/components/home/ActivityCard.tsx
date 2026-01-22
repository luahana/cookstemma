'use client';

import Image from 'next/image';
import { Link } from '@/i18n/navigation';
import { useTranslations } from 'next-intl';
import { StarRating } from '@/components/log/StarRating';
import { BookmarkButton } from '@/components/common/BookmarkButton';
import { getImageUrl } from '@/lib/utils/image';

interface Activity {
  logPublicId: string;
  foodName: string;
  recipeTitle: string;
  userName?: string | null;
  thumbnailUrl?: string | null;
  rating?: number | null;
  commentCount?: number;
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
            <div className="flex items-center gap-2 mt-1">
              {activity.rating && (
                <StarRating rating={activity.rating} size="sm" />
              )}
              {activity.commentCount !== undefined && activity.commentCount > 0 && (
                <span className="flex items-center gap-0.5 text-xs text-[var(--text-secondary)]">
                  <svg className="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                    <path strokeLinecap="round" strokeLinejoin="round" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
                  </svg>
                  {activity.commentCount}
                </span>
              )}
            </div>
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
