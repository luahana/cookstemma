import type { LogPostDetail } from '@/lib/types';

interface LogJsonLdProps {
  log: LogPostDetail;
}

export function LogJsonLd({ log }: LogJsonLdProps) {
  const jsonLd = {
    '@context': 'https://schema.org',
    '@type': 'Article',
    headline: log.title,
    description: log.content.slice(0, 160),
    image: log.images.map((img) => img.imageUrl),
    datePublished: log.createdAt,
    author: {
      '@type': 'Person',
      name: log.userName || 'Anonymous',
    },
    keywords: log.hashtags.map((h) => h.name).join(', '),
    ...(log.linkedRecipe && {
      about: {
        '@type': 'Recipe',
        name: log.linkedRecipe.title,
        url: `/recipes/${log.linkedRecipe.publicId}`,
      },
    }),
  };

  return (
    <script
      type="application/ld+json"
      dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
    />
  );
}
