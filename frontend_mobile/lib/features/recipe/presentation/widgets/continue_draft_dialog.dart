import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_draft.dart';

/// A dialog that asks the user whether to continue editing an existing draft
/// or start fresh.
class ContinueDraftDialog extends StatelessWidget {
  final RecipeDraft draft;
  final VoidCallback onContinue;
  final VoidCallback onDiscard;

  const ContinueDraftDialog({
    super.key,
    required this.draft,
    required this.onContinue,
    required this.onDiscard,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      title: Text(
        'draft.continueTitle'.tr(),
        style: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'draft.continueMessage'.tr(),
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 16.h),
          // Draft preview
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Draft title
                Text(
                  draft.title.isNotEmpty
                      ? draft.title
                      : 'draft.untitled'.tr(),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                // Last modified time
                Text(
                  _formatLastModified(draft.updatedAt),
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 8.h),
                // Draft stats
                Row(
                  children: [
                    _buildStatChip(
                      Icons.restaurant_menu,
                      '${draft.ingredients.length}',
                    ),
                    SizedBox(width: 8.w),
                    _buildStatChip(
                      Icons.format_list_numbered,
                      '${draft.steps.length}',
                    ),
                    SizedBox(width: 8.w),
                    _buildStatChip(
                      Icons.photo_library,
                      '${draft.images.length}',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onDiscard,
          child: Text(
            'draft.startFresh'.tr(),
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[600],
            ),
          ),
        ),
        ElevatedButton(
          onPressed: onContinue,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          child: Text(
            'draft.continue'.tr(),
            style: TextStyle(fontSize: 14.sp),
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip(IconData icon, String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4.r),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.w, color: Colors.grey[600]),
          SizedBox(width: 4.w),
          Text(
            value,
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  String _formatLastModified(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'draft.justNow'.tr();
    } else if (difference.inMinutes < 60) {
      return 'draft.minutesAgo'.tr(args: ['${difference.inMinutes}']);
    } else if (difference.inHours < 24) {
      return 'draft.hoursAgo'.tr(args: ['${difference.inHours}']);
    } else {
      return 'draft.daysAgo'.tr(args: ['${difference.inDays}']);
    }
  }
}
