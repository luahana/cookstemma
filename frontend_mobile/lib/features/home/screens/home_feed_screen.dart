import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nested_scroll_view_plus/nested_scroll_view_plus.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/core/providers/scroll_to_top_provider.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/data/models/home/home_feed_response_dto.dart';
import 'package:pairing_planet2_frontend/data/models/recipe/trending_tree_dto.dart';
import 'package:pairing_planet2_frontend/features/auth/providers/auth_provider.dart';
import 'package:pairing_planet2_frontend/features/profile/providers/profile_provider.dart';
import 'package:pairing_planet2_frontend/features/recipe/providers/browse_filter_provider.dart';
import 'package:pairing_planet2_frontend/core/widgets/app_logo.dart';
import 'package:pairing_planet2_frontend/core/widgets/search/hero_search_bar.dart';
import 'package:pairing_planet2_frontend/core/widgets/search/hero_search_icon.dart';
import '../providers/home_feed_provider.dart';
import '../widgets/cache_status_banner.dart';
import '../widgets/section_header.dart';
import '../widgets/bento_grid_section.dart';
import '../widgets/horizontal_recipe_scroll.dart';
import '../widgets/evolution_recipe_card.dart';
import '../widgets/skeletons/home_feed_skeleton.dart';

class HomeFeedScreen extends ConsumerStatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  ConsumerState<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends ConsumerState<HomeFeedScreen> {
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> _titleOpacity = ValueNotifier<double>(0.0);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateTitleOpacity);
  }

  void _updateTitleOpacity() {
    if (!_scrollController.hasClients) return;
    final maxScroll = 100.h - kToolbarHeight;
    final opacity = (_scrollController.offset / maxScroll).clamp(0.0, 1.0);
    if (opacity != _titleOpacity.value) {
      _titleOpacity.value = opacity;
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateTitleOpacity);
    _scrollController.dispose();
    _titleOpacity.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'home.goodMorning'.tr();
    } else if (hour >= 12 && hour < 17) {
      return 'home.goodAfternoon'.tr();
    } else {
      return 'home.goodEvening'.tr();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to scroll-to-top events for tab index 0 (Home)
    ref.listen<int>(scrollToTopProvider(0), (previous, current) {
      if (previous != null && current != previous) {
        _scrollToTop();
      }
    });
    final feedState = ref.watch(homeFeedProvider);
    final authState = ref.watch(authStateProvider);

    // Get username if authenticated
    String? username;
    if (authState.status == AuthStatus.authenticated) {
      final profileAsync = ref.watch(myProfileProvider);
      username = profileAsync.whenOrNull(
        data: (profile) => profile.user.username,
      );
    }

    final greeting = _getGreeting();
    final displayName = username ?? 'home.welcome'.tr();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _buildContent(feedState, greeting, displayName),
    );
  }

  Widget _buildContent(HomeFeedState feedState, String greeting, String displayName) {
    return RefreshIndicator(
      notificationPredicate: (notification) {
        // Allow refresh from any scroll depth (needed for NestedScrollView)
        return notification.depth == 0 || notification.depth == 1;
      },
      onRefresh: () async {
        await ref.read(homeFeedProvider.notifier).refresh();
      },
      child: NestedScrollViewPlus(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverAppBar(greeting, displayName, innerBoxIsScrolled),
        ],
        body: Builder(
        builder: (context) {
          // Show skeleton if loading with no data
          if (feedState.isLoading && feedState.data == null) {
            return CustomScrollView(
              slivers: [
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: HomeFeedSkeleton(),
                ),
              ],
            );
          }
          // Show error if error with no data
          if (feedState.error != null && feedState.data == null) {
            return CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildErrorContent(feedState.error!),
                ),
              ],
            );
          }
          // Show no data message if null
          if (feedState.data == null) {
            return CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildErrorContent('common.noData'.tr()),
                ),
              ],
            );
          }
          // Normal content
          return _buildContentBody(feedState);
        },
      ),
      ),
    );
  }

  /// Build content body - returns CustomScrollView with proper slivers
  Widget _buildContentBody(HomeFeedState feedState) {
    return CustomScrollView(
      slivers: [
        // Cache status banner
        SliverToBoxAdapter(
          child: CacheStatusBanner(
            isFromCache: feedState.isFromCache,
            cachedAt: feedState.cachedAt,
            isLoading: feedState.isLoading,
          ),
        ),
        // Content slivers
        ..._buildContentSlivers(feedState.data!, context),
      ],
    );
  }

  List<Widget> _buildContentSlivers(HomeFeedResponseDto feed, BuildContext context) {
    // Sort trending trees by evolution (variantCount + logCount) descending
    final sortedTrending = List<TrendingTreeDto>.from(feed.trendingTrees)
      ..sort((a, b) {
        final aScore = a.variantCount + a.logCount;
        final bScore = b.variantCount + b.logCount;
        return bScore.compareTo(aScore);
      });

    return [
      // Section 1: Most Evolved (Bento Grid)
      if (sortedTrending.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: SectionHeader(
            title: 'home.mostEvolved'.tr(),
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
            onSeeAll: () {
              ref.read(browseFilterProvider.notifier).setSortOption(RecipeSortOption.mostForked);
              context.push(RouteConstants.recipes);
            },
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
    ];
  }

  /// Error content for use inside SliverFillRemaining
  Widget _buildErrorContent(Object err) {
    return Center(
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
    );
  }

  Widget _buildSliverAppBar(String greeting, String displayName, bool innerBoxIsScrolled) {
    return SliverAppBar(
      pinned: true,
      floating: false,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: innerBoxIsScrolled ? 1 : 0,
      expandedHeight: 100.h,
      centerTitle: false,
      title: ValueListenableBuilder<double>(
        valueListenable: _titleOpacity,
        builder: (context, opacity, child) => Opacity(
          opacity: opacity,
          child: child,
        ),
        child: const AppLogo(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Greeting row
                RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 18.sp,
                      color: AppColors.textPrimary,
                    ),
                    children: [
                      TextSpan(
                        text: '$greeting, ',
                        style: const TextStyle(fontWeight: FontWeight.normal),
                      ),
                      TextSpan(
                        text: displayName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: '!'),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),
                // Search bar - taps navigate to dedicated search page with Hero animation
                HeroSearchBar(
                  onTap: () => context.push(RouteConstants.search),
                  hintText: 'home.searchHint'.tr(),
                  heroTag: 'search-hero',
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        ValueListenableBuilder<double>(
          valueListenable: _titleOpacity,
          builder: (context, opacity, child) => Opacity(
            opacity: opacity,
            child: child,
          ),
          child: HeroSearchIcon(
            onTap: () => context.push(RouteConstants.search),
            heroTag: 'search-icon-hero',
          ),
        ),
        IconButton(
          onPressed: () => context.push(RouteConstants.notifications),
          icon: const Icon(Icons.notifications_outlined),
        ),
      ],
    );
  }

}
