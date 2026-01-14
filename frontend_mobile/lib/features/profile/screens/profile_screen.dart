import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:nested_scroll_view_plus/nested_scroll_view_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/core/providers/scroll_to_top_provider.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/core/widgets/app_logo.dart';
import 'package:pairing_planet2_frontend/features/auth/providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/cooking_dna_provider.dart';
import '../widgets/cooking_dna_header.dart';
import '../widgets/profile_shared.dart';
import '../widgets/tabs/my_recipes_tab.dart';
import '../widgets/tabs/my_logs_tab.dart';
import '../widgets/tabs/saved_tab.dart';

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
    try {
      if (_scrollController.hasClients &&
          _scrollController.positions.isNotEmpty &&
          _scrollController.position.hasPixels) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (_) {
      // Ignore scroll errors when position is not ready
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
    if (authStatus == AuthStatus.guest ||
        authStatus == AuthStatus.unauthenticated) {
      return _buildGuestView(context);
    }

    final profileAsync = ref.watch(myProfileProvider);
    final cookingDnaState = ref.watch(cookingDnaProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: profileAsync.when(
        data: (profile) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(myProfileProvider);
            ref.invalidate(cookingDnaProvider);
            ref.invalidate(myRecipesProvider);
            ref.invalidate(myLogsProvider);
            ref.invalidate(savedRecipesProvider);
            ref.invalidate(savedLogsProvider);
          },
          child: NestedScrollViewPlus(
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
              // Header content
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
                delegate: StickyTabBarDelegate(
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
                MyRecipesTab(key: PageStorageKey<String>('my_recipes')),
                MyLogsTab(key: PageStorageKey<String>('my_logs')),
                SavedTab(key: PageStorageKey<String>('saved')),
              ],
            ),
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
              Text(
                'guest.profileTitle'.tr(),
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12.h),
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
