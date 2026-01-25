import { siteConfig } from '@/config/site';

interface PersonJsonLdProps {
  username: string;
  publicId: string;
  bio?: string | null;
  profileImageUrl?: string | null;
  youtubeUrl?: string | null;
  instagramHandle?: string | null;
}

export function PersonJsonLd({
  username,
  publicId,
  bio,
  profileImageUrl,
  youtubeUrl,
  instagramHandle,
}: PersonJsonLdProps) {
  const sameAs: string[] = [];

  if (youtubeUrl) {
    sameAs.push(youtubeUrl);
  }

  if (instagramHandle) {
    sameAs.push(`https://instagram.com/${instagramHandle}`);
  }

  const personSchema = {
    '@context': 'https://schema.org',
    '@type': 'Person',
    name: username,
    url: `${siteConfig.url}/users/${publicId}`,
    ...(bio && { description: bio }),
    ...(profileImageUrl && { image: profileImageUrl }),
    ...(sameAs.length > 0 && { sameAs }),
  };

  return (
    <script
      type="application/ld+json"
      dangerouslySetInnerHTML={{ __html: JSON.stringify(personSchema) }}
    />
  );
}
