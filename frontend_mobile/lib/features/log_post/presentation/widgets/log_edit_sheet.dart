import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pairing_planet2_frontend/core/providers/image_providers.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/core/theme/app_input_styles.dart';
import 'package:pairing_planet2_frontend/core/widgets/image_source_sheet.dart';
import 'package:pairing_planet2_frontend/core/widgets/reorderable_image_picker.dart';
import 'package:pairing_planet2_frontend/domain/entities/log_post/log_post_detail.dart';
import 'package:pairing_planet2_frontend/core/widgets/outcome/outcome_badge.dart';
import 'package:pairing_planet2_frontend/features/log_post/presentation/widgets/outcome_selector.dart';
import 'package:pairing_planet2_frontend/features/log_post/providers/log_post_providers.dart';
import 'package:pairing_planet2_frontend/features/recipe/presentation/widgets/hashtag_input_section.dart';
import 'package:pairing_planet2_frontend/shared/data/model/upload_item_model.dart';

class LogEditSheet extends ConsumerStatefulWidget {
  final LogPostDetail log;
  final VoidCallback onSuccess;

  const LogEditSheet({
    super.key,
    required this.log,
    required this.onSuccess,
  });

  static Future<void> show({
    required BuildContext context,
    required LogPostDetail log,
    required VoidCallback onSuccess,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => LogEditSheet(log: log, onSuccess: onSuccess),
    );
  }

  @override
  ConsumerState<LogEditSheet> createState() => _LogEditSheetState();
}

class _LogEditSheetState extends ConsumerState<LogEditSheet> {
  late TextEditingController _contentController;
  late LogOutcome _selectedOutcome;
  late List<Map<String, dynamic>> _hashtags;
  late List<UploadItem> _images;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.log.content);
    _selectedOutcome = LogOutcome.fromString(widget.log.outcome) ?? LogOutcome.partial;
    _hashtags = widget.log.hashtags.map((h) => {
      'name': h.name,
      'isOriginal': false,
      'isDeleted': false,
    }).toList();

    // Initialize images from existing log
    _images = widget.log.images
        .where((img) => img.url != null && img.publicId.isNotEmpty)
        .map((img) => UploadItem.fromRemote(
              url: img.url!,
              publicId: img.publicId,
            ))
        .toList();
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_images.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('logPost.maxPhotosError'.tr())),
      );
      return;
    }
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      imageQuality: 70,
    );
    if (image != null) {
      final newItem = UploadItem.fromFile(File(image.path));
      setState(() => _images.add(newItem));
      _handleImageUpload(newItem);
    }
  }

  Future<void> _handleImageUpload(UploadItem item) async {
    setState(() => item.status = UploadStatus.uploading);
    final result = await ref
        .read(uploadImageWithTrackingUseCaseProvider)
        .execute(file: item.file!, type: "LOG_POST");
    result.fold(
      (f) => setState(() => item.status = UploadStatus.error),
      (res) {
        setState(() {
          item.status = UploadStatus.success;
          item.publicId = res.imagePublicId;
        });
      },
    );
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  void _reorderImages(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _images.removeAt(oldIndex);
      _images.insert(newIndex, item);
    });
  }

  /// Check if any images are currently uploading
  bool get _hasUploadingImages {
    return _images.any((img) => img.status == UploadStatus.uploading);
  }

  /// Check if any images have upload errors
  bool get _hasUploadErrors {
    return _images.any((img) => img.status == UploadStatus.error);
  }

  /// Get counts for status display
  (int uploading, int errors) get _uploadStatusCounts {
    int uploading = 0;
    int errors = 0;
    for (final img in _images) {
      if (img.status == UploadStatus.uploading) uploading++;
      if (img.status == UploadStatus.error) errors++;
    }
    return (uploading, errors);
  }

  Widget _buildUploadStatusBanner() {
    final (uploading, errors) = _uploadStatusCounts;
    if (uploading == 0 && errors == 0) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: errors > 0 ? Colors.red[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: errors > 0 ? Colors.red[200]! : Colors.orange[200]!,
        ),
      ),
      child: Row(
        children: [
          if (uploading > 0) ...[
            SizedBox(
              width: 16.w,
              height: 16.w,
              child: const CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                'logPost.uploadingPhotos'.tr(namedArgs: {'count': '$uploading'}),
                style: TextStyle(fontSize: 13.sp),
              ),
            ),
          ] else if (errors > 0) ...[
            Icon(Icons.error_outline, color: Colors.red, size: 18.sp),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                'logPost.uploadFailed'.tr(namedArgs: {'count': '$errors'}),
                style: TextStyle(color: Colors.red[700], fontSize: 13.sp),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('logPost.memoHint'.tr())),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Collect image public IDs (only successfully uploaded ones)
    final imagePublicIds = _images
        .where((img) => img.status == UploadStatus.success && img.publicId != null)
        .map((img) => img.publicId!)
        .toList();

    final hashtagNames = _hashtags
        .where((h) => h['isDeleted'] != true)
        .map((h) => h['name'] as String)
        .toList();

    final repository = ref.read(logPostRepositoryProvider);
    final result = await repository.updateLog(
      widget.log.publicId,
      content: _contentController.text.trim(),
      outcome: _selectedOutcome.value,
      hashtags: hashtagNames.isEmpty ? null : hashtagNames,
      imagePublicIds: imagePublicIds,
    );

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('logPost.updateFailed'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      },
      (_) {
        // Invalidate the detail provider to refresh
        ref.invalidate(logPostDetailProvider(widget.log.publicId));
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('logPost.updateSuccess'.tr()),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSuccess();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.fromLTRB(20.w, 12.h, 8.w, 12.h),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Row(
                children: [
                  Text(
                    'logPost.edit'.tr(),
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: EdgeInsets.all(20.r),
                children: [
                  // Image picker section
                  Row(
                    children: [
                      Icon(Icons.photo_library, color: AppColors.primary, size: 20.sp),
                      SizedBox(width: 8.w),
                      Text(
                        'logPost.photosMax'.tr(),
                        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  ReorderableImagePicker(
                    images: _images,
                    maxImages: 3,
                    onReorder: _reorderImages,
                    onRemove: _removeImage,
                    onRetry: _handleImageUpload,
                    onAdd: () => ImageSourceSheet.show(
                      context: context,
                      onSourceSelected: _pickImage,
                    ),
                    showThumbnailBadge: false,
                  ),
                  SizedBox(height: 24.h),

                  // Outcome selector
                  Row(
                    children: [
                      Icon(Icons.emoji_emotions, color: AppColors.primary, size: 20.sp),
                      SizedBox(width: 8.w),
                      Text(
                        'logPost.outcome'.tr(),
                        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  CompactOutcomeSelector(
                    selectedOutcome: _selectedOutcome,
                    onOutcomeSelected: (outcome) {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedOutcome = outcome);
                    },
                  ),
                  SizedBox(height: 24.h),

                  // Content text field
                  Row(
                    children: [
                      Icon(Icons.edit_note, color: AppColors.primary, size: 20.sp),
                      SizedBox(width: 8.w),
                      Text(
                        'logPost.memo'.tr(),
                        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Container(
                    padding: EdgeInsets.all(16.r),
                    decoration: AppInputStyles.editableBoxDecoration,
                    child: TextField(
                      controller: _contentController,
                      maxLines: 5,
                      minLines: 3,
                      decoration: InputDecoration(
                        hintText: 'logPost.contentHint'.tr(),
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: TextStyle(fontSize: 15.sp, height: 1.5),
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Hashtags
                  HashtagInputSection(
                    hashtags: _hashtags,
                    onHashtagsChanged: (tags) {
                      setState(() => _hashtags = tags);
                    },
                  ),
                  SizedBox(height: 32.h),
                ],
              ),
            ),
            // Save button
            Container(
              padding: EdgeInsets.fromLTRB(
                20.w,
                12.h,
                20.w,
                12.h + MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildUploadStatusBanner(),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: (_isLoading || _hasUploadingImages || _hasUploadErrors)
                          ? null
                          : _saveChanges,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 20.w,
                              height: 20.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'common.save'.tr(),
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
