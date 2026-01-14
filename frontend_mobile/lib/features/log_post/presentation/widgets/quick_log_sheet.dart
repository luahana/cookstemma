import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/data/datasources/sync/log_sync_engine.dart';
import 'package:pairing_planet2_frontend/features/log_post/providers/quick_log_draft_provider.dart';
import 'package:pairing_planet2_frontend/features/log_post/presentation/widgets/quick_log/outcome_step.dart';
import 'package:pairing_planet2_frontend/features/log_post/presentation/widgets/quick_log/photo_step.dart';
import 'package:pairing_planet2_frontend/features/log_post/presentation/widgets/quick_log/notes_step.dart';
import 'package:pairing_planet2_frontend/features/log_post/presentation/widgets/quick_log/hashtag_step.dart';
import 'package:pairing_planet2_frontend/features/log_post/presentation/widgets/quick_log/result_states.dart';

/// Bottom sheet for quick log entry flow
/// Target: Complete log in under 10 seconds
class QuickLogSheet extends ConsumerStatefulWidget {
  const QuickLogSheet({super.key});

  /// Show the quick log sheet as a modal bottom sheet
  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const QuickLogSheet(),
    );
  }

  @override
  ConsumerState<QuickLogSheet> createState() => _QuickLogSheetState();
}

class _QuickLogSheetState extends ConsumerState<QuickLogSheet> {
  @override
  void initState() {
    super.initState();
    // Start the flow when sheet opens - recipe should already be pre-selected
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final draft = ref.read(quickLogDraftProvider);
      if (draft.step == QuickLogStep.idle) {
        ref.read(quickLogDraftProvider.notifier).startFlow();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(quickLogDraftProvider);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DragHandle(onTap: _handleClose),
              _ProgressIndicator(draft: draft),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: _buildContent(draft),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(QuickLogDraft draft) {
    switch (draft.step) {
      case QuickLogStep.idle:
      case QuickLogStep.selectingOutcome:
        return OutcomeStep(draft: draft);
      case QuickLogStep.capturingPhoto:
        return PhotoStep(draft: draft);
      case QuickLogStep.addingNotes:
        return NotesStep(draft: draft);
      case QuickLogStep.addingHashtags:
        return HashtagStep(draft: draft, onSubmit: _handleSubmit);
      case QuickLogStep.submitting:
        return const SubmittingState();
      case QuickLogStep.success:
        return const SuccessState();
      case QuickLogStep.error:
        return ErrorState(
          errorMessage: draft.errorMessage,
          onRetry: _handleSubmit,
        );
    }
  }

  void _handleSubmit() async {
    final draft = ref.read(quickLogDraftProvider);

    // Validate required fields
    if (draft.outcome == null || draft.photoPaths.isEmpty) {
      ref.read(quickLogDraftProvider.notifier).markError(
        'logPost.quickLog.missingRequired'.tr(),
      );
      return;
    }

    ref.read(quickLogDraftProvider.notifier).startSubmission();

    try {
      // Queue the log post for offline-first sync
      final syncQueue = ref.read(syncQueueRepositoryProvider);
      final queueItem = await syncQueue.queueLogPost(
        outcome: draft.outcome!.value,
        localPhotoPaths: draft.photoPaths,
        recipePublicId: draft.recipePublicId,
        title: draft.recipeTitle,
        content: draft.notes ?? '',
        hashtags: draft.hashtags.isNotEmpty ? draft.hashtags : null,
      );

      // Trigger immediate sync attempt
      ref.read(logSyncEngineProvider).triggerSync();

      // Mark as success with the created log's local ID
      if (mounted) {
        final localId = queueItem.localId ?? queueItem.id;
        ref.read(quickLogDraftProvider.notifier).markSuccess(localId);
      }
    } catch (e) {
      if (mounted) {
        ref.read(quickLogDraftProvider.notifier).markError(e.toString());
      }
    }
  }

  void _handleClose() {
    final draft = ref.read(quickLogDraftProvider);
    if (draft.isActive) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('logPost.quickLog.discardTitle'.tr()),
          content: Text('logPost.quickLog.discardMessage'.tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('common.cancel'.tr()),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                ref.read(quickLogDraftProvider.notifier).cancel();
                Navigator.of(this.context).pop();
              },
              child: Text('common.discard'.tr()),
            ),
          ],
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }
}

/// Drag handle for the sheet
class _DragHandle extends StatelessWidget {
  final VoidCallback onTap;

  const _DragHandle({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Center(
          child: Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
        ),
      ),
    );
  }
}

/// Progress indicator showing current step
class _ProgressIndicator extends StatelessWidget {
  final QuickLogDraft draft;

  const _ProgressIndicator({required this.draft});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
      child: Column(
        children: [
          Row(
            children: [
              _buildStepDot(1, draft.step.index >= QuickLogStep.selectingOutcome.index),
              Expanded(child: _buildStepLine(draft.step.index > QuickLogStep.selectingOutcome.index)),
              _buildStepDot(2, draft.step.index >= QuickLogStep.capturingPhoto.index),
              Expanded(child: _buildStepLine(draft.step.index > QuickLogStep.capturingPhoto.index)),
              _buildStepDot(3, draft.step.index >= QuickLogStep.addingNotes.index),
              Expanded(child: _buildStepLine(draft.step.index > QuickLogStep.addingNotes.index)),
              _buildStepDot(4, draft.step.index >= QuickLogStep.addingHashtags.index),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStepLabel('logPost.quickLog.step.outcome'.tr(), 1),
              _buildStepLabel('logPost.quickLog.step.photo'.tr(), 2),
              _buildStepLabel('logPost.quickLog.step.notes'.tr(), 3),
              _buildStepLabel('logPost.quickLog.step.hashtags'.tr(), 4),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepDot(int step, bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 24.w,
      height: 24.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? AppColors.primary : Colors.grey[200],
        border: Border.all(
          color: isActive ? AppColors.primary : Colors.grey[300]!,
          width: 2,
        ),
      ),
      child: Center(
        child: isActive
            ? Icon(Icons.check, size: 14.sp, color: Colors.white)
            : Text(
                '$step',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[500],
                ),
              ),
      ),
    );
  }

  Widget _buildStepLine(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 2.h,
      color: isActive ? AppColors.primary : Colors.grey[200],
    );
  }

  Widget _buildStepLabel(String label, int step) {
    final stepIndex = step + QuickLogStep.idle.index;
    final isActive = draft.step.index >= stepIndex;

    return Text(
      label,
      style: TextStyle(
        fontSize: 10.sp,
        fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
        color: isActive ? AppColors.primary : Colors.grey[500],
      ),
    );
  }
}
