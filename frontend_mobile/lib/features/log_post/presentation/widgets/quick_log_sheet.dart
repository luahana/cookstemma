import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/core/services/media_service.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/core/widgets/image_source_sheet.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pairing_planet2_frontend/features/log_post/presentation/widgets/outcome_badge.dart';
import 'package:pairing_planet2_frontend/features/log_post/providers/quick_log_draft_provider.dart';
import 'package:pairing_planet2_frontend/features/recipe/presentation/widgets/hashtag_input_section.dart';
import 'package:pairing_planet2_frontend/data/datasources/sync/log_sync_engine.dart';
import 'package:pairing_planet2_frontend/features/profile/providers/profile_provider.dart';

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
  final MediaService _mediaService = MediaService();
  final TextEditingController _notesController = TextEditingController();
  final List<String> _hashtags = [];

  @override
  void initState() {
    super.initState();
    // Start the flow when sheet opens - recipe should already be pre-selected
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Note: Recipe must be set via startFlowWithRecipe() before showing this sheet
      final draft = ref.read(quickLogDraftProvider);
      if (draft.step == QuickLogStep.idle) {
        ref.read(quickLogDraftProvider.notifier).startFlow();
      }
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
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
              // Drag handle
              _buildDragHandle(),
              // Progress indicator
              _buildProgressIndicator(draft),
              // Content based on current step
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

  Widget _buildDragHandle() {
    return GestureDetector(
      onTap: () => _handleClose(),
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

  Widget _buildProgressIndicator(QuickLogDraft draft) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
      child: Column(
        children: [
          // Step indicators: Outcome → Photo → Notes → Hashtags
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
          // Step labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStepLabel('logPost.quickLog.step.outcome'.tr(), 1, draft),
              _buildStepLabel('logPost.quickLog.step.photo'.tr(), 2, draft),
              _buildStepLabel('logPost.quickLog.step.notes'.tr(), 3, draft),
              _buildStepLabel('logPost.quickLog.step.hashtags'.tr(), 4, draft),
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

  Widget _buildStepLabel(String label, int step, QuickLogDraft draft) {
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

  Widget _buildContent(QuickLogDraft draft) {
    switch (draft.step) {
      case QuickLogStep.idle:
      case QuickLogStep.selectingOutcome:
        return _buildOutcomeStep(draft);
      case QuickLogStep.capturingPhoto:
        return _buildPhotoStep(draft);
      case QuickLogStep.addingNotes:
        return _buildNotesStep(draft);
      case QuickLogStep.addingHashtags:
        return _buildHashtagStep(draft);
      case QuickLogStep.submitting:
        return _buildSubmittingState();
      case QuickLogStep.success:
        return _buildSuccessState();
      case QuickLogStep.error:
        return _buildErrorState(draft);
    }
  }

  Widget _buildOutcomeStep(QuickLogDraft draft) {
    // Outcome buttons positioned at bottom for easy thumb access
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height * 0.35,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header at top
          Padding(
            padding: EdgeInsets.only(top: 24.h),
            child: Column(
              children: [
                Text(
                  'logPost.quickLog.howDidItGo'.tr(),
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.h),
                Text(
                  'logPost.quickLog.tapToSelect'.tr(),
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          // Buttons at bottom - large touch targets for cooking mode
          Padding(
            padding: EdgeInsets.only(bottom: 24.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: LogOutcome.values.map((outcome) {
                final isSelected = draft.outcome == outcome;
                return _buildLargeOutcomeButton(outcome, isSelected);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLargeOutcomeButton(LogOutcome outcome, bool isSelected) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        ref.read(quickLogDraftProvider.notifier).selectOutcome(outcome);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 100.w,
        height: 100.w, // 64pt minimum + extra for content
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
        decoration: BoxDecoration(
          color: isSelected
              ? outcome.primaryColor
              : outcome.backgroundColor,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected
                ? outcome.primaryColor
                : outcome.primaryColor.withValues(alpha: 0.3),
            width: isSelected ? 3 : 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: outcome.primaryColor.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: Offset(0, 4.h),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: Offset(0, 2.h),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              outcome.emoji,
              style: TextStyle(fontSize: 36.sp),
            ),
            SizedBox(height: 4.h),
            Text(
              outcome.label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : outcome.primaryColor,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoStep(QuickLogDraft draft) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24.h),
      child: Column(
        children: [
          // Selected outcome badge
          if (draft.outcome != null)
            Padding(
              padding: EdgeInsets.only(bottom: 16.h),
              child: OutcomeBadge(
                outcome: draft.outcome!,
                variant: OutcomeBadgeVariant.full,
              ),
            ),
          // Header
          Text(
            'logPost.quickLog.captureEvidence'.tr(),
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            'logPost.photosMax'.tr(),
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          // Reorderable photo grid
          _buildPhotoGrid(draft.photoPaths),
          SizedBox(height: 24.h),
          // Navigation buttons
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
              // Continue button - only enabled if at least 1 photo
              if (draft.photoPaths.isNotEmpty)
                FilledButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    ref.read(quickLogDraftProvider.notifier).proceedToNotes();
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

  Widget _buildPhotoGrid(List<String> photoPaths) {
    const maxPhotos = 3;
    final canAddMore = photoPaths.length < maxPhotos;

    return SizedBox(
      height: 110.h,
      child: ReorderableListView.builder(
        scrollDirection: Axis.horizontal,
        buildDefaultDragHandles: false,
        itemCount: photoPaths.length + (canAddMore ? 1 : 0),
        onReorder: (oldIndex, newIndex) {
          // Don't allow reordering the add button
          if (oldIndex >= photoPaths.length) return;
          if (newIndex > photoPaths.length) {
            newIndex = photoPaths.length;
          }
          HapticFeedback.selectionClick();
          ref.read(quickLogDraftProvider.notifier).reorderPhotos(oldIndex, newIndex);
        },
        itemBuilder: (context, index) {
          // Add button
          if (index == photoPaths.length) {
            return Padding(
              key: const ValueKey('add_button'),
              padding: EdgeInsets.only(top: 10.h),
              child: _buildAddPhotoButton(),
            );
          }
          // Photo thumbnail
          return _buildPhotoThumbnail(photoPaths[index], index);
        },
      ),
    );
  }

  Widget _buildAddPhotoButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        ImageSourceSheet.show(
          context: context,
          onSourceSelected: _pickImage,
        );
      },
      child: Container(
        width: 100.w,
        margin: EdgeInsets.only(right: 12.w),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo, color: Colors.grey[600], size: 28.sp),
            SizedBox(height: 4.h),
            Text(
              'logPost.quickLog.takePhoto'.tr(),
              style: TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoThumbnail(String photoPath, int index) {
    final bool isThumbnail = index == 0;

    return ReorderableDragStartListener(
      key: ValueKey('photo_$index'),
      index: index,
      child: SizedBox(
        width: 112.w,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Image container
            Padding(
              padding: EdgeInsets.only(top: 10.h, right: 12.w),
              child: Container(
                width: 100.w,
                height: 100.w,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12.r),
                  border: isThumbnail
                      ? Border.all(color: AppColors.primary, width: 2)
                      : null,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(isThumbnail ? 10.r : 12.r),
                  child: Image.file(
                    File(photoPath),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            // Thumbnail badge (first photo)
            if (isThumbnail)
              Positioned(
                top: 0,
                left: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    'recipe.hook.thumbnail'.tr(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            // Remove button
            Positioned(
              top: 2.h,
              right: 4.w,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  ref.read(quickLogDraftProvider.notifier).removePhoto(index);
                },
                child: Container(
                  padding: EdgeInsets.all(4.r),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close, color: Colors.white, size: 14.sp),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final photo = source == ImageSource.camera
        ? await _mediaService.takePhoto()
        : await _mediaService.pickImage();
    if (photo != null) {
      ref.read(quickLogDraftProvider.notifier).addPhoto(photo.path);
    }
  }

  Widget _buildHashtagStep(QuickLogDraft draft) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24.h),
      child: Column(
        children: [
          // Summary of what's been captured
          _buildDraftSummary(draft),
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
              ref.read(quickLogDraftProvider.notifier).setHashtags(tags);
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
                  _handleSubmit();
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

  Widget _buildNotesStep(QuickLogDraft draft) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24.h),
      child: Column(
        children: [
          // Summary of what's been captured
          _buildDraftSummary(draft),
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
            decoration: InputDecoration(
              hintText: 'logPost.quickLog.notesHint'.tr(),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              contentPadding: EdgeInsets.all(16.r),
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
                  // Save notes and go to hashtags step
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

  Widget _buildDraftSummary(QuickLogDraft draft) {
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
              child: Image.file(
                File(draft.photoPaths.first),
                width: 60.w,
                height: 60.w,
                fit: BoxFit.cover,
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

  Widget _buildSubmittingState() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 48.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          SizedBox(height: 24.h),
          Text(
            'logPost.quickLog.saving'.tr(),
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState() {
    final draft = ref.watch(quickLogDraftProvider);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Success icon
          Container(
            width: 64.w,
            height: 64.w,
            decoration: BoxDecoration(
              color: Colors.green[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle,
              size: 40.sp,
              color: Colors.green[600],
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'logPost.quickLog.logged'.tr(),
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 24.h),

          // Preview card showing what was logged
          _buildLogPreviewCard(draft),

          SizedBox(height: 16.h),
          Text(
            'logPost.quickLog.syncingBackground'.tr(),
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24.h),

          // Updated buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  ref.read(quickLogDraftProvider.notifier).reset();
                  Navigator.of(context).pop(true);
                },
                child: Text('common.done'.tr()),
              ),
              SizedBox(width: 16.w),
              FilledButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  ref.read(quickLogDraftProvider.notifier).reset();
                  Navigator.of(context).pop(true);
                  // Invalidate profile to refresh stats
                  ref.invalidate(myProfileProvider);
                  // Navigate to Profile with My Logs tab (index 1)
                  context.go('${RouteConstants.profile}?tab=1');
                },
                icon: const Icon(Icons.visibility),
                label: Text('logPost.quickLog.viewLogs'.tr()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Preview card showing what was logged for immediate user feedback
  Widget _buildLogPreviewCard(QuickLogDraft draft) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Photo thumbnail
          if (draft.photoPaths.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: Image.file(
                File(draft.photoPaths.first),
                width: 80.w,
                height: 80.w,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(Icons.photo, color: Colors.grey[400]),
            ),
          SizedBox(width: 16.w),
          // Log info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (draft.outcome != null)
                  OutcomeBadge(
                    outcome: draft.outcome!,
                    variant: OutcomeBadgeVariant.compact,
                  ),
                SizedBox(height: 8.h),
                if (draft.recipeTitle != null)
                  Text(
                    draft.recipeTitle!,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (draft.notes != null && draft.notes!.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 4.h),
                    child: Text(
                      draft.notes!,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(QuickLogDraft draft) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 32.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 48.sp,
            color: Colors.red[400],
          ),
          SizedBox(height: 16.h),
          Text(
            'logPost.quickLog.error'.tr(),
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            draft.errorMessage ?? 'Unknown error',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  ref.read(quickLogDraftProvider.notifier).goBack();
                },
                child: Text('common.back'.tr()),
              ),
              SizedBox(width: 16.w),
              FilledButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  _handleSubmit();
                },
                child: Text('common.tryAgain'.tr()),
              ),
            ],
          ),
        ],
      ),
    );
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
      await syncQueue.queueLogPost(
        outcome: draft.outcome!.value,
        localPhotoPaths: draft.photoPaths,
        recipePublicId: draft.recipePublicId,
        title: draft.recipeTitle,
        content: draft.notes ?? '',
        hashtags: draft.hashtags.isNotEmpty ? draft.hashtags : null,
      );

      // Trigger immediate sync attempt
      ref.read(logSyncEngineProvider).triggerSync();

      // Mark as success (item is queued, will sync in background)
      if (mounted) {
        ref.read(quickLogDraftProvider.notifier).markSuccess();
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
      // Confirm before closing if there's progress
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
