import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/core/widgets/app_cached_image.dart';
import 'package:pairing_planet2_frontend/data/models/log_post/log_post_summary_dto.dart';
import 'package:pairing_planet2_frontend/data/models/recipe/recipe_summary_dto.dart';
import 'package:pairing_planet2_frontend/features/auth/providers/auth_provider.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(myProfileProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          '마이페이지',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              context.push(RouteConstants.profileEdit);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              _showLogoutDialog(context);
            },
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) => Column(
          children: [
            // Profile Header
            _buildProfileHeader(profile),
            // Tab Bar
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF1A237E),
                unselectedLabelColor: Colors.grey[600],
                indicatorColor: const Color(0xFF1A237E),
                tabs: const [
                  Tab(text: '내 레시피'),
                  Tab(text: '내 로그'),
                  Tab(text: '저장됨'),
                ],
              ),
            ),
            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  _MyRecipesTab(),
                  _MyLogsTab(),
                  _SavedRecipesTab(),
                ],
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                '프로필을 불러올 수 없습니다',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(myProfileProvider),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(dynamic profile) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Profile Image
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.grey[200],
            backgroundImage: profile.user.profileImageUrl != null
                ? NetworkImage(profile.user.profileImageUrl)
                : null,
            child: profile.user.profileImageUrl == null
                ? Icon(Icons.person, size: 40, color: Colors.grey[400])
                : null,
          ),
          const SizedBox(height: 12),
          // Username
          Text(
            '@${profile.user.username}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          // Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem('레시피', profile.recipeCount),
              _buildStatDivider(),
              _buildStatItem('로그', profile.logCount),
              _buildStatDivider(),
              _buildStatItem('저장', profile.savedCount),
            ],
          ),
          const SizedBox(height: 16),
          // Follow Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTappableStatItem(
                context,
                '팔로워',
                profile.user.followerCount,
                () => context.push(
                  RouteConstants.followersPath(profile.user.id),
                ),
              ),
              const SizedBox(width: 32),
              _buildTappableStatItem(
                context,
                '팔로잉',
                profile.user.followingCount,
                () => context.push(
                  '${RouteConstants.followersPath(profile.user.id)}?tab=1',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A237E),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.grey[300],
    );
  }

  Widget _buildTappableStatItem(
    BuildContext context,
    String label,
    int count,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            count.toString(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A237E),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authStateProvider.notifier).logout();
            },
            child: const Text('로그아웃', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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
    timeText = "방금 전";
  } else if (diff.inMinutes < 60) {
    timeText = "${diff.inMinutes}분 전";
  } else {
    timeText = "${diff.inHours}시간 전";
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
          "마지막 업데이트: $timeText",
          style: TextStyle(fontSize: 12, color: Colors.orange[700]),
        ),
        if (isLoading) ...[
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

/// 내 레시피 탭
class _MyRecipesTab extends ConsumerStatefulWidget {
  const _MyRecipesTab();

  @override
  ConsumerState<_MyRecipesTab> createState() => _MyRecipesTabState();
}

class _MyRecipesTabState extends ConsumerState<_MyRecipesTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      ref.read(myRecipesProvider.notifier).fetchNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myRecipesProvider);

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

    // Empty state
    if (state.items.isEmpty) {
      return _buildEmptyState(
        icon: Icons.restaurant_menu,
        message: '아직 만든 레시피가 없어요',
        subMessage: '나만의 레시피를 만들어보세요!',
      );
    }

    // Data available
    return RefreshIndicator(
      onRefresh: () => ref.read(myRecipesProvider.notifier).refresh(),
      child: Column(
        children: [
          _buildCacheIndicator(
            isFromCache: state.isFromCache,
            cachedAt: state.cachedAt,
            isLoading: state.isLoading,
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: state.items.length + (state.hasNext ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= state.items.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                return _buildRecipeCard(context, state.items[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeCard(BuildContext context, RecipeSummaryDto recipe) {
    return GestureDetector(
      onTap: () => context.push(RouteConstants.recipeDetailPath(recipe.publicId)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
              child: recipe.thumbnail != null
                  ? AppCachedImage(
                      imageUrl: recipe.thumbnail!,
                      width: 100,
                      height: 100,
                      borderRadius: 0,
                    )
                  : Container(
                      width: 100,
                      height: 100,
                      color: Colors.grey[200],
                      child: Icon(Icons.restaurant, color: Colors.grey[400]),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    Text(
                      recipe.foodName,
                      style: TextStyle(
                        fontSize: 13,
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
  const _MyLogsTab();

  @override
  ConsumerState<_MyLogsTab> createState() => _MyLogsTabState();
}

class _MyLogsTabState extends ConsumerState<_MyLogsTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      ref.read(myLogsProvider.notifier).fetchNextPage();
    }
  }

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

    // Empty state
    if (state.items.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history_edu,
        message: '아직 요리 기록이 없어요',
        subMessage: '레시피를 따라 요리하고 기록을 남겨보세요!',
      );
    }

    // Data available
    return RefreshIndicator(
      onRefresh: () => ref.read(myLogsProvider.notifier).refresh(),
      child: Column(
        children: [
          _buildCacheIndicator(
            isFromCache: state.isFromCache,
            cachedAt: state.cachedAt,
            isLoading: state.isLoading,
          ),
          Expanded(
            child: GridView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: state.items.length + (state.hasNext ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= state.items.length) {
                  return const Center(child: CircularProgressIndicator());
                }
                return _buildLogCard(context, state.items[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogCard(BuildContext context, LogPostSummaryDto log) {
    return GestureDetector(
      onTap: () => context.push(RouteConstants.logPostDetailPath(log.publicId)),
      child: Container(
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
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
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
                            child: Icon(Icons.restaurant, size: 40, color: Colors.grey[400]),
                          ),
                  ),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        _getOutcomeEmoji(log.outcome),
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                log.title ?? '',
                style: const TextStyle(
                  fontSize: 13,
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

/// 저장한 레시피 탭
class _SavedRecipesTab extends ConsumerStatefulWidget {
  const _SavedRecipesTab();

  @override
  ConsumerState<_SavedRecipesTab> createState() => _SavedRecipesTabState();
}

class _SavedRecipesTabState extends ConsumerState<_SavedRecipesTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      ref.read(savedRecipesProvider.notifier).fetchNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(savedRecipesProvider);

    // Initial loading (no cached data)
    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error with no data
    if (state.error != null && state.items.isEmpty) {
      return _buildErrorState(() {
        ref.read(savedRecipesProvider.notifier).refresh();
      });
    }

    // Empty state
    if (state.items.isEmpty) {
      return _buildEmptyState(
        icon: Icons.bookmark_border,
        message: '저장한 레시피가 없어요',
        subMessage: '마음에 드는 레시피를 저장해보세요!',
      );
    }

    // Data available
    return RefreshIndicator(
      onRefresh: () => ref.read(savedRecipesProvider.notifier).refresh(),
      child: Column(
        children: [
          _buildCacheIndicator(
            isFromCache: state.isFromCache,
            cachedAt: state.cachedAt,
            isLoading: state.isLoading,
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: state.items.length + (state.hasNext ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= state.items.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                return _buildSavedRecipeCard(context, state.items[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedRecipeCard(BuildContext context, RecipeSummaryDto recipe) {
    return GestureDetector(
      onTap: () => context.push(RouteConstants.recipeDetailPath(recipe.publicId)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
              child: recipe.thumbnail != null
                  ? AppCachedImage(
                      imageUrl: recipe.thumbnail!,
                      width: 100,
                      height: 100,
                      borderRadius: 0,
                    )
                  : Container(
                      width: 100,
                      height: 100,
                      color: Colors.grey[200],
                      child: Icon(Icons.restaurant, color: Colors.grey[400]),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            recipe.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(
                          Icons.bookmark,
                          size: 18,
                          color: Color(0xFF1A237E),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      recipe.foodName,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (recipe.creatorName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'by ${recipe.creatorName}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
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
        Icon(icon, size: 64, color: Colors.grey[400]),
        const SizedBox(height: 16),
        Text(
          message,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subMessage,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
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
        const Icon(Icons.error_outline, size: 48, color: Colors.red),
        const SizedBox(height: 16),
        Text(
          '데이터를 불러올 수 없습니다',
          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: onRetry,
          child: const Text('다시 시도'),
        ),
      ],
    ),
  );
}
