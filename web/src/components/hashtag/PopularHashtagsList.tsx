import { Link } from '@/i18n/navigation';
import { getTranslations } from 'next-intl/server';
import { getPopularHashtags } from '@/lib/api/hashtags';

interface PopularHashtagsListProps {
  className?: string;
}

export async function PopularHashtagsList({
  className = '',
}: PopularHashtagsListProps) {
  const t = await getTranslations('hashtagsPage');
  let hashtags;
  try {
    hashtags = await getPopularHashtags(50);
  } catch {
    return (
      <div className="text-center py-12">
        <p className="text-[var(--text-secondary)]">{t('noHashtags')}</p>
      </div>
    );
  }

  if (hashtags.length === 0) {
    return (
      <div className="text-center py-12">
        <p className="text-[var(--text-secondary)]">{t('noHashtags')}</p>
      </div>
    );
  }

  return (
    <div className={className}>
      <div className="flex flex-wrap gap-3">
        {hashtags.map((hashtag) => (
          <Link
            key={hashtag.publicId}
            href={`/hashtags/${encodeURIComponent(hashtag.name)}`}
            className="inline-flex items-center gap-2 px-4 py-2 bg-[var(--surface)] border border-[var(--border)] rounded-full hover:border-[var(--hashtag)] hover:bg-[var(--highlight-bg)] transition-colors group"
          >
            <span className="text-hashtag font-medium">
              #{hashtag.name}
            </span>
            <span className="text-sm text-[var(--text-secondary)] bg-[var(--background)] px-2 py-0.5 rounded-full">
              {hashtag.totalCount}
            </span>
          </Link>
        ))}
      </div>
    </div>
  );
}
