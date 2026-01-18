import type { RecipeSummary } from '@/lib/types';
import { RecipeCard } from './RecipeCard';

interface RecipeGridProps {
  recipes: RecipeSummary[];
  emptyMessage?: string;
  locale?: string;
}

export function RecipeGrid({
  recipes,
  emptyMessage = 'No recipes found',
  locale = 'ko',
}: RecipeGridProps) {
  if (recipes.length === 0) {
    return (
      <div className="text-center py-12">
        <p className="text-[var(--text-secondary)]">{emptyMessage}</p>
      </div>
    );
  }

  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
      {recipes.map((recipe) => (
        <RecipeCard key={recipe.publicId} recipe={recipe} locale={locale} />
      ))}
    </div>
  );
}
