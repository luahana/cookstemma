import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/data/models/recipe/trending_tree_dto.dart';
import '../providers/home_feed_provider.dart';
import '../widgets/enhanced_search_app_bar.dart';
import '../widgets/cache_status_banner.dart';
import '../widgets/section_header.dart';
import '../widgets/bento_grid_section.dart';
import '../widgets/horizontal_recipe_scroll.dart';
import '../widgets/evolution_recipe_card.dart';
import '../widgets/skeletons/home_feed_skeleton.dart';

class HomeFeedScreen extends ConsumerWidget {
  const HomeFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedState = ref.watch(homeFeedProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Enhanced Search App Bar (replaces standard AppBar)
          const EnhancedSearchAppBar(),

          // Main content
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref.read(homeFeedProvider.notifier).refresh();
              },
              child: _buildContent(context, ref, feedState),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, HomeFeedState feedState) {
    // Show shimmer skeleton only if no data available
    if (feedState.isLoading && feedState.data == null) {
      return const HomeFeedSkeleton();
    }

    // Show error only if no data available
    if (feedState.error != null && feedState.data == null) {
      return _buildErrorState(context, ref, feedState.error!);
    }

    final feed = feedState.data;
    if (feed == null) {
      return _buildErrorState(context, ref, 'common.noData'.tr());
    }

    // Sort trending trees by evolution (variantCount + logCount) descending
    final sortedTrending = List<TrendingTreeDto>.from(feed.trendingTrees)
      ..sort((a, b) {
        final aScore = a.variantCount + a.logCount;
        final bScore = b.variantCount + b.logCount;
        return bScore.compareTo(aScore);
      });

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Cache status banner
        SliverToBoxAdapter(
          child: CacheStatusBanner(
            isFromCache: feedState.isFromCache,
            cachedAt: feedState.cachedAt,
            isLoading: feedState.isLoading,
          ),
        ),

        // Section 1: Most Evolved (Bento Grid)
        if (sortedTrending.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: SectionHeader(
              title: 'home.mostEvolved'.tr(),
              onSeeAll: () => context.push(RouteConstants.recipes),
            ),
          ),
          SliverToBoxAdapter(
            child: BentoGridFromTrending(trendingTrees: sortedTrending.take(3).toList()),
          ),
        ],

        // Section 2: Hot Right Now (Horizontal Activity)
        if (feed.recentActivity.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: SectionHeader(
              title: 'home.hotRightNow'.tr(),
              onSeeAll: () => context.push(RouteConstants.logPosts),
            ),
          ),
          SliverToBoxAdapter(
            child: HorizontalActivityScroll(activities: feed.recentActivity),
          ),
        ],

        // Section 3: Fresh Uploads (Vertical Recipe List)
        if (feed.recentRecipes.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: SectionHeader(
              title: 'home.freshUploads'.tr(),
              onSeeAll: () => context.push(RouteConstants.recipes),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final recipe = feed.recentRecipes[index];
                return EvolutionRecipeCard(recipe: recipe);
              },
              childCount: feed.recentRecipes.length,
            ),
          ),
        ],

        // Bottom padding
        SliverToBoxAdapter(
          child: SizedBox(height: 32.h),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object err) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48.sp, color: Colors.red),
                SizedBox(height: 16.h),
                Text('common.errorWithMessage'.tr(namedArgs: {'message': err.toString()})),
                TextButton(
                  onPressed: () => ref.invalidate(homeFeedProvider),
                  child: Text('common.tryAgain'.tr()),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
