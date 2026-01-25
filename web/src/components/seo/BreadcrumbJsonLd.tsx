import { siteConfig } from '@/config/site';

interface BreadcrumbItem {
  name: string;
  href: string;
}

interface BreadcrumbJsonLdProps {
  items: BreadcrumbItem[];
  /** Locale prefix for URLs (e.g., "en", "ko") */
  locale?: string;
}

export function BreadcrumbJsonLd({ items, locale }: BreadcrumbJsonLdProps) {
  const breadcrumbSchema = {
    '@context': 'https://schema.org',
    '@type': 'BreadcrumbList',
    itemListElement: items.map((item, index) => {
      // Build full URL with optional locale prefix
      const path = locale && !item.href.startsWith(`/${locale}`)
        ? `/${locale}${item.href}`
        : item.href;
      return {
        '@type': 'ListItem',
        position: index + 1,
        name: item.name,
        item: `${siteConfig.url}${path}`,
      };
    }),
  };

  return (
    <script
      type="application/ld+json"
      dangerouslySetInnerHTML={{ __html: JSON.stringify(breadcrumbSchema) }}
    />
  );
}
