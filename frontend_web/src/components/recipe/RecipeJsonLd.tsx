import type { RecipeDetail } from '@/lib/types';
import { COOKING_TIME_RANGES, type CookingTimeRange } from '@/lib/types';

interface RecipeJsonLdProps {
  recipe: RecipeDetail;
}

/**
 * Convert cooking time range to ISO 8601 duration
 */
function cookingTimeToISO(range: string): string {
  const mapping: Record<string, string> = {
    MIN_0_TO_15: 'PT15M',
    MIN_15_TO_30: 'PT30M',
    MIN_30_TO_60: 'PT1H',
    MIN_60_TO_120: 'PT2H',
    MIN_120_PLUS: 'PT3H',
  };
  return mapping[range] || 'PT1H';
}

export function RecipeJsonLd({ recipe }: RecipeJsonLdProps) {
  const jsonLd = {
    '@context': 'https://schema.org',
    '@type': 'Recipe',
    name: recipe.title,
    description: recipe.description,
    image: recipe.images.map((img) => img.imageUrl),
    author: {
      '@type': 'Person',
      name: recipe.creatorName || 'Anonymous',
    },
    recipeIngredient: recipe.ingredients.map((ing) =>
      ing.amount ? `${ing.amount} ${ing.name}` : ing.name,
    ),
    recipeInstructions: recipe.steps.map((step) => ({
      '@type': 'HowToStep',
      position: step.stepNumber,
      text: step.description,
      ...(step.imageUrl && { image: step.imageUrl }),
    })),
    recipeYield: `${recipe.servings} servings`,
    cookTime: cookingTimeToISO(recipe.cookingTimeRange),
    recipeCategory: recipe.foodName,
    recipeCuisine: recipe.culinaryLocale,
    keywords: recipe.hashtags.map((h) => h.name).join(', '),
  };

  return (
    <script
      type="application/ld+json"
      dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
    />
  );
}
