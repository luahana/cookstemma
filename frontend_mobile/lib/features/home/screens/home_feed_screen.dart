import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/core/widgets/app_cached_image.dart';
import 'package:pairing_planet2_frontend/data/models/home/recent_activity_dto.dart';
import 'package:pairing_planet2_frontend/data/models/recipe/recipe_summary_dto.dart';
import 'package:pairing_planet2_frontend/data/models/recipe/trending_tree_dto.dart';
import '../providers/home_feed_provider.dart';

class HomeFeedScreen extends ConsumerWidget {
  const HomeFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedState = ref.watch(homeFeedProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Pairing Planet",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(homeFeedProvider.notifier).refresh();
        },
        child: _buildContent(context, ref, feedState),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, HomeFeedState feedState) {
    // Show loading only if no data available
    if (feedState.isLoading && feedState.data == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show error only if no data available
    if (feedState.error != null && feedState.data == null) {
      return _buildErrorState(context, ref, feedState.error!);
    }

    final feed = feedState.data;
    if (feed == null) {
      return _buildErrorState(context, ref, 'common.noData'.tr());
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cache status indicator (optional)
          if (feedState.isFromCache && feedState.cachedAt != null)
            _buildCacheIndicator(feedState),

          // Section 1: Recent Activity
          if (feed.recentActivity.isNotEmpty) ...[
            _buildSectionHeader('home.recentActivity'.tr()),
            ...feed.recentActivity.map((activity) => _buildActivityCard(context, activity)),
          ],

          // Section 2: Trending Trees
          if (feed.trendingTrees.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSectionHeader('home.trendingVariants'.tr()),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: feed.trendingTrees.length,
                itemBuilder: (context, index) {
                  return _buildTrendingTreeCard(context, feed.trendingTrees[index]);
                },
              ),
            ),
          ],

          // Section 3: Recent Recipes
          if (feed.recentRecipes.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSectionHeader('home.recentRecipes'.tr()),
            ...feed.recentRecipes.map((recipe) => _buildRecipeCard(context, recipe)),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildCacheIndicator(HomeFeedState state) {
    final cachedAt = state.cachedAt;
    if (cachedAt == null) return const SizedBox.shrink();

    final diff = DateTime.now().difference(cachedAt);
    String timeText;
    if (diff.inMinutes < 1) {
      timeText = 'common.justNow'.tr();
    } else if (diff.inMinutes < 60) {
      timeText = 'common.minutesAgo'.tr(namedArgs: {'count': diff.inMinutes.toString()});
    } else {
      timeText = 'common.hoursAgo'.tr(namedArgs: {'count': diff.inHours.toString()});
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.orange[50],
      child: Row(
        children: [
          Icon(Icons.access_time, size: 14, color: Colors.orange[700]),
          const SizedBox(width: 6),
          Text(
            'common.lastUpdatedTime'.tr(namedArgs: {'time': timeText}),
            style: TextStyle(fontSize: 12, color: Colors.orange[700]),
          ),
          if (state.isLoading) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.orange[700],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActivityCard(BuildContext context, RecentActivityDto activity) {
    final outcomeEmoji = switch (activity.outcome) {
      'SUCCESS' => '😊',
      'PARTIAL' => '😐',
      'FAILED' => '😢',
      _ => '🍳',
    };

    return GestureDetector(
      onTap: () => context.push(RouteConstants.logPostDetailPath(activity.logPublicId)),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail with outcome overlay
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: activity.thumbnailUrl != null
                      ? AppCachedImage(
                          imageUrl: activity.thumbnailUrl!,
                          width: 60,
                          height: 60,
                          borderRadius: 8,
                        )
                      : Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[200],
                          child: const Icon(Icons.restaurant, color: Colors.grey),
                        ),
                ),
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(outcomeEmoji, style: const TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            // Activity info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'home.cookedThis'.tr(namedArgs: {'name': activity.creatorName}),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activity.recipeTitle,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    activity.foodName,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.indigo[700],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingTreeCard(BuildContext context, TrendingTreeDto tree) {
    return GestureDetector(
      onTap: () => context.push(RouteConstants.recipeDetailPath(tree.rootRecipeId)),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: tree.thumbnail != null
                  ? AppCachedImage(
                      imageUrl: tree.thumbnail!,
                      width: 160,
                      height: 100,
                      borderRadius: 0,
                    )
                  : Container(
                      width: 160,
                      height: 100,
                      color: Colors.orange[100],
                      child: Icon(Icons.restaurant_menu, size: 40, color: Colors.orange[300]),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tree.foodName ?? tree.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tree.title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        "🔀 ${tree.variantCount}",
                        style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "📝 ${tree.logCount}",
                        style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeCard(BuildContext context, RecipeSummaryDto recipe) {
    return GestureDetector(
      onTap: () => context.push(RouteConstants.recipeDetailPath(recipe.publicId)),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: recipe.thumbnail != null
                  ? AppCachedImage(
                      imageUrl: recipe.thumbnail!,
                      width: 70,
                      height: 70,
                      borderRadius: 8,
                    )
                  : Container(
                      width: 70,
                      height: 70,
                      color: Colors.grey[200],
                      child: const Icon(Icons.restaurant_menu, color: Colors.grey),
                    ),
            ),
            const SizedBox(width: 12),
            // Recipe info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.foodName,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.indigo[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    recipe.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if ((recipe.variantCount ?? 0) > 0)
                        Text(
                          "🔀 ${'home.variants'.tr(namedArgs: {'count': recipe.variantCount.toString()})}",
                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                      if ((recipe.variantCount ?? 0) > 0 && (recipe.logCount ?? 0) > 0)
                        Text(" · ", style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                      if ((recipe.logCount ?? 0) > 0)
                        Text(
                          "📝 ${'home.logs'.tr(namedArgs: {'count': recipe.logCount.toString()})}",
                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object err) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
        Center(
          child: Column(
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('common.errorWithMessage'.tr(namedArgs: {'message': err.toString()})),
              TextButton(
                onPressed: () => ref.invalidate(homeFeedProvider),
                child: Text('common.tryAgain'.tr()),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
