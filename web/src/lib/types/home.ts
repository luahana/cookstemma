import type { RecipeSummary, TrendingTree } from './recipe';
import type { RecentActivity } from './log';

/**
 * Home feed response
 */
export interface HomeFeedResponse {
  recentActivity: RecentActivity[];
  recentRecipes: RecipeSummary[];
  trendingTrees: TrendingTree[];
}
