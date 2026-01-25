import type {
  SearchResultItem,
  RecipeSummary,
  LogPostSummary,
  HashtagSearchResult,
} from '@/lib/types';
import { isRecipeResult, isLogResult, isHashtagResult } from '@/lib/types';
import { RecipeCard } from '@/components/recipe/RecipeCard';
import { LogCard } from '@/components/log/LogCard';
import { HashtagCard } from './HashtagCard';

interface SearchResultCardProps {
  item: SearchResultItem;
  showTypeLabel?: boolean;
}

export function SearchResultCard({ item, showTypeLabel = false }: SearchResultCardProps) {
  if (isRecipeResult(item)) {
    return <RecipeCard recipe={item.data as RecipeSummary} showTypeLabel={showTypeLabel} />;
  }

  if (isLogResult(item)) {
    return <LogCard log={item.data as LogPostSummary} showTypeLabel={showTypeLabel} />;
  }

  if (isHashtagResult(item)) {
    return <HashtagCard hashtag={item.data as HashtagSearchResult} />;
  }

  // Fallback for unknown types
  return null;
}
