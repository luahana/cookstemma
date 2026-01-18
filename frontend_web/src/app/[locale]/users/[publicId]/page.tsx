import type { Metadata } from 'next';
import Link from 'next/link';
import { notFound } from 'next/navigation';
import { getUserProfile, getUserRecipes, getUserLogs } from '@/lib/api/users';
import { RecipeGrid } from '@/components/recipe/RecipeGrid';
import { LogGrid } from '@/components/log/LogGrid';
import { PersonJsonLd } from '@/components/seo/PersonJsonLd';
import { BreadcrumbJsonLd } from '@/components/seo/BreadcrumbJsonLd';
import { UserProfileHeader } from '@/components/user/UserProfileHeader';
import { getImageUrl } from '@/lib/utils/image';
import { siteConfig } from '@/config/site';

interface Props {
  params: Promise<{ publicId: string }>;
  searchParams: Promise<{ tab?: string }>;
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { publicId } = await params;

  try {
    const user = await getUserProfile(publicId);

    return {
      title: user.username,
      description: user.bio || `${user.username}'s recipes and cooking logs on Cookstemma`,
      alternates: {
        canonical: `${siteConfig.url}/users/${publicId}`,
      },
      openGraph: {
        title: user.username,
        description: user.bio || `${user.username}'s recipes and cooking logs on Cookstemma`,
        type: 'profile',
        ...(user.profileImageUrl && {
          images: [{ url: user.profileImageUrl }],
        }),
      },
    };
  } catch {
    return {
      title: 'User Not Found',
    };
  }
}

export default async function UserProfilePage({ params, searchParams }: Props) {
  const { publicId } = await params;
  const { tab = 'recipes' } = await searchParams;

  let user;
  try {
    user = await getUserProfile(publicId);
  } catch {
    notFound();
  }

  const [recipesData, logsData] = await Promise.all([
    getUserRecipes(publicId, { size: 6 }),
    getUserLogs(publicId, { size: 6 }),
  ]);

  const tabs = [
    { id: 'recipes', label: 'Recipes', count: user.recipeCount },
    { id: 'logs', label: 'Cooking Logs', count: user.logCount },
  ];

  return (
    <>
      <PersonJsonLd
        username={user.username}
        publicId={publicId}
        bio={user.bio}
        profileImageUrl={getImageUrl(user.profileImageUrl)}
        youtubeUrl={user.youtubeUrl}
        instagramHandle={user.instagramHandle}
      />
      <BreadcrumbJsonLd
        items={[
          { name: 'Home', href: '/' },
          { name: user.username, href: `/users/${publicId}` },
        ]}
      />

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Profile header */}
        <UserProfileHeader user={user} publicId={publicId} />

        {/* Tabs */}
        <div className="border-b border-[var(--border)] mb-6">
          <nav className="flex gap-8">
            {tabs.map((t) => (
              <Link
                key={t.id}
                href={`/users/${publicId}?tab=${t.id}`}
                className={`pb-4 px-1 border-b-2 font-medium transition-colors ${
                  tab === t.id
                    ? 'border-[var(--primary)] text-[var(--primary)]'
                    : 'border-transparent text-[var(--text-secondary)] hover:text-[var(--text-primary)]'
                }`}
              >
                {t.label} ({t.count})
              </Link>
            ))}
          </nav>
        </div>

        {/* Content */}
        {tab === 'recipes' ? (
          <RecipeGrid
            recipes={recipesData.content}
            emptyMessage={`${user.username} hasn't shared any recipes yet`}
          />
        ) : (
          <LogGrid
            logs={logsData.content}
            emptyMessage={`${user.username} hasn't shared any cooking logs yet`}
          />
        )}
      </div>
    </>
  );
}
