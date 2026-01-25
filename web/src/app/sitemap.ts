import type { MetadataRoute } from 'next';
import { siteConfig } from '@/config/site';
import { routing } from '@/i18n/routing';
import { getAllRecipeIds } from '@/lib/api/recipes';
import { getAllLogIds } from '@/lib/api/logs';
import { getHashtags } from '@/lib/api/hashtags';
import { getAllUserIds } from '@/lib/api/users';

// Helper to generate alternates for all locales
function generateAlternates(path: string) {
  const baseUrl = siteConfig.url;
  const languages: Record<string, string> = {};

  routing.locales.forEach((locale) => {
    languages[locale] = `${baseUrl}/${locale}${path}`;
  });

  // x-default points to the default locale
  languages['x-default'] = `${baseUrl}/${routing.defaultLocale}${path}`;

  return { languages };
}

// Helper to create sitemap entry with locale URLs
function createLocalizedEntry(
  path: string,
  changeFrequency: 'always' | 'hourly' | 'daily' | 'weekly' | 'monthly' | 'yearly' | 'never',
  priority: number
): MetadataRoute.Sitemap {
  const baseUrl = siteConfig.url;
  const alternates = generateAlternates(path);

  return routing.locales.map((locale) => ({
    url: `${baseUrl}/${locale}${path}`,
    lastModified: new Date(),
    changeFrequency,
    priority,
    alternates,
  }));
}

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  // Static pages with locale support
  const staticPages: MetadataRoute.Sitemap = [
    ...createLocalizedEntry('', 'daily', 1),
    ...createLocalizedEntry('/recipes', 'daily', 0.9),
    ...createLocalizedEntry('/logs', 'daily', 0.8),
    ...createLocalizedEntry('/search', 'weekly', 0.7),
    ...createLocalizedEntry('/terms', 'monthly', 0.3),
    ...createLocalizedEntry('/privacy', 'monthly', 0.3),
  ];

  // Dynamic pages - wrap in try/catch to handle API failures
  let recipePages: MetadataRoute.Sitemap = [];
  let logPages: MetadataRoute.Sitemap = [];
  let hashtagPages: MetadataRoute.Sitemap = [];
  let userPages: MetadataRoute.Sitemap = [];

  try {
    const recipeIds = await getAllRecipeIds();
    recipePages = recipeIds.flatMap((id) =>
      createLocalizedEntry(`/recipes/${id}`, 'weekly', 0.8)
    );
  } catch {
    console.error('Failed to fetch recipe IDs for sitemap');
  }

  try {
    const logIds = await getAllLogIds();
    logPages = logIds.flatMap((id) =>
      createLocalizedEntry(`/logs/${id}`, 'weekly', 0.7)
    );
  } catch {
    console.error('Failed to fetch log IDs for sitemap');
  }

  try {
    const hashtags = await getHashtags();
    hashtagPages = hashtags.flatMap((tag) =>
      createLocalizedEntry(`/hashtags/${encodeURIComponent(tag.name)}`, 'weekly', 0.6)
    );
  } catch {
    console.error('Failed to fetch hashtags for sitemap');
  }

  try {
    const userIds = await getAllUserIds();
    userPages = userIds.flatMap((id) =>
      createLocalizedEntry(`/users/${id}`, 'weekly', 0.5)
    );
  } catch {
    console.error('Failed to fetch user IDs for sitemap');
  }

  return [...staticPages, ...recipePages, ...logPages, ...hashtagPages, ...userPages];
}
