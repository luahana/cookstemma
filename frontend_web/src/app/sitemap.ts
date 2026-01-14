import type { MetadataRoute } from 'next';
import { siteConfig } from '@/config/site';
import { getAllRecipeIds } from '@/lib/api/recipes';
import { getAllLogIds } from '@/lib/api/logs';
import { getHashtags } from '@/lib/api/hashtags';

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const baseUrl = siteConfig.url;

  // Static pages
  const staticPages: MetadataRoute.Sitemap = [
    {
      url: baseUrl,
      lastModified: new Date(),
      changeFrequency: 'daily',
      priority: 1,
    },
    {
      url: `${baseUrl}/recipes`,
      lastModified: new Date(),
      changeFrequency: 'daily',
      priority: 0.9,
    },
    {
      url: `${baseUrl}/logs`,
      lastModified: new Date(),
      changeFrequency: 'daily',
      priority: 0.8,
    },
    {
      url: `${baseUrl}/search`,
      lastModified: new Date(),
      changeFrequency: 'weekly',
      priority: 0.7,
    },
    {
      url: `${baseUrl}/terms`,
      lastModified: new Date(),
      changeFrequency: 'monthly',
      priority: 0.3,
    },
    {
      url: `${baseUrl}/privacy`,
      lastModified: new Date(),
      changeFrequency: 'monthly',
      priority: 0.3,
    },
  ];

  // Dynamic pages - wrap in try/catch to handle API failures
  let recipePages: MetadataRoute.Sitemap = [];
  let logPages: MetadataRoute.Sitemap = [];
  let hashtagPages: MetadataRoute.Sitemap = [];

  try {
    const recipeIds = await getAllRecipeIds();
    recipePages = recipeIds.map((id) => ({
      url: `${baseUrl}/recipes/${id}`,
      lastModified: new Date(),
      changeFrequency: 'weekly' as const,
      priority: 0.8,
    }));
  } catch {
    console.error('Failed to fetch recipe IDs for sitemap');
  }

  try {
    const logIds = await getAllLogIds();
    logPages = logIds.map((id) => ({
      url: `${baseUrl}/logs/${id}`,
      lastModified: new Date(),
      changeFrequency: 'weekly' as const,
      priority: 0.7,
    }));
  } catch {
    console.error('Failed to fetch log IDs for sitemap');
  }

  try {
    const hashtags = await getHashtags();
    hashtagPages = hashtags.map((tag) => ({
      url: `${baseUrl}/hashtags/${encodeURIComponent(tag.name)}`,
      lastModified: new Date(),
      changeFrequency: 'weekly' as const,
      priority: 0.6,
    }));
  } catch {
    console.error('Failed to fetch hashtags for sitemap');
  }

  return [...staticPages, ...recipePages, ...logPages, ...hashtagPages];
}
