import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pairing_planet2_frontend/core/theme/app_input_styles.dart';
import 'package:pairing_planet2_frontend/core/widgets/outcome/outcome_badge.dart';
import 'package:pairing_planet2_frontend/features/log_post/providers/quick_log_draft_provider.dart';

/// Notes input step with draft summary
class NotesStep extends ConsumerStatefulWidget {
  final QuickLogDraft draft;

  const NotesStep({super.key, required this.draft});

  @override
  ConsumerState<NotesStep> createState() => _NotesStepState();
}

class _NotesStepState extends ConsumerState<NotesStep> {
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.draft.notes);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
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
          // Notes input
          Text(
            'logPost.quickLog.addNotes'.tr(),
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'logPost.quickLog.notesOptional'.tr(),
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 16.h),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: AppInputStyles.editableInputDecoration(
              hintText: 'logPost.quickLog.notesHint'.tr(),
            ),
            onChanged: (value) {
              ref.read(quickLogDraftProvider.notifier).updateNotes(value);
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
                  HapticFeedback.mediumImpact();
                  ref.read(quickLogDraftProvider.notifier).setNotes(_notesController.text);
                },
                icon: const Icon(Icons.arrow_forward),
                label: Text('common.continue'.tr()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Summary card showing draft progress (photo thumbnail + outcome)
class _DraftSummary extends StatelessWidget {
  final QuickLogDraft draft;

  const _DraftSummary({required this.draft});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Photo thumbnail (first photo)
          if (draft.photoPaths.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: Builder(
                builder: (context) {
                  // Use cacheWidth/cacheHeight to reduce memory footprint
                  // Display is 60x60, multiply by devicePixelRatio
                  final cacheSize = (60 * MediaQuery.devicePixelRatioOf(context)).toInt();
                  return Image.file(
                    File(draft.photoPaths.first),
                    width: 60.w,
                    height: 60.w,
                    fit: BoxFit.cover,
                    cacheWidth: cacheSize,
                    cacheHeight: cacheSize,
                  );
                },
              ),
            )
          else
            Container(
              width: 60.w,
              height: 60.w,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(Icons.photo, color: Colors.grey[400]),
            ),
          SizedBox(width: 16.w),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (draft.outcome != null)
                  OutcomeBadge(
                    outcome: draft.outcome!,
                    variant: OutcomeBadgeVariant.compact,
                  ),
                SizedBox(height: 4.h),
                if (draft.recipeTitle != null)
                  Text(
                    draft.recipeTitle!,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
