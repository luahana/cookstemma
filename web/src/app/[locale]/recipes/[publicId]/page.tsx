import type { Metadata } from 'next';
import Image from 'next/image';
import Link from 'next/link';
import { notFound } from 'next/navigation';
import { getTranslations } from 'next-intl/server';
import { getRecipeDetail } from '@/lib/api/recipes';
import { RecipeJsonLd } from '@/components/recipe/RecipeJsonLd';
import { BreadcrumbJsonLd } from '@/components/seo/BreadcrumbJsonLd';
import { VariantsGallery } from '@/components/recipe/VariantsGallery';
import { RecipeActions } from '@/components/recipe/RecipeActions';
import { ContentActions } from '@/components/shared/ContentActions';
import { RecentLogsGallery } from '@/components/recipe/RecentLogsGallery';
import { IngredientsSection } from '@/components/recipe/IngredientsSection';
import { ChangeDiffSection } from '@/components/recipe/ChangeDiffSection';
import { BookmarkButton } from '@/components/common/BookmarkButton';
import { ShareButtons } from '@/components/common/ShareButtons';
import { VariantButton } from '@/components/recipe/VariantButton';
import { ImageCarousel } from '@/components/common/ImageCarousel';
import { CookingStyleBadge } from '@/components/common/CookingStyleBadge';
import { COOKING_TIME_TRANSLATION_KEYS } from '@/lib/types';
import { getImageUrl } from '@/lib/utils/image';
import { getAvatarInitial } from '@/lib/utils/string';
import { siteConfig } from '@/config/site';
import { ViewTracker } from '@/components/common/ViewTracker';

interface Props {
  params: Promise<{ publicId: string; locale: string }>;
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { publicId, locale } = await params;

  try {
    const recipe = await getRecipeDetail(publicId);
    // title and description are pre-localized by the backend based on Accept-Language header

    return {
      title: recipe.title,
      description: recipe.description.slice(0, 160),
      alternates: {
        canonical: `${siteConfig.url}/${locale}/recipes/${publicId}`,
      },
      openGraph: {
        title: recipe.title,
        description: recipe.description,
        type: 'article',
        images: recipe.images.map((img) => ({
          url: img.imageUrl,
          width: 800,
          height: 600,
          alt: recipe.title,
        })),
      },
      twitter: {
        card: 'summary_large_image',
        title: recipe.title,
        description: recipe.description,
        images: recipe.images[0]?.imageUrl,
      },
    };
  } catch {
    return {
      title: 'Recipe Not Found',
    };
  }
}

export default async function RecipeDetailPage({ params }: Props) {
  const { publicId, locale } = await params;

  let recipe;
  try {
    recipe = await getRecipeDetail(publicId);
  } catch {
    notFound();
  }

  // All string fields (title, description, foodName) are pre-localized by the backend
  // based on the Accept-Language header
  const t = await getTranslations('recipes');
  const tNav = await getTranslations('nav');
  const tFilters = await getTranslations('filters');

  const cookingTimeKey = COOKING_TIME_TRANSLATION_KEYS[recipe.cookingTimeRange];
  const cookingTime = cookingTimeKey ? tFilters(cookingTimeKey) : recipe.cookingTimeRange;

  return (
    <>
      <ViewTracker
        publicId={publicId}
        type="recipe"
        title={recipe.title}
        thumbnail={recipe.images[0]?.imageUrl || null}
        foodName={recipe.foodName}
      />
      <RecipeJsonLd recipe={recipe} />
      <BreadcrumbJsonLd
        locale={locale}
        items={[
          { name: tNav('home') || 'Home', href: '/' },
          { name: tNav('recipes'), href: '/recipes' },
          { name: recipe.title, href: `/recipes/${publicId}` },
        ]}
      />

      <article className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Breadcrumb */}
        <nav className="text-sm text-[var(--text-secondary)] mb-6">
          <Link href="/recipes" className="hover:text-[var(--primary)]">
            {tNav('recipes')}
          </Link>
          <span className="mx-2">/</span>
          <span className="text-[var(--text-primary)]">{recipe.foodName}</span>
        </nav>

        {/* Hero image carousel */}
        {recipe.images.length > 0 && (
          <ImageCarousel images={recipe.images} alt={recipe.title} />
        )}

        {/* Header */}
        <header className="mb-8">
          <div className="flex items-start justify-between gap-4">
            <div className="flex-1">
              <p className="text-[var(--primary)] font-medium mb-2">
                {recipe.foodName}
              </p>
              <h1 className="text-3xl sm:text-4xl font-bold text-[var(--text-primary)] mb-4">
                {recipe.title}
              </h1>
            </div>
            <div className="flex items-center gap-2">
              <BookmarkButton
                publicId={publicId}
                type="recipe"
                initialSaved={recipe.isSavedByCurrentUser ?? false}
              />
              <RecipeActions
                recipePublicId={publicId}
                creatorPublicId={recipe.creatorPublicId}
                recipeTitle={recipe.title}
              />
              <ContentActions
                contentType="recipe"
                contentTitle={recipe.title}
                authorPublicId={recipe.creatorPublicId}
                authorName={recipe.userName}
              />
            </div>
          </div>
          <p className="text-[var(--text-secondary)] text-lg">
            {recipe.description}
          </p>

          {/* Meta */}
          <div className="flex flex-wrap items-center gap-4 mt-6">
            {recipe.userName && (
              <Link
                href={`/users/${recipe.creatorPublicId}`}
                className="flex items-center gap-2 text-[var(--text-secondary)] hover:text-[var(--primary)]"
              >
                <span className="w-8 h-8 bg-[var(--primary-light)] rounded-full flex items-center justify-center text-sm">
                  {getAvatarInitial(recipe.userName)}
                </span>
                <span>{recipe.userName}</span>
              </Link>
            )}
            <CookingStyleBadge localeCode={recipe.cookingStyle} size="md" />
            <span className="text-[var(--text-secondary)]">{cookingTime}</span>
            <span className="text-[var(--text-secondary)]">
              {t('servingsCount', { count: recipe.servings })}
            </span>
          </div>

          {/* Hashtags */}
          {recipe.hashtags.length > 0 && (
            <div className="flex flex-wrap gap-2 mt-4">
              {recipe.hashtags.map((tag) => (
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
              url={`/recipes/${publicId}`}
              title={recipe.title}
              description={recipe.description}
            />
          </div>
        </header>

        {/* Variant info - show for variant recipes (has rootInfo, parentInfo, or changeReason) */}
        {(recipe.rootInfo || recipe.parentInfo || recipe.changeReason || recipe.changeDiff) && (
          <div className="mb-8 space-y-4">
            {/* Change reason - prominent quote style */}
            {recipe.changeReason && (
              <div className="flex items-start justify-center gap-3 px-8 py-4">
                <span className="text-3xl font-bold text-[var(--primary)] leading-none">&ldquo;</span>
                <p className="text-center text-[var(--primary)] italic text-lg leading-relaxed">
                  {recipe.changeReason}
                </p>
                <span className="text-3xl font-bold text-[var(--primary)] leading-none">&rdquo;</span>
              </div>
            )}

            {/* Based on section - prefer rootInfo (original), fallback to parentInfo (direct parent) */}
            {(() => {
              const baseRecipe = recipe.rootInfo || recipe.parentInfo;
              if (!baseRecipe) return null;
              return (
                <div className="bg-[var(--highlight-bg)] border border-[var(--primary-light)] rounded-xl p-4">
                  <p className="text-sm text-[var(--text-secondary)] mb-2">
                    {t('variantOf')}
                  </p>
                  <Link
                    href={`/recipes/${baseRecipe.publicId}`}
                    className="font-medium text-[var(--primary)] hover:underline"
                  >
                    {baseRecipe.title}
                  </Link>
                </div>
              );
            })()}

            {/* Change diff section - collapsible */}
            <ChangeDiffSection changeDiff={recipe.changeDiff} />
          </div>
        )}

        {/* Ingredients */}
        <IngredientsSection ingredients={recipe.ingredients} locale={locale} />

        {/* Steps */}
        <section className="mb-8">
          <h2 className="text-2xl font-bold text-[var(--text-primary)] mb-4">
            {t('instructions')}
          </h2>
          <ol className="space-y-6">
            {recipe.steps.map((step) => (
              <li key={step.stepNumber} className="flex gap-4">
                <span className="flex-shrink-0 w-8 h-8 bg-[var(--primary)] text-white rounded-full flex items-center justify-center font-bold text-sm">
                  {step.stepNumber}
                </span>
                <div className="flex-1">
                  <p className="text-[var(--text-primary)]">{step.description}</p>
                  {getImageUrl(step.imageUrl) && (
                    <div className="relative aspect-video rounded-lg overflow-hidden mt-3 max-w-md">
                      <Image
                        src={getImageUrl(step.imageUrl)!}
                        alt={t('step', { number: step.stepNumber })}
                        fill
                        className="object-cover"
                        sizes="(max-width: 448px) 100vw, 448px"
                      />
                    </div>
                  )}
                </div>
              </li>
            ))}
          </ol>
        </section>

        {/* Cooking logs gallery */}
        <RecentLogsGallery logs={recipe.logs} recipePublicId={publicId} />

        {/* Create Variation CTA */}
        <section className="mb-8">
          <VariantButton recipePublicId={publicId} />
        </section>

        {/* Variants - only show for original recipes (not variants) */}
        {!recipe.rootInfo && !recipe.parentInfo && recipe.variants.length > 0 && (
          <VariantsGallery variants={recipe.variants} rootRecipePublicId={publicId} />
        )}
      </article>
    </>
  );
}
