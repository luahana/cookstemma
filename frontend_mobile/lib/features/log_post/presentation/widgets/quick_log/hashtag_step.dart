import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pairing_planet2_frontend/core/widgets/outcome/outcome_badge.dart';
import 'package:pairing_planet2_frontend/features/log_post/providers/quick_log_draft_provider.dart';
import 'package:pairing_planet2_frontend/features/recipe/presentation/widgets/hashtag_input_section.dart';

/// Hashtag input step - final step before submission
class HashtagStep extends ConsumerStatefulWidget {
  final QuickLogDraft draft;
  final VoidCallback onSubmit;

  const HashtagStep({
    super.key,
    required this.draft,
    required this.onSubmit,
  });

  @override
  ConsumerState<HashtagStep> createState() => _HashtagStepState();
}

class _HashtagStepState extends ConsumerState<HashtagStep> {
  final List<Map<String, dynamic>> _hashtags = [];

  @override
  void initState() {
    super.initState();
    // Convert string hashtags from draft to map format for HashtagInputSection
    for (final tag in widget.draft.hashtags) {
      _hashtags.add({
        'name': tag,
        'isOriginal': false,
        'isDeleted': false,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24.h),
      child: Column(
        children: [
          // Summary of what's been captured
          _DraftSummary(draft: widget.draft),
          SizedBox(height: 24.h),
          // Hashtag input
          Text(
            'logPost.quickLog.addHashtags'.tr(),
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'logPost.quickLog.hashtagsOptional'.tr(),
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 16.h),
          // Hashtag input section
          HashtagInputSection(
            hashtags: _hashtags,
            onHashtagsChanged: (tags) {
              setState(() {
                _hashtags.clear();
                _hashtags.addAll(tags);
              });
              // Extract active hashtag names for the provider
              final activeNames = tags
                  .where((h) => h['isDeleted'] != true)
                  .map((h) => h['name'] as String)
                  .toList();
              ref.read(quickLogDraftProvider.notifier).setHashtags(activeNames);
            },
          ),
          SizedBox(height: 24.h),
          // Action buttons
          Row(
            children: [
              TextButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  ref.read(quickLogDraftProvider.notifier).goBack();
                },
                icon: const Icon(Icons.arrow_back),
                label: Text('common.back'.tr()),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () {
                  HapticFeedback.heavyImpact();
                  widget.onSubmit();
                },
                icon: const Icon(Icons.check),
                label: Text('logPost.quickLog.saveLog'.tr()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Summary card with title header and horizontal content row
class _DraftSummary extends StatelessWidget {
  final QuickLogDraft draft;

  const _DraftSummary({required this.draft});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title at top (centered)
          if (draft.recipeTitle != null)
            Text(
              draft.recipeTitle!,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          SizedBox(height: 10.h),
          // Content row: [Emoji] [Photos] [Memo]
          Row(
            children: [
              // Outcome emoji (far left)
              if (draft.outcome != null)
                OutcomeBadge(
                  outcome: draft.outcome!,
                  variant: OutcomeBadgeVariant.compact,
                ),
              // Stacked photos (next to emoji)
              if (draft.photoPaths.isNotEmpty) ...[
                SizedBox(width: 10.w),
                _buildStackedPhotos(context),
              ],
              // Spacer to push memo to far right
              const Spacer(),
              // Memo (far right)
              if (draft.notes != null && draft.notes!.isNotEmpty)
                Flexible(
                  child: Text(
                    draft.notes!,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStackedPhotos(BuildContext context) {
    const photoSize = 48.0;
    const offset = 20.0;

    if (draft.photoPaths.isEmpty) {
      return Container(
        width: photoSize.w,
        height: photoSize.w,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(Icons.photo, color: Colors.grey[400], size: 24.sp),
      );
    }

    final totalWidth = photoSize + (draft.photoPaths.length - 1) * offset;

    return SizedBox(
      width: totalWidth.w,
      height: photoSize.w,
      child: Stack(
        children: draft.photoPaths.asMap().entries.map((entry) {
          final index = entry.key;
          final path = entry.value;
          return Positioned(
            left: (index * offset).w,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6.r),
                child: Builder(
                  builder: (context) {
                    final cacheSize = (photoSize * MediaQuery.devicePixelRatioOf(context)).toInt();
                    return Image.file(
                      File(path),
                      width: photoSize.w,
                      height: photoSize.w,
                      fit: BoxFit.cover,
                      cacheWidth: cacheSize,
                      cacheHeight: cacheSize,
                    );
                  },
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
