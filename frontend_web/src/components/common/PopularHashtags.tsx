import Link from 'next/link';
import { getPopularHashtags } from '@/lib/api/hashtags';

interface PopularHashtagsProps {
  limit?: number;
  className?: string;
}

export async function PopularHashtags({
  limit = 8,
  className = '',
}: PopularHashtagsProps) {
  let hashtags;
  try {
    hashtags = await getPopularHashtags(limit);
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
          Popular Hashtags
        </h2>
      </div>

      <div className="flex flex-wrap gap-2">
        {hashtags.map((hashtag) => (
          <Link
            key={hashtag.publicId}
            href={`/hashtags/${encodeURIComponent(hashtag.name)}`}
            className="inline-flex items-center gap-1.5 px-3 py-1.5 bg-[var(--surface)] border border-[var(--border)] rounded-full hover:border-[var(--success)] hover:bg-[var(--highlight-bg)] transition-colors group"
          >
            <span className="text-[var(--success)] group-hover:text-[var(--success)]">
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
