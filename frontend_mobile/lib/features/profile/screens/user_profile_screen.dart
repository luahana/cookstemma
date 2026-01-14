import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nested_scroll_view_plus/nested_scroll_view_plus.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/core/utils/url_launcher_utils.dart';
import 'package:pairing_planet2_frontend/data/models/user/user_dto.dart';
import 'package:pairing_planet2_frontend/features/profile/providers/profile_provider.dart';
import 'package:pairing_planet2_frontend/features/profile/providers/follow_provider.dart';
import 'package:pairing_planet2_frontend/features/profile/providers/user_profile_provider.dart';
import 'package:pairing_planet2_frontend/features/profile/widgets/follow_button.dart';
import 'package:pairing_planet2_frontend/features/profile/widgets/level_badge.dart';
import 'package:pairing_planet2_frontend/features/profile/widgets/profile_shared.dart';
import 'package:pairing_planet2_frontend/features/profile/widgets/user_action_menu.dart';
import 'package:pairing_planet2_frontend/features/profile/widgets/tabs/user_recipes_tab.dart';
import 'package:pairing_planet2_frontend/features/profile/widgets/tabs/user_logs_tab.dart';
import 'package:pairing_planet2_frontend/core/widgets/custom_bottom_nav_bar.dart';
import 'package:pairing_planet2_frontend/features/auth/providers/auth_provider.dart';
import 'package:pairing_planet2_frontend/features/profile/providers/cooking_dna_provider.dart';

/// Screen for viewing other user's public profile
class UserProfileScreen extends ConsumerStatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _navigateToTab(BuildContext context, int index) {
    // Navigate to tab root using go (replaces current route)
    switch (index) {
      case 0:
        context.go(RouteConstants.home);
        break;
      case 1:
        context.go(RouteConstants.recipes);
        break;
      case 2:
        context.go(RouteConstants.logPosts);
        break;
      case 3:
        context.go(RouteConstants.profile);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider(widget.userId));
    final followStatusAsync = ref.watch(followStatusProvider(widget.userId));

    // Get auth state and cooking DNA for bottom nav
    final authState = ref.watch(authStateProvider);
    final isGuest = authState.status == AuthStatus.guest;
    final cookingDnaState = isGuest ? null : ref.watch(cookingDnaProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: -1, // No tab selected when viewing user profile
        onTap: (index) => _navigateToTab(context, index),
        onFabTap: () {
          // For now, just navigate to home if FAB is tapped
          // Could show create options sheet if needed
          context.go(RouteConstants.home);
        },
        levelProgress: cookingDnaState?.data?.levelProgress,
        level: cookingDnaState?.data?.level,
        isGuest: isGuest,
      ),
      body: profileAsync.when(
        data: (user) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(userProfileProvider(widget.userId));
            ref.invalidate(followStatusProvider(widget.userId));
            ref.invalidate(userRecipesProvider(widget.userId));
            ref.invalidate(userLogsProvider(widget.userId));
          },
          child: NestedScrollViewPlus(
            controller: _scrollController,
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              // App Bar
              SliverAppBar(
                pinned: true,
                floating: false,
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: innerBoxIsScrolled ? 1 : 0,
                centerTitle: false,
                titleSpacing: 0,
                automaticallyImplyLeading: false,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.pop(),
                ),
                title: Text(
                  user.username,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                actions: _buildAppBarActions(user),
              ),
              // Profile Header
              SliverToBoxAdapter(
                child: _buildProfileHeader(
                  user,
                  followStatusAsync.value ?? false,
                ),
              ),
              // Tab Bar
              SliverPersistentHeader(
                pinned: true,
                delegate: StickyTabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: Colors.grey[600],
                    indicatorColor: AppColors.primary,
                    indicatorWeight: 3.h,
                    tabs: [
                      Tab(text: 'profile.recipes'.tr()),
                      Tab(text: 'profile.logs'.tr()),
                    ],
                  ),
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                UserRecipesTab(
                  key: PageStorageKey<String>('user_recipes_${widget.userId}'),
                  userId: widget.userId,
                ),
                UserLogsTab(
                  key: PageStorageKey<String>('user_logs_${widget.userId}'),
                  userId: widget.userId,
                ),
              ],
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(),
      ),
    );
  }

  Widget _buildProfileHeader(UserDto user, bool isFollowing) {
    // Check if this is the current user's own profile
    final myProfile = ref.read(myProfileProvider);
    final currentUserId = myProfile.valueOrNull?.user.id;
    final isOwnProfile = currentUserId == widget.userId;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(16.r),
      child: Column(
        children: [
          // Avatar and username row
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 40.r,
                backgroundColor: Colors.grey[200],
                backgroundImage: user.profileImageUrl != null
                    ? NetworkImage(user.profileImageUrl!)
                    : null,
                child: user.profileImageUrl == null
                    ? Icon(Icons.person, size: 40.sp, color: Colors.grey[400])
                    : null,
              ),
              SizedBox(width: 20.w),
              // Stats
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatColumn(
                      user.recipeCount.toString(),
                      'profile.recipes'.tr(),
                      () => _tabController.animateTo(0),
                    ),
                    _buildStatColumn(
                      user.logCount.toString(),
                      'profile.logs'.tr(),
                      () => _tabController.animateTo(1),
                    ),
                    _buildStatColumn(
                      user.followerCount.toString(),
                      'profile.followers'.tr(),
                      () => context.push(RouteConstants.followersPath(widget.userId)),
                    ),
                    _buildStatColumn(
                      user.followingCount.toString(),
                      'profile.following'.tr(),
                      () => context.push('${RouteConstants.followersPath(widget.userId)}?tab=1'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          // Level badge
          Align(
            alignment: Alignment.centerLeft,
            child: LevelBadge(
              level: user.level,
              levelName: user.levelName,
            ),
          ),
          // Bio and social links
          if (_hasBioOrSocialLinks(user)) ...[
            SizedBox(height: 4.h),
            _buildBioAndSocialLinks(user),
          ],
          SizedBox(height: 12.h),
          // Follow button (only show if not own profile)
          if (!isOwnProfile)
            SizedBox(
              width: double.infinity,
              child: FollowButton(
                userId: widget.userId,
                initialIsFollowing: isFollowing,
                onFollowChanged: () {
                  ref.invalidate(userProfileProvider(widget.userId));
                },
              ),
            ),
        ],
      ),
    );
  }

  bool _hasBioOrSocialLinks(UserDto user) {
    return (user.bio != null && user.bio!.isNotEmpty) ||
        (user.youtubeUrl != null && user.youtubeUrl!.isNotEmpty) ||
        (user.instagramHandle != null && user.instagramHandle!.isNotEmpty);
  }

  bool _hasSocialLinks(UserDto user) {
    return (user.youtubeUrl != null && user.youtubeUrl!.isNotEmpty) ||
        (user.instagramHandle != null && user.instagramHandle!.isNotEmpty);
  }

  Widget _buildBioAndSocialLinks(UserDto user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bio
        if (user.bio != null && user.bio!.isNotEmpty) ...[
          Text(
            user.bio!,
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
          if (_hasSocialLinks(user)) SizedBox(height: 8.h),
        ],
        // Social links
        if (_hasSocialLinks(user)) _buildSocialLinksRow(user),
      ],
    );
  }

  Widget _buildSocialLinksRow(UserDto user) {
    return Row(
      children: [
        if (user.youtubeUrl != null && user.youtubeUrl!.isNotEmpty)
          _buildSocialButton(
            icon: Icons.play_circle_filled,
            color: const Color(0xFFFF0000),
            label: 'YouTube',
            onTap: () => UrlLauncherUtils.launchYoutube(user.youtubeUrl!),
          ),
        if (user.youtubeUrl != null &&
            user.youtubeUrl!.isNotEmpty &&
            user.instagramHandle != null &&
            user.instagramHandle!.isNotEmpty)
          SizedBox(width: 8.w),
        if (user.instagramHandle != null && user.instagramHandle!.isNotEmpty)
          _buildSocialButton(
            icon: Icons.camera_alt,
            color: const Color(0xFFE1306C),
            label: 'Instagram',
            onTap: () => UrlLauncherUtils.launchInstagram(user.instagramHandle!),
          ),
      ],
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16.sp, color: color),
            SizedBox(width: 4.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAppBarActions(UserDto user) {
    // Check if this is the current user's own profile
    final myProfile = ref.read(myProfileProvider);
    final currentUserId = myProfile.valueOrNull?.user.id;
    final isOwnProfile = currentUserId == widget.userId;

    if (isOwnProfile) return [];

    return [
      UserActionMenu(
        userId: widget.userId,
        onBlocked: () {
          // Invalidate providers when user is blocked
          ref.invalidate(userProfileProvider(widget.userId));
        },
      ),
    ];
  }

  Widget _buildStatColumn(String count, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            count,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
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
              ref.invalidate(userProfileProvider(widget.userId));
            },
            child: Text('common.tryAgain'.tr()),
          ),
        ],
      ),
    );
  }
}
