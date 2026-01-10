import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import '../../providers/recipe_providers.dart';

/// Action menu for recipe detail screen.
/// Shows Edit and Delete options only for recipe owner.
/// Options are disabled if recipe has variants or logs.
class RecipeActionMenu extends ConsumerWidget {
  final String recipePublicId;
  final VoidCallback? onDeleted;

  const RecipeActionMenu({
    super.key,
    required this.recipePublicId,
    this.onDeleted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modifiableAsync = ref.watch(recipeModifiableProvider(recipePublicId));

    return modifiableAsync.when(
      data: (modifiable) {
        // Only show menu if user is the owner
        if (!modifiable.isOwner) return const SizedBox.shrink();

        return PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) async {
            if (value == 'edit') {
              if (modifiable.canModify) {
                context.push(RouteConstants.recipeEditPath(recipePublicId));
              } else {
                _showBlockedDialog(context, modifiable.reason!);
              }
            } else if (value == 'delete') {
              if (modifiable.canModify) {
                _showDeleteConfirmDialog(context, ref);
              } else {
                _showBlockedDialog(context, modifiable.reason!);
              }
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(
                    Icons.edit_outlined,
                    color: modifiable.canModify
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    size: 20.sp,
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    'common.edit'.tr(),
                    style: TextStyle(
                      color: modifiable.canModify
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                  if (!modifiable.canModify) ...[
                    SizedBox(width: 8.w),
                    Icon(
                      Icons.lock_outline,
                      size: 16.sp,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(
                    Icons.delete_outline,
                    color: modifiable.canModify
                        ? AppColors.error
                        : AppColors.textSecondary,
                    size: 20.sp,
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    'common.delete'.tr(),
                    style: TextStyle(
                      color: modifiable.canModify
                          ? AppColors.error
                          : AppColors.textSecondary,
                    ),
                  ),
                  if (!modifiable.canModify) ...[
                    SizedBox(width: 8.w),
                    Icon(
                      Icons.lock_outline,
                      size: 16.sp,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  void _showBlockedDialog(BuildContext context, String reason) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('recipe.cannotModify'.tr()),
        content: Text(reason),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common.close'.tr()),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('recipe.deleteConfirmTitle'.tr()),
        content: Text('recipe.deleteConfirmMessage'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await ref
                  .read(recipeDeleteProvider.notifier)
                  .deleteRecipe(recipePublicId);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('recipe.deleted'.tr())),
                );
                onDeleted?.call();
                // Navigate back from detail screen
                context.pop();
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    );
  }
}
