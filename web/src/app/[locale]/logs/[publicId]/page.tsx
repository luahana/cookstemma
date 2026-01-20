import type { Metadata } from 'next';
import Image from 'next/image';
import Link from 'next/link';
import { notFound } from 'next/navigation';
import { getTranslations, getFormatter } from 'next-intl/server';
import { getLogDetail } from '@/lib/api/logs';
import { LogJsonLd } from '@/components/log/LogJsonLd';
import { BreadcrumbJsonLd } from '@/components/seo/BreadcrumbJsonLd';
import { LogDetailClient } from '@/components/log/LogDetailClient';
import { ContentActions } from '@/components/shared/ContentActions';
import { StarRating } from '@/components/log/StarRating';
import { RecipeCard } from '@/components/recipe/RecipeCard';
import { ShareButtons } from '@/components/common/ShareButtons';
import { BookmarkButton } from '@/components/common/BookmarkButton';
import { getImageUrl } from '@/lib/utils/image';
import { getAvatarInitial } from '@/lib/utils/string';
import { getLocalizedContent } from '@/lib/utils/localization';
import { siteConfig } from '@/config/site';
import { ViewTracker } from '@/components/common/ViewTracker';

interface Props {
  params: Promise<{ publicId: string; locale: string }>;
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { publicId, locale } = await params;

  try {
    const log = await getLogDetail(publicId);
    const title = getLocalizedContent(log.titleTranslations, locale, log.title);
    const content = getLocalizedContent(log.contentTranslations, locale, log.content);

    return {
      title,
      description: content.slice(0, 160),
      alternates: {
        canonical: `${siteConfig.url}/logs/${publicId}`,
      },
      openGraph: {
        title,
        description: content.slice(0, 160),
        type: 'article',
        images: log.images.map((img) => ({
          url: img.imageUrl,
          width: 800,
          height: 600,
          alt: title,
        })),
      },
      twitter: {
        card: 'summary_large_image',
        title,
        description: content.slice(0, 160),
        images: log.images[0]?.imageUrl,
      },
    };
  } catch {
    return {
      title: 'Cooking Log Not Found',
    };
  }
}

export default async function LogDetailPage({ params }: Props) {
  const { publicId, locale } = await params;

  let log;
  try {
    log = await getLogDetail(publicId);
  } catch {
    notFound();
  }

  const format = await getFormatter();
  const formattedDate = format.dateTime(new Date(log.createdAt), {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  });

  const localizedTitle = getLocalizedContent(log.titleTranslations, locale, log.title);
  const localizedContent = getLocalizedContent(log.contentTranslations, locale, log.content);

  const t = await getTranslations('logs');
  const tNav = await getTranslations('nav');

  return (
    <>
      <ViewTracker
        publicId={publicId}
        type="log"
        title={localizedTitle}
        titleTranslations={log.titleTranslations}
        thumbnail={log.images[0]?.imageUrl || null}
        foodName={log.linkedRecipe?.foodName || null}
        rating={log.rating}
      />
      <LogJsonLd log={log} />
      <BreadcrumbJsonLd
        items={[
          { name: 'Home', href: '/' },
          { name: 'Cooking Logs', href: '/logs' },
          { name: localizedTitle, href: `/logs/${publicId}` },
        ]}
      />

      <article className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Breadcrumb */}
        <nav className="text-sm text-[var(--text-secondary)] mb-6">
          <Link href="/logs" className="hover:text-[var(--primary)]">
            {tNav('cookingLogs')}
          </Link>
          <span className="mx-2">/</span>
          <span className="text-[var(--text-primary)]">{localizedTitle}</span>
        </nav>

        {/* Hero section */}
        <header className="mb-8">
          <div className="flex items-start justify-between gap-4">
            <div className="flex items-center gap-3 mb-4">
              <span className="text-[var(--text-secondary)]">{formattedDate}</span>
            </div>
            <div className="flex items-center gap-2">
              <BookmarkButton
                publicId={publicId}
                type="log"
                initialSaved={log.isSavedByCurrentUser ?? false}
              />
              <LogDetailClient log={log} />
              <ContentActions
                contentType="log"
                contentTitle={localizedTitle}
                authorPublicId={log.creatorPublicId}
                authorName={log.userName}
              />
            </div>
          </div>

          {/* Food name */}
          {log.linkedRecipe?.foodName && (
            <div className="mb-2">
              <span className="text-lg font-medium text-[var(--primary)]">{log.linkedRecipe.foodName}</span>
            </div>
          )}

          <h1 className="text-3xl sm:text-4xl font-bold text-[var(--text-primary)] mb-4">
            {localizedTitle}
          </h1>

          {/* Creator */}
          {log.userName && (
            <Link
              href={`/users/${log.creatorPublicId}`}
              className="inline-flex items-center gap-2 text-[var(--text-secondary)] hover:text-[var(--primary)]"
            >
              <span className="w-8 h-8 bg-[var(--primary-light)] rounded-full flex items-center justify-center text-sm">
                {getAvatarInitial(log.userName)}
              </span>
              <span>{log.userName}</span>
            </Link>
          )}

          {/* Hashtags */}
          {log.hashtags.length > 0 && (
            <div className="flex flex-wrap gap-2 mt-4">
              {log.hashtags.map((tag) => (
                <Link
                  key={tag.publicId}
                  href={`/hashtags/${encodeURIComponent(tag.name)}`}
                  className="text-sm hover:underline text-hashtag"
                >
                  #{tag.name}
                </Link>
              ))}
            </div>
          )}

          {/* Share Buttons */}
          <div className="mt-6 pt-4 border-t border-[var(--border)]">
            <ShareButtons
              url={`/logs/${publicId}`}
              title={localizedTitle}
              description={localizedContent.slice(0, 160)}
            />
          </div>
        </header>

        {/* Images */}
        {log.images.length > 0 && (
          <div className="mb-8">
            {log.images.length === 1 ? (
              <div className="relative aspect-video rounded-2xl overflow-hidden">
                <Image
                  src={getImageUrl(log.images[0].imageUrl)!}
                  alt={localizedTitle}
                  fill
                  className="object-cover"
                  priority
                  sizes="(max-width: 896px) 100vw, 896px"
                />
              </div>
            ) : (
              <div className="grid grid-cols-2 gap-4">
                {log.images.map((img, idx) => (
                  <div
                    key={img.imagePublicId}
                    className={`relative aspect-video rounded-xl overflow-hidden ${
                      idx === 0 && log.images.length === 3 ? 'col-span-2' : ''
                    }`}
                  >
                    <Image
                      src={getImageUrl(img.imageUrl)!}
                      alt={`${localizedTitle} - Image ${idx + 1}`}
                      fill
                      className="object-cover"
                      priority={idx === 0}
                      sizes="(max-width: 896px) 50vw, 448px"
                    />
                  </div>
                ))}
              </div>
            )}
          </div>
        )}

        {/* Star Rating */}
        {log.rating && (
          <div className="mb-8 flex items-center gap-3">
            <StarRating rating={log.rating} size="lg" />
            <span className="text-lg text-[var(--text-secondary)]">{log.rating}/5</span>
          </div>
        )}

        {/* Content */}
        <section className="mb-8">
          <div className="prose prose-lg max-w-none">
            <p className="text-[var(--text-primary)] whitespace-pre-wrap leading-relaxed">
              {localizedContent}
            </p>
          </div>
        </section>

        {/* Linked recipe */}
        {log.linkedRecipe && (
          <section className="mb-8">
            <h2 className="text-2xl font-bold text-[var(--text-primary)] mb-4">
              {t('recipeUsed')}
            </h2>
            <div className="max-w-sm">
              <RecipeCard recipe={log.linkedRecipe} />
            </div>
          </section>
        )}
      </article>
    </>
  );
}
