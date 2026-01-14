import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pairing_planet2_frontend/core/services/media_service.dart';
import 'package:pairing_planet2_frontend/core/widgets/image_source_sheet.dart';
import 'package:pairing_planet2_frontend/core/widgets/outcome/outcome_badge.dart';
import 'package:pairing_planet2_frontend/core/widgets/reorderable_image_picker.dart';
import 'package:pairing_planet2_frontend/features/log_post/providers/quick_log_draft_provider.dart';
import 'package:pairing_planet2_frontend/shared/data/model/upload_item_model.dart';

/// Photo capture step with reorderable grid
class PhotoStep extends ConsumerWidget {
  final QuickLogDraft draft;

  const PhotoStep({super.key, required this.draft});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24.h),
      child: Column(
        children: [
          // Preview summary (styled container matching other steps)
          Container(
            margin: EdgeInsets.only(bottom: 16.h),
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
                // Emoji at far left
                Row(
                  children: [
                    if (draft.outcome != null)
                      OutcomeBadge(
                        outcome: draft.outcome!,
                        variant: OutcomeBadgeVariant.compact,
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Reorderable photo grid
          ReorderableImagePicker(
            images: _photoPathsToUploadItems(draft.photoPaths),
            maxImages: 3,
            onReorder: (oldIndex, newIndex) {
              HapticFeedback.selectionClick();
              ref.read(quickLogDraftProvider.notifier).reorderPhotos(oldIndex, newIndex);
            },
            onRemove: (index) {
              HapticFeedback.lightImpact();
              ref.read(quickLogDraftProvider.notifier).removePhoto(index);
            },
            onRetry: (_) {}, // No upload retry needed - local files only
            onAdd: () {
              HapticFeedback.selectionClick();
              ImageSourceSheet.show(
                context: context,
                onSourceSelected: (source) => _pickImage(source, ref),
              );
            },
            showThumbnailBadge: true,
          ),
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

  Future<void> _pickImage(ImageSource source, WidgetRef ref) async {
    final mediaService = MediaService();
    final photo = source == ImageSource.camera
        ? await mediaService.takePhoto()
        : await mediaService.pickImage();
    if (photo != null) {
      ref.read(quickLogDraftProvider.notifier).addPhoto(photo.path);
    }
  }

  /// Convert photo paths to UploadItem for ReorderableImagePicker compatibility.
  List<UploadItem> _photoPathsToUploadItems(List<String> photoPaths) {
    return photoPaths.map((path) => UploadItem(file: File(path))).toList();
  }
}
