import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/data/models/block/blocked_user_dto.dart';
import 'package:pairing_planet2_frontend/features/profile/providers/block_provider.dart';

/// Screen showing list of blocked users
class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(blockedUsersListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('profile.blockedUsers'.tr()),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[50],
      body: _buildBody(context, ref, state),
    );
  }

  Widget _buildBody(
      BuildContext context, WidgetRef ref, BlockedUsersListState state) {
    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48.sp, color: Colors.grey),
            SizedBox(height: 16.h),
            Text('common.error'.tr()),
            SizedBox(height: 8.h),
            ElevatedButton(
              onPressed: () => ref.read(blockedUsersListProvider.notifier).refresh(),
              child: Text('common.retry'.tr()),
            ),
          ],
        ),
      );
    }

    if (state.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.block, size: 64.sp, color: Colors.grey[300]),
            SizedBox(height: 16.h),
            Text(
              'profile.noBlockedUsers'.tr(),
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(blockedUsersListProvider.notifier).refresh();
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollEndNotification) {
            if (notification.metrics.extentAfter < 200) {
              ref.read(blockedUsersListProvider.notifier).fetchNextPage();
            }
          }
          return false;
        },
        child: ListView.builder(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          itemCount: state.items.length + (state.hasNext ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == state.items.length) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(16.r),
                  child: const CircularProgressIndicator(),
                ),
              );
            }
            return _buildBlockedUserTile(context, ref, state.items[index]);
          },
        ),
      ),
    );
  }

  Widget _buildBlockedUserTile(
      BuildContext context, WidgetRef ref, BlockedUserDto user) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 24.r,
          backgroundColor: user.profileImageUrl == null
              ? AppColors.primaryLight
              : Colors.grey[200],
          backgroundImage: user.profileImageUrl != null
              ? NetworkImage(user.profileImageUrl!)
              : null,
          child: user.profileImageUrl == null
              ? Text(
                  user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                )
              : null,
        ),
        title: Text(
          user.username,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: TextButton(
          onPressed: () => _showUnblockConfirmDialog(context, ref, user),
          child: Text(
            'profile.unblock'.tr(),
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 13.sp,
            ),
          ),
        ),
        onTap: () {
          context.push(RouteConstants.userProfilePath(user.publicId));
        },
      ),
    );
  }

  void _showUnblockConfirmDialog(
      BuildContext context, WidgetRef ref, BlockedUserDto user) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('profile.unblockConfirmTitle'.tr()),
        content: Text('profile.unblockConfirmMessage'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _unblockUser(context, ref, user);
            },
            child: Text('profile.unblock'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _unblockUser(
      BuildContext context, WidgetRef ref, BlockedUserDto user) async {
    try {
      final dataSource = ref.read(blockRemoteDataSourceProvider);
      await dataSource.unblockUser(user.publicId);

      ref.read(blockedUsersListProvider.notifier).removeBlockedUser(user.publicId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('profile.unblocked'.tr())),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('common.error'.tr())),
        );
      }
    }
  }
}
