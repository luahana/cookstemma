import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pairing_planet2_frontend/data/models/follow/follower_dto.dart';
import 'package:pairing_planet2_frontend/features/profile/providers/follow_provider.dart';
import 'package:pairing_planet2_frontend/features/profile/widgets/follow_button.dart';

class FollowersListScreen extends ConsumerStatefulWidget {
  final String userId;
  final int initialTabIndex;

  const FollowersListScreen({
    super.key,
    required this.userId,
    this.initialTabIndex = 0,
  });

  @override
  ConsumerState<FollowersListScreen> createState() => _FollowersListScreenState();
}

class _FollowersListScreenState extends ConsumerState<FollowersListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('팔로워 / 팔로잉'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '팔로워'),
            Tab(text: '팔로잉'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _FollowersTab(userId: widget.userId),
          _FollowingTab(userId: widget.userId),
        ],
      ),
    );
  }
}

class _FollowersTab extends ConsumerWidget {
  final String userId;

  const _FollowersTab({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(followersListProvider(userId));
    final notifier = ref.read(followersListProvider(userId).notifier);

    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.items.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => notifier.refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: 200.h),
            Center(
              child: Column(
                children: [
                  Text('오류가 발생했습니다', style: TextStyle(fontSize: 16.sp)),
                  SizedBox(height: 8.h),
                  ElevatedButton(
                    onPressed: () => notifier.refresh(),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (state.items.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => notifier.refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: 200.h),
            Center(
              child: Column(
                children: [
                  Icon(Icons.people_outline, size: 64.sp, color: Colors.grey[400]),
                  SizedBox(height: 16.h),
                  Text(
                    '아직 팔로워가 없습니다',
                    style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => notifier.refresh(),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollEndNotification) {
            final metrics = notification.metrics;
            if (metrics.pixels >= metrics.maxScrollExtent * 0.8) {
              notifier.fetchNextPage();
            }
          }
          return false;
        },
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: state.items.length + (state.isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= state.items.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final follower = state.items[index];
            return _FollowerListItem(follower: follower);
          },
        ),
      ),
    );
  }
}

class _FollowingTab extends ConsumerWidget {
  final String userId;

  const _FollowingTab({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(followingListProvider(userId));
    final notifier = ref.read(followingListProvider(userId).notifier);

    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.items.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => notifier.refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: 200.h),
            Center(
              child: Column(
                children: [
                  Text('오류가 발생했습니다', style: TextStyle(fontSize: 16.sp)),
                  SizedBox(height: 8.h),
                  ElevatedButton(
                    onPressed: () => notifier.refresh(),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (state.items.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => notifier.refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: 200.h),
            Center(
              child: Column(
                children: [
                  Icon(Icons.person_add_outlined, size: 64.sp, color: Colors.grey[400]),
                  SizedBox(height: 16.h),
                  Text(
                    '아직 팔로잉하는 유저가 없습니다',
                    style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => notifier.refresh(),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollEndNotification) {
            final metrics = notification.metrics;
            if (metrics.pixels >= metrics.maxScrollExtent * 0.8) {
              notifier.fetchNextPage();
            }
          }
          return false;
        },
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: state.items.length + (state.isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= state.items.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final following = state.items[index];
            return _FollowerListItem(follower: following, showFollowBack: false);
          },
        ),
      ),
    );
  }
}

class _FollowerListItem extends StatelessWidget {
  final FollowerDto follower;
  final bool showFollowBack;

  const _FollowerListItem({
    required this.follower,
    this.showFollowBack = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        radius: 24.r,
        backgroundImage: follower.profileImageUrl != null
            ? NetworkImage(follower.profileImageUrl!)
            : null,
        child: follower.profileImageUrl == null
            ? Icon(Icons.person, size: 24.sp)
            : null,
      ),
      title: Text(
        follower.username,
        style: TextStyle(
          fontSize: 15.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: FollowButtonCompact(
        userId: follower.publicId,
        initialIsFollowing: follower.isFollowingBack ?? false,
      ),
    );
  }
}
