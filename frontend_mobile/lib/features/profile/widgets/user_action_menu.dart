import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/features/profile/providers/block_provider.dart';
import 'package:pairing_planet2_frontend/features/profile/widgets/report_user_sheet.dart';

/// Action menu for user profile screen.
/// Shows Block and Report options for non-own profiles.
class UserActionMenu extends ConsumerWidget {
  final String userId;
  final VoidCallback? onBlocked;

  const UserActionMenu({
    super.key,
    required this.userId,
    this.onBlocked,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blockStatusAsync = ref.watch(blockStatusProvider(userId));

    return blockStatusAsync.when(
      data: (status) {
        return PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'block') {
              _showBlockConfirmDialog(context, ref, status.isBlocked);
            } else if (value == 'report') {
              ReportUserSheet.show(context, userId);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'block',
              child: Row(
                children: [
                  Icon(
                    status.isBlocked ? Icons.person_add : Icons.block,
                    color: status.isBlocked
                        ? AppColors.textPrimary
                        : AppColors.error,
                    size: 20.sp,
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    status.isBlocked
                        ? 'profile.unblock'.tr()
                        : 'profile.block'.tr(),
                    style: TextStyle(
                      color: status.isBlocked
                          ? AppColors.textPrimary
                          : AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'report',
              child: Row(
                children: [
                  Icon(
                    Icons.flag_outlined,
                    color: AppColors.textPrimary,
                    size: 20.sp,
                  ),
                  SizedBox(width: 12.w),
                  Text('profile.report'.tr()),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        onSelected: (value) {
          if (value == 'report') {
            ReportUserSheet.show(context, userId);
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'report',
            child: Row(
              children: [
                Icon(
                  Icons.flag_outlined,
                  color: AppColors.textPrimary,
                  size: 20.sp,
                ),
                SizedBox(width: 12.w),
                Text('profile.report'.tr()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showBlockConfirmDialog(
      BuildContext context, WidgetRef ref, bool isCurrentlyBlocked) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          isCurrentlyBlocked
              ? 'profile.unblockConfirmTitle'.tr()
              : 'profile.blockConfirmTitle'.tr(),
        ),
        content: Text(
          isCurrentlyBlocked
              ? 'profile.unblockConfirmMessage'.tr()
              : 'profile.blockConfirmMessage'.tr(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _toggleBlock(context, ref, isCurrentlyBlocked);
            },
            style: isCurrentlyBlocked
                ? null
                : TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(
              isCurrentlyBlocked
                  ? 'profile.unblock'.tr()
                  : 'profile.block'.tr(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleBlock(
      BuildContext context, WidgetRef ref, bool isCurrentlyBlocked) async {
    final blockStatus = await ref.read(blockStatusProvider(userId).future);
    final notifier = ref.read(blockActionProvider((
      userId: userId,
      isBlocked: blockStatus.isBlocked,
      amBlocked: blockStatus.amBlocked,
    )).notifier);

    final success = await notifier.toggleBlock();

    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isCurrentlyBlocked
                  ? 'profile.unblocked'.tr()
                  : 'profile.blocked'.tr(),
            ),
          ),
        );

        // Invalidate related providers
        ref.invalidate(blockStatusProvider(userId));

        // Refresh blocked users list so it shows the newly blocked user
        ref.invalidate(blockedUsersListProvider);

        // If blocked, navigate back
        if (!isCurrentlyBlocked) {
          onBlocked?.call();
          context.pop();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('common.error'.tr())),
        );
      }
    }
  }
}
