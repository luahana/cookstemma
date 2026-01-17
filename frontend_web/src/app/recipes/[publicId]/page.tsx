import type { Metadata } from 'next';
import Image from 'next/image';
import Link from 'next/link';
import { notFound } from 'next/navigation';
import { getRecipeDetail } from '@/lib/api/recipes';
import { RecipeJsonLd } from '@/components/recipe/RecipeJsonLd';
import { BreadcrumbJsonLd } from '@/components/seo/BreadcrumbJsonLd';
import { RecipeGrid } from '@/components/recipe/RecipeGrid';
import { RecipeActions } from '@/components/recipe/RecipeActions';
import { RecentLogsGallery } from '@/components/recipe/RecentLogsGallery';
import { ShareButtons } from '@/components/common/ShareButtons';
import { ImageCarousel } from '@/components/common/ImageCarousel';
import { CookingStyleBadge } from '@/components/common/CookingStyleBadge';
import { COOKING_TIME_RANGES, type CookingTimeRange } from '@/lib/types';
import { getImageUrl } from '@/lib/utils/image';
import { siteConfig } from '@/config/site';
import { ViewTracker } from '@/components/common/ViewTracker';

interface Props {
  params: Promise<{ publicId: string }>;
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { publicId } = await params;

  try {
    const recipe = await getRecipeDetail(publicId);

    return {
      title: recipe.title,
      description: recipe.description.slice(0, 160),
      alternates: {
        canonical: `${siteConfig.url}/recipes/${publicId}`,
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
  const { publicId } = await params;

  let recipe;
  try {
    recipe = await getRecipeDetail(publicId);
  } catch {
    notFound();
  }

  const cookingTime =
    COOKING_TIME_RANGES[recipe.cookingTimeRange as CookingTimeRange] ||
    recipe.cookingTimeRange;

  // Group ingredients by type
  const ingredientsByType = recipe.ingredients.reduce(
    (acc, ing) => {
      const type = ing.type || 'MAIN';
      if (!acc[type]) acc[type] = [];
      acc[type].push(ing);
      return acc;
    },
    {} as Record<string, typeof recipe.ingredients>,
  );

  const ingredientTypeLabels: Record<string, string> = {
    MAIN: 'Main Ingredients',
    SUB: 'Additional Ingredients',
    SAUCE: 'Sauce & Seasoning',
    GARNISH: 'Garnish',
    OPTIONAL: 'Optional',
  };

  return (
    <>
      <ViewTracker publicId={publicId} type="recipe" />
      <RecipeJsonLd recipe={recipe} />
      <BreadcrumbJsonLd
        items={[
          { name: 'Home', href: '/' },
          { name: 'Recipes', href: '/recipes' },
          { name: recipe.title, href: `/recipes/${publicId}` },
        ]}
      />

      <article className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Breadcrumb */}
        <nav className="text-sm text-[var(--text-secondary)] mb-6">
          <Link href="/recipes" className="hover:text-[var(--primary)]">
            Recipes
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
            <RecipeActions
              recipePublicId={publicId}
              creatorPublicId={recipe.creatorPublicId}
              recipeTitle={recipe.title}
            />
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
                  {recipe.userName[0].toUpperCase()}
                </span>
                <span>{recipe.userName}</span>
              </Link>
            )}
            <CookingStyleBadge localeCode={recipe.culinaryLocale} size="md" />
            <span className="text-[var(--text-secondary)]">{cookingTime}</span>
            <span className="text-[var(--text-secondary)]">
              {recipe.servings} servings
            </span>
          </div>

          {/* Hashtags */}
          {recipe.hashtags.length > 0 && (
            <div className="flex flex-wrap gap-2 mt-4">
              {recipe.hashtags.map((tag) => (
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
              url={`/recipes/${publicId}`}
              title={recipe.title}
              description={recipe.description}
            />
          </div>
        </header>

        {/* Variant info */}
        {recipe.rootInfo && (
          <div className="bg-[var(--highlight-bg)] border border-[var(--primary-light)] rounded-xl p-4 mb-8">
            <p className="text-sm text-[var(--text-secondary)] mb-2">
              This is a variant of:
            </p>
            <Link
              href={`/recipes/${recipe.rootInfo.publicId}`}
              className="font-medium text-[var(--primary)] hover:underline"
            >
              {recipe.rootInfo.title}
            </Link>
            {recipe.changeReason && (
              <p className="text-sm text-[var(--text-secondary)] mt-2">
                Changes: {recipe.changeReason}
              </p>
            )}
          </div>
        )}

        {/* Ingredients */}
        <section className="mb-8">
          <h2 className="text-2xl font-bold text-[var(--text-primary)] mb-4">
            Ingredients
          </h2>
          <div className="bg-[var(--surface)] border border-[var(--border)] rounded-xl p-6">
            {Object.entries(ingredientsByType).map(([type, ingredients]) => (
              <div key={type} className="mb-4 last:mb-0">
                <h3 className="font-medium text-[var(--text-primary)] mb-2">
                  {ingredientTypeLabels[type] || type}
                </h3>
                <ul className="space-y-2">
                  {ingredients.map((ing, idx) => (
                    <li
                      key={idx}
                      className="flex items-center gap-2 text-[var(--text-secondary)]"
                    >
                      <span className="w-2 h-2 bg-[var(--primary)] rounded-full" />
                      <span>
                        {ing.amount && (
                          <span className="font-medium text-[var(--text-primary)]">
                            {ing.amount}{' '}
                          </span>
                        )}
                        {ing.name}
                      </span>
                    </li>
                  ))}
                </ul>
              </div>
            ))}
          </div>
        </section>

        {/* Steps */}
        <section className="mb-8">
          <h2 className="text-2xl font-bold text-[var(--text-primary)] mb-4">
            Instructions
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
                        alt={`Step ${step.stepNumber}`}
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

        {/* Variants */}
        {recipe.variants.length > 0 && (
          <section className="mb-8">
            <h2 className="text-2xl font-bold text-[var(--text-primary)] mb-4">
              Variations ({recipe.variants.length})
            </h2>
            <RecipeGrid recipes={recipe.variants} />
          </section>
        )}

        {/* Cooking logs gallery */}
        <RecentLogsGallery logs={recipe.logs} recipePublicId={publicId} />
      </article>
    </>
  );
}
