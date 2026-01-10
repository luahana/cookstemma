import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nested_scroll_view_plus/nested_scroll_view_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/core/providers/scroll_to_top_provider.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/core/widgets/app_cached_image.dart';
import 'package:pairing_planet2_frontend/core/widgets/app_logo.dart';
import 'package:pairing_planet2_frontend/data/models/log_post/log_post_summary_dto.dart';
import 'package:pairing_planet2_frontend/data/models/recipe/recipe_summary_dto.dart';
import 'package:pairing_planet2_frontend/features/auth/providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/cooking_dna_provider.dart';
import '../widgets/cooking_dna_header.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;

  const ProfileScreen({super.key, this.initialTabIndex = 0});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 2),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
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

  @override
  Widget build(BuildContext context) {
    // Listen to scroll-to-top events for tab index 3 (Profile)
    ref.listen<int>(scrollToTopProvider(3), (previous, current) {
      if (previous != null && current != previous) {
        _scrollToTop();
      }
    });
    final authStatus = ref.watch(authStateProvider).status;

    // Show guest view for unauthenticated users
    if (authStatus == AuthStatus.guest || authStatus == AuthStatus.unauthenticated) {
      return _buildGuestView(context);
    }

    final profileAsync = ref.watch(myProfileProvider);
    final cookingDnaState = ref.watch(cookingDnaProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: profileAsync.when(
        data: (profile) => NestedScrollViewPlus(
          controller: _scrollController,
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            // Pinned app bar
            SliverAppBar(
              pinned: true,
              floating: false,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: innerBoxIsScrolled ? 1 : 0,
              centerTitle: false,
              title: const AppLogo(),
              actions: [
                IconButton(
                  icon: Icon(Icons.settings_outlined, size: 22.sp),
                  onPressed: () => context.push(RouteConstants.settings),
                ),
              ],
            ),
            // Instagram-style pull-to-refresh - grows from 0 height, pushes content down
            CupertinoSliverRefreshControl(
              onRefresh: () async {
                ref.invalidate(myProfileProvider);
                ref.invalidate(cookingDnaProvider);
                ref.invalidate(myRecipesProvider);
                ref.invalidate(myLogsProvider);
                ref.invalidate(savedRecipesProvider);
                ref.invalidate(savedLogsProvider);
              },
            ),
            // Header content - sizes naturally to content
            SliverToBoxAdapter(
              child: CookingDnaHeader(
                profile: profile,
                cookingDna: cookingDnaState.data,
                isLoading: cookingDnaState.isLoading,
                onRecipesTap: () => _tabController.animateTo(0),
                onLogsTap: () => _tabController.animateTo(1),
              ),
            ),
            // Sticky Tab Bar
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyTabBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: Colors.grey[600],
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3.h,
                  tabs: [
                    Tab(text: 'profile.myRecipes'.tr()),
                    Tab(text: 'profile.myLogs'.tr()),
                    Tab(text: 'profile.saved'.tr()),
                  ],
                ),
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: const [
              _MyRecipesTab(key: PageStorageKey<String>('my_recipes')),
              _MyLogsTab(key: PageStorageKey<String>('my_logs')),
              _SavedTab(key: PageStorageKey<String>('saved')),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48.sp, color: Colors.red),
              SizedBox(height: 16.h),
              Text(
                'profile.couldNotLoad'.tr(),
                style: TextStyle(fontSize: 16.sp, color: Colors.grey[700]),
              ),
              SizedBox(height: 16.h),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(myProfileProvider);
                  ref.invalidate(cookingDnaProvider);
                },
                child: Text('common.tryAgain'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuestView(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'profile.myPage'.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(32.r),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                padding: EdgeInsets.all(24.r),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_outline,
                  size: 64.sp,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              SizedBox(height: 24.h),
              // Title
              Text(
                'guest.profileTitle'.tr(),
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12.h),
              // Subtitle
              Text(
                'guest.profileSubtitle'.tr(),
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32.h),
              // Sign in button
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.login),
                  label: Text('guest.signIn'.tr()),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  onPressed: () {
                    context.push(RouteConstants.login);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Delegate for sticky tab bar in NestedScrollView
class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _StickyTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}

/// Cache indicator widget
Widget _buildCacheIndicator({
  required bool isFromCache,
  required DateTime? cachedAt,
  required bool isLoading,
}) {
  if (!isFromCache || cachedAt == null) return const SizedBox.shrink();

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
    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
    color: Colors.orange[50],
    child: Row(
      children: [
        Icon(Icons.access_time, size: 14.sp, color: Colors.orange[700]),
        SizedBox(width: 6.w),
        Text(
          'common.lastUpdatedTime'.tr(namedArgs: {'time': timeText}),
          style: TextStyle(fontSize: 12.sp, color: Colors.orange[700]),
        ),
        if (isLoading) ...[
          SizedBox(width: 8.w),
          SizedBox(
            width: 12.r,
            height: 12.r,
            child: CircularProgressIndicator(
              strokeWidth: 2.r,
              color: Colors.orange[700],
            ),
          ),
        ],
      ],
    ),
  );
}

/// 내 레시피 탭
class _MyRecipesTab extends ConsumerStatefulWidget {
  const _MyRecipesTab({super.key});

  @override
  ConsumerState<_MyRecipesTab> createState() => _MyRecipesTabState();
}

class _MyRecipesTabState extends ConsumerState<_MyRecipesTab> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myRecipesProvider);
    final notifier = ref.read(myRecipesProvider.notifier);

    // Initial loading (no cached data)
    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error with no data
    if (state.error != null && state.items.isEmpty) {
      return _buildErrorState(() {
        ref.read(myRecipesProvider.notifier).refresh();
      });
    }

    // Data available or empty (with filter chips)
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >=
            notification.metrics.maxScrollExtent * 0.8) {
          ref.read(myRecipesProvider.notifier).fetchNextPage();
        }
        return false;
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _buildCacheIndicator(
              isFromCache: state.isFromCache,
              cachedAt: state.cachedAt,
              isLoading: state.isLoading,
            ),
          ),
          // Filter chips
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Row(
                children: [
                  _buildRecipeFilterChip(
                    label: 'profile.filter.all'.tr(),
                    isSelected: notifier.currentFilter == RecipeTypeFilter.all,
                    onTap: () => notifier.setFilter(RecipeTypeFilter.all),
                  ),
                  SizedBox(width: 8.w),
                  _buildRecipeFilterChip(
                    label: 'profile.filter.original'.tr(),
                    isSelected: notifier.currentFilter == RecipeTypeFilter.original,
                    onTap: () => notifier.setFilter(RecipeTypeFilter.original),
                  ),
                  SizedBox(width: 8.w),
                  _buildRecipeFilterChip(
                    label: 'profile.filter.variants'.tr(),
                    isSelected: notifier.currentFilter == RecipeTypeFilter.variants,
                    onTap: () => notifier.setFilter(RecipeTypeFilter.variants),
                  ),
                ],
              ),
            ),
          ),
          // Empty state or list
          if (state.items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(
                icon: Icons.restaurant_menu,
                message: 'profile.noRecipesYet'.tr(),
                subMessage: 'profile.createRecipe'.tr(),
              ),
            )
          else ...[
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= state.items.length) {
                      return Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.r),
                          child: const CircularProgressIndicator(),
                        ),
                      );
                    }
                    return _buildRecipeCard(context, state.items[index]);
                  },
                  childCount: state.items.length + (state.hasNext ? 1 : 0),
                ),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 16.h)),
          ],
        ],
      ),
    );
  }

  Widget _buildRecipeFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey[200],
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildRecipeCard(BuildContext context, RecipeSummaryDto recipe) {
    return GestureDetector(
      onTap: () => context.push(RouteConstants.recipeDetailPath(recipe.publicId)),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
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
            ClipRRect(
              borderRadius: BorderRadius.horizontal(left: Radius.circular(12.r)),
              child: recipe.thumbnail != null
                  ? AppCachedImage(
                      imageUrl: recipe.thumbnail!,
                      width: 100.w,
                      height: 100.h,
                      borderRadius: 0,
                    )
                  : Container(
                      width: 100.w,
                      height: 100.h,
                      color: Colors.grey[200],
                      child: Icon(Icons.restaurant, color: Colors.grey[400]),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.title,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      recipe.foodName,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 내 로그 탭
class _MyLogsTab extends ConsumerStatefulWidget {
  const _MyLogsTab({super.key});

  @override
  ConsumerState<_MyLogsTab> createState() => _MyLogsTabState();
}

class _MyLogsTabState extends ConsumerState<_MyLogsTab> {
  String _getOutcomeEmoji(String? outcome) {
    return switch (outcome) {
      'SUCCESS' => '😊',
      'PARTIAL' => '😐',
      'FAILED' => '😢',
      _ => '🍳',
    };
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myLogsProvider);
    final notifier = ref.read(myLogsProvider.notifier);

    // Initial loading (no cached data)
    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error with no data
    if (state.error != null && state.items.isEmpty) {
      return _buildErrorState(() {
        ref.read(myLogsProvider.notifier).refresh();
      });
    }

    // Data available or empty (with filter chips)
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >=
            notification.metrics.maxScrollExtent * 0.8) {
          ref.read(myLogsProvider.notifier).fetchNextPage();
        }
        return false;
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _buildCacheIndicator(
              isFromCache: state.isFromCache,
              cachedAt: state.cachedAt,
              isLoading: state.isLoading,
            ),
          ),
          // Filter chips with emojis
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              child: Row(
                children: [
                  _buildLogFilterChip(
                    label: 'profile.filter.all'.tr(),
                    isSelected: notifier.currentFilter == LogOutcomeFilter.all,
                    onTap: () => notifier.setFilter(LogOutcomeFilter.all),
                  ),
                  SizedBox(width: 8.w),
                  _buildLogFilterChip(
                    label: '😊 ${'profile.filter.wins'.tr()}',
                    isSelected: notifier.currentFilter == LogOutcomeFilter.wins,
                    onTap: () => notifier.setFilter(LogOutcomeFilter.wins),
                  ),
                  SizedBox(width: 8.w),
                  _buildLogFilterChip(
                    label: '😐 ${'profile.filter.learning'.tr()}',
                    isSelected: notifier.currentFilter == LogOutcomeFilter.learning,
                    onTap: () => notifier.setFilter(LogOutcomeFilter.learning),
                  ),
                  SizedBox(width: 8.w),
                  _buildLogFilterChip(
                    label: '😢 ${'profile.filter.lessons'.tr()}',
                    isSelected: notifier.currentFilter == LogOutcomeFilter.lessons,
                    onTap: () => notifier.setFilter(LogOutcomeFilter.lessons),
                  ),
                ],
              ),
            ),
          ),
          // Empty state or grid
          if (state.items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(
                icon: Icons.history_edu,
                message: 'profile.noLogsYet'.tr(),
                subMessage: 'profile.tryRecipe'.tr(),
              ),
            )
          else ...[
            SliverPadding(
              padding: EdgeInsets.all(12.r),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12.h,
                  crossAxisSpacing: 12.w,
                  childAspectRatio: 0.85,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= state.items.length) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return _buildLogCard(context, state.items[index]);
                  },
                  childCount: state.items.length + (state.hasNext ? 1 : 0),
                ),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 16.h)),
          ],
        ],
      ),
    );
  }

  Widget _buildLogFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey[200],
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildLogCard(BuildContext context, LogPostSummaryDto log) {
    return GestureDetector(
      onTap: () => context.push(RouteConstants.logPostDetailPath(log.publicId)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
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
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
                    child: log.thumbnailUrl != null
                        ? AppCachedImage(
                            imageUrl: log.thumbnailUrl!,
                            width: double.infinity,
                            height: double.infinity,
                            borderRadius: 0,
                          )
                        : Container(
                            width: double.infinity,
                            color: Colors.grey[200],
                            child: Icon(Icons.restaurant, size: 40.sp, color: Colors.grey[400]),
                          ),
                  ),
                  Positioned(
                    right: 8.w,
                    bottom: 8.h,
                    child: Container(
                      padding: EdgeInsets.all(6.r),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        _getOutcomeEmoji(log.outcome),
                        style: TextStyle(fontSize: 18.sp),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(10.r),
              child: Text(
                log.title ?? '',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 저장한 탭 (레시피 + 로그)
class _SavedTab extends ConsumerStatefulWidget {
  const _SavedTab({super.key});

  @override
  ConsumerState<_SavedTab> createState() => _SavedTabState();
}

class _SavedTabState extends ConsumerState<_SavedTab> {
  SavedTypeFilter _currentFilter = SavedTypeFilter.all;

  String _getOutcomeEmoji(String? outcome) {
    return switch (outcome) {
      'SUCCESS' => '😊',
      'PARTIAL' => '😐',
      'FAILED' => '😢',
      _ => '🍳',
    };
  }

  @override
  Widget build(BuildContext context) {
    final recipesState = ref.watch(savedRecipesProvider);
    final logsState = ref.watch(savedLogsProvider);

    // Initial loading
    final isLoading = (_currentFilter == SavedTypeFilter.all || _currentFilter == SavedTypeFilter.recipes)
        ? (recipesState.isLoading && recipesState.items.isEmpty)
        : (logsState.isLoading && logsState.items.isEmpty);

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // CustomScrollView with slivers for unified scrolling
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >=
            notification.metrics.maxScrollExtent * 0.8) {
          // Fetch next page based on current filter
          switch (_currentFilter) {
            case SavedTypeFilter.all:
              // All filter shows limited items, no pagination needed
              break;
            case SavedTypeFilter.recipes:
              ref.read(savedRecipesProvider.notifier).fetchNextPage();
              break;
            case SavedTypeFilter.logs:
              ref.read(savedLogsProvider.notifier).fetchNextPage();
              break;
          }
        }
        return false;
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Filter chips
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Row(
                children: [
                  _buildFilterChip(
                    label: 'profile.filter.all'.tr(),
                    isSelected: _currentFilter == SavedTypeFilter.all,
                    onTap: () => setState(() => _currentFilter = SavedTypeFilter.all),
                  ),
                  SizedBox(width: 8.w),
                  _buildFilterChip(
                    label: 'profile.filter.recipes'.tr(),
                    isSelected: _currentFilter == SavedTypeFilter.recipes,
                    onTap: () => setState(() => _currentFilter = SavedTypeFilter.recipes),
                  ),
                  SizedBox(width: 8.w),
                  _buildFilterChip(
                    label: 'profile.filter.logs'.tr(),
                    isSelected: _currentFilter == SavedTypeFilter.logs,
                    onTap: () => setState(() => _currentFilter = SavedTypeFilter.logs),
                  ),
                ],
              ),
            ),
          ),
          // Content based on filter
          ..._buildContentSlivers(recipesState, logsState),
        ],
      ),
    );
  }

  List<Widget> _buildContentSlivers(SavedRecipesState recipesState, SavedLogsState logsState) {
    switch (_currentFilter) {
      case SavedTypeFilter.all:
        return _buildCombinedSlivers(recipesState, logsState);
      case SavedTypeFilter.recipes:
        return _buildRecipesSlivers(recipesState);
      case SavedTypeFilter.logs:
        return _buildLogsSlivers(logsState);
    }
  }

  List<Widget> _buildCombinedSlivers(SavedRecipesState recipesState, SavedLogsState logsState) {
    final hasRecipes = recipesState.items.isNotEmpty;
    final hasLogs = logsState.items.isNotEmpty;

    if (!hasRecipes && !hasLogs) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _buildEmptyState(
            icon: Icons.bookmark_border,
            message: 'profile.noSavedYet'.tr(),
            subMessage: 'profile.saveRecipe'.tr(),
          ),
        ),
      ];
    }

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasRecipes) ...[
                Text(
                  'profile.filter.recipes'.tr(),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 8.h),
                ...recipesState.items.take(3).map((recipe) => _buildSavedRecipeCard(context, recipe)),
                if (recipesState.items.length > 3)
                  TextButton(
                    onPressed: () => setState(() => _currentFilter = SavedTypeFilter.recipes),
                    child: Text('+ ${recipesState.items.length - 3} more'),
                  ),
                SizedBox(height: 16.h),
              ],
              if (hasLogs) ...[
                Text(
                  'profile.filter.logs'.tr(),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 8.h),
                ...logsState.items.take(3).map((log) => _buildSavedLogCard(context, log)),
                if (logsState.items.length > 3)
                  TextButton(
                    onPressed: () => setState(() => _currentFilter = SavedTypeFilter.logs),
                    child: Text('+ ${logsState.items.length - 3} more'),
                  ),
              ],
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildRecipesSlivers(SavedRecipesState state) {
    if (state.items.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _buildEmptyState(
            icon: Icons.bookmark_border,
            message: 'profile.noSavedYet'.tr(),
            subMessage: 'profile.saveRecipe'.tr(),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index >= state.items.length) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.r),
                    child: const CircularProgressIndicator(),
                  ),
                );
              }
              return _buildSavedRecipeCard(context, state.items[index]);
            },
            childCount: state.items.length + (state.hasNext ? 1 : 0),
          ),
        ),
      ),
      SliverToBoxAdapter(child: SizedBox(height: 16.h)),
    ];
  }

  List<Widget> _buildLogsSlivers(SavedLogsState state) {
    if (state.items.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _buildEmptyState(
            icon: Icons.bookmark_border,
            message: 'profile.noSavedYet'.tr(),
            subMessage: 'profile.saveRecipe'.tr(),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index >= state.items.length) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.r),
                    child: const CircularProgressIndicator(),
                  ),
                );
              }
              return _buildSavedLogCard(context, state.items[index]);
            },
            childCount: state.items.length + (state.hasNext ? 1 : 0),
          ),
        ),
      ),
      SliverToBoxAdapter(child: SizedBox(height: 16.h)),
    ];
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey[200],
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildSavedRecipeCard(BuildContext context, RecipeSummaryDto recipe) {
    return GestureDetector(
      onTap: () => context.push(RouteConstants.recipeDetailPath(recipe.publicId)),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
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
            ClipRRect(
              borderRadius: BorderRadius.horizontal(left: Radius.circular(12.r)),
              child: recipe.thumbnail != null
                  ? AppCachedImage(
                      imageUrl: recipe.thumbnail!,
                      width: 80.w,
                      height: 80.h,
                      borderRadius: 0,
                    )
                  : Container(
                      width: 80.w,
                      height: 80.h,
                      color: Colors.grey[200],
                      child: Icon(Icons.restaurant, color: Colors.grey[400]),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            recipe.title,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          Icons.bookmark,
                          size: 16.sp,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      recipe.foodName,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedLogCard(BuildContext context, LogPostSummaryDto log) {
    return GestureDetector(
      onTap: () => context.push(RouteConstants.logPostDetailPath(log.publicId)),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
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
            ClipRRect(
              borderRadius: BorderRadius.horizontal(left: Radius.circular(12.r)),
              child: log.thumbnailUrl != null
                  ? AppCachedImage(
                      imageUrl: log.thumbnailUrl!,
                      width: 80.w,
                      height: 80.h,
                      borderRadius: 0,
                    )
                  : Container(
                      width: 80.w,
                      height: 80.h,
                      color: Colors.grey[200],
                      child: Icon(Icons.restaurant, color: Colors.grey[400]),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            log.title ?? 'Cooking Log',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _getOutcomeEmoji(log.outcome),
                          style: TextStyle(fontSize: 16.sp),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'by ${log.creatorName}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper widgets
Widget _buildEmptyState({
  required IconData icon,
  required String message,
  required String subMessage,
}) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 64.sp, color: Colors.grey[400]),
        SizedBox(height: 16.h),
        Text(
          message,
          style: TextStyle(
            fontSize: 16.sp,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          subMessage,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.grey[500],
          ),
        ),
      ],
    ),
  );
}

Widget _buildErrorState(VoidCallback onRetry) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 48.sp, color: Colors.red),
        SizedBox(height: 16.h),
        Text(
          'common.couldNotLoad'.tr(),
          style: TextStyle(fontSize: 16.sp, color: Colors.grey[700]),
        ),
        SizedBox(height: 16.h),
        ElevatedButton(
          onPressed: onRetry,
          child: Text('common.tryAgain'.tr()),
        ),
      ],
    ),
  );
}
