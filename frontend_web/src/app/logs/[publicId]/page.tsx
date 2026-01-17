import type { Metadata } from 'next';
import Image from 'next/image';
import Link from 'next/link';
import { notFound } from 'next/navigation';
import { getLogDetail } from '@/lib/api/logs';
import { LogJsonLd } from '@/components/log/LogJsonLd';
import { BreadcrumbJsonLd } from '@/components/seo/BreadcrumbJsonLd';
import { LogDetailClient } from '@/components/log/LogDetailClient';
import { OutcomeBadge } from '@/components/log/OutcomeBadge';
import { RecipeCard } from '@/components/recipe/RecipeCard';
import { ShareButtons } from '@/components/common/ShareButtons';
import { getImageUrl } from '@/lib/utils/image';
import { siteConfig } from '@/config/site';
import { ViewTracker } from '@/components/common/ViewTracker';

interface Props {
  params: Promise<{ publicId: string }>;
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { publicId } = await params;

  try {
    const log = await getLogDetail(publicId);

    return {
      title: log.title,
      description: log.content.slice(0, 160),
      alternates: {
        canonical: `${siteConfig.url}/logs/${publicId}`,
      },
      openGraph: {
        title: log.title,
        description: log.content.slice(0, 160),
        type: 'article',
        images: log.images.map((img) => ({
          url: img.imageUrl,
          width: 800,
          height: 600,
          alt: log.title,
        })),
      },
      twitter: {
        card: 'summary_large_image',
        title: log.title,
        description: log.content.slice(0, 160),
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
  const { publicId } = await params;

  let log;
  try {
    log = await getLogDetail(publicId);
  } catch {
    notFound();
  }

  const formattedDate = new Date(log.createdAt).toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  });

  return (
    <>
      <ViewTracker publicId={publicId} type="log" />
      <LogJsonLd log={log} />
      <BreadcrumbJsonLd
        items={[
          { name: 'Home', href: '/' },
          { name: 'Cooking Logs', href: '/logs' },
          { name: log.title, href: `/logs/${publicId}` },
        ]}
      />

      <article className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Breadcrumb */}
        <nav className="text-sm text-[var(--text-secondary)] mb-6">
          <Link href="/logs" className="hover:text-[var(--primary)]">
            Cooking Logs
          </Link>
          <span className="mx-2">/</span>
          <span className="text-[var(--text-primary)]">{log.title}</span>
        </nav>

        {/* Hero section */}
        <header className="mb-8">
          <div className="flex items-start justify-between gap-4">
            <div className="flex items-center gap-3 mb-4">
              <OutcomeBadge outcome={log.outcome} size="lg" />
              <span className="text-[var(--text-secondary)]">{formattedDate}</span>
            </div>
            <LogDetailClient log={log} />
          </div>

          <h1 className="text-3xl sm:text-4xl font-bold text-[var(--text-primary)] mb-4">
            {log.title}
          </h1>

          {/* Creator */}
          {log.userName && (
            <Link
              href={`/users/${log.creatorPublicId}`}
              className="inline-flex items-center gap-2 text-[var(--text-secondary)] hover:text-[var(--primary)]"
            >
              <span className="w-8 h-8 bg-[var(--primary-light)] rounded-full flex items-center justify-center text-sm">
                {log.userName[0].toUpperCase()}
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
                  className="text-sm text-[var(--success)] hover:underline"
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
              title={log.title}
              description={log.content.slice(0, 160)}
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
                  alt={log.title}
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
                      alt={`${log.title} - Image ${idx + 1}`}
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

        {/* Content */}
        <section className="mb-8">
          <div className="prose prose-lg max-w-none">
            <p className="text-[var(--text-primary)] whitespace-pre-wrap leading-relaxed">
              {log.content}
            </p>
          </div>
        </section>

        {/* Linked recipe */}
        {log.linkedRecipe && (
          <section className="mb-8">
            <h2 className="text-2xl font-bold text-[var(--text-primary)] mb-4">
              Recipe Used
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
