import { Link } from '@/i18n/navigation';
import { getTranslations } from 'next-intl/server';
import { getPopularHashtags } from '@/lib/api/hashtags';

interface PopularHashtagsProps {
  locale: string;
  limit?: number;
  className?: string;
}

export async function PopularHashtags({
  locale,
  limit = 8,
  className = '',
}: PopularHashtagsProps) {
  const t = await getTranslations('popularHashtags');
  let hashtags;
  try {
    hashtags = await getPopularHashtags(limit, locale);
  } catch {
    return null;
  }

  if (hashtags.length === 0) {
    return null;
  }

  return (
    <section className={className}>
      <div className="flex items-center justify-between mb-4">
        <h2 className="text-xl font-bold text-[var(--text-primary)]">
          {t('title')}
        </h2>
      </div>

      <div className="flex flex-wrap gap-2">
        {hashtags.map((hashtag) => (
          <Link
            key={hashtag.publicId}
            href={`/hashtags/${encodeURIComponent(hashtag.name)}`}
            className="inline-flex items-center gap-1.5 px-3 py-1.5 bg-[var(--surface)] border border-[var(--border)] rounded-full hover:border-[var(--hashtag)] hover:bg-[var(--highlight-bg)] transition-colors group"
          >
            <span className="text-hashtag">
              #{hashtag.name}
            </span>
            <span className="text-xs text-[var(--text-secondary)]">
              ({hashtag.totalCount})
            </span>
          </Link>
        ))}
      </div>
    </section>
  );
}
