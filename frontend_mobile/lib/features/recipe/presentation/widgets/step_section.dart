import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pairing_planet2_frontend/core/config/platform_url_resolver.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/core/theme/app_input_styles.dart';
import 'package:pairing_planet2_frontend/core/widgets/image_source_sheet.dart';
import 'package:pairing_planet2_frontend/shared/data/model/upload_item_model.dart';
import '../../../../core/providers/image_providers.dart';
import 'minimal_header.dart';

class StepSection extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> steps;
  final VoidCallback onAddStep;
  final Function(List<File> images) onAddMultipleSteps;
  final Function(int) onRemoveStep;
  final Function(int) onRestoreStep;
  final Function(int, int) onReorder;
  final VoidCallback onStateChanged;

  const StepSection({
    super.key,
    required this.steps,
    required this.onAddStep,
    required this.onAddMultipleSteps,
    required this.onRemoveStep,
    required this.onRestoreStep,
    required this.onReorder,
    required this.onStateChanged,
  });

  @override
  ConsumerState<StepSection> createState() => _StepSectionState();
}

class _StepSectionState extends ConsumerState<StepSection> {
  static const int _maxBatchImages = 10;
  static const int _maxSteps = 12;

  @override
  void didUpdateWidget(StepSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trigger uploads for any pending items (batch-added images)
    _uploadPendingImages();
  }

  void _uploadPendingImages() {
    for (int i = 0; i < widget.steps.length; i++) {
      final step = widget.steps[i];
      final item = step['uploadItem'] as UploadItem?;
      // Upload if item has file but hasn't been uploaded yet (status is initial)
      if (item != null &&
          item.file != null &&
          item.status == UploadStatus.initial &&
          step['imagePublicId'] == null) {
        _handleStepImageUpload(i, item);
      }
    }
  }

  Future<void> _pickStepImage(int index, ImageSource source) async {
    if (widget.steps[index]['isOriginal'] == true) return; // 💡 기존 이미지는 수정 불가

    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      imageQuality: 70,
    );
    if (image != null) {
      final newItem = UploadItem(file: File(image.path));
      widget.steps[index]['uploadItem'] = newItem;
      _handleStepImageUpload(index, newItem);
    }
  }



  Future<void> _pickMultipleStepImages() async {
    final picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage(
      imageQuality: 70,
      limit: _maxBatchImages,
    );

    if (images.isEmpty) return;

    final files = images.map((img) => File(img.path)).toList();
    widget.onAddMultipleSteps(files);
  }

  Future<void> _handleStepImageUpload(int index, UploadItem item) async {
    setState(() => item.status = UploadStatus.uploading);
    final result = await ref
        .read(uploadImageWithTrackingUseCaseProvider)
        .execute(file: item.file!, type: "STEP");
    result.fold(
      (f) => setState(() => item.status = UploadStatus.error),
      (res) => setState(() {
        item.status = UploadStatus.success;
        widget.steps[index]['imageUrl'] = res.imageUrl;
        widget.steps[index]['imagePublicId'] = res.imagePublicId;
      }),
    );
    widget.onStateChanged();
  }

  @override
  Widget build(BuildContext context) {
    // Split into active and deleted steps
    final activeSteps = widget.steps
        .asMap()
        .entries
        .where((e) => e.value['isDeleted'] != true)
        .toList();

    final deletedSteps = widget.steps
        .asMap()
        .entries
        .where((e) => e.value['isDeleted'] == true)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MinimalHeader(
          icon: Icons.format_list_numbered,
          title: 'steps.header'.tr(),
          isRequired: true,
        ),
        SizedBox(height: 12.h),
        // 💡 드래그 앤 드롭 리스트 (active steps only)
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: activeSteps.length,
          onReorder: (oldIndex, newIndex) {
            // Map back to original indices
            final oldOriginalIndex = activeSteps[oldIndex].key;
            final newOriginalIndex = newIndex < activeSteps.length
                ? activeSteps[newIndex].key
                : widget.steps.length;
            widget.onReorder(oldOriginalIndex, newOriginalIndex);
          },
          itemBuilder: (context, index) {
            final entry = activeSteps[index];
            final originalIndex = entry.key;
            final step = entry.value;
            final bool isOriginal = step['isOriginal'] ?? false;

            return Container(
              key: ValueKey("step_${step['stepNumber']}_$originalIndex"),
              margin: EdgeInsets.only(bottom: 20.h),
              decoration: BoxDecoration(
                color: isOriginal ? Colors.grey[50] : Colors.white,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  ReorderableDragStartListener(
                    index: index,
                    child: Icon(
                      Icons.drag_handle,
                      // Orange color for inherited steps to show it's interactive
                      color: isOriginal ? AppColors.inheritedInteractive : Colors.grey,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  _buildStepNumber(index + 1),
                  SizedBox(width: 12.w),
                  _buildImageSlot(originalIndex, step),
                  SizedBox(width: 12.w),
                  Expanded(child: _buildDescriptionField(step, isOriginal)),
                  IconButton(
                    onPressed: () => widget.onRemoveStep(originalIndex),
                    icon: Icon(
                      Icons.remove_circle_outline,
                      // Orange color for inherited steps to show it's interactive
                      color: isOriginal ? AppColors.inheritedInteractive : Colors.redAccent,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        _buildActionButtons(),
        if (deletedSteps.isNotEmpty) _buildDeletedSection(deletedSteps, isAtMax: activeSteps.length >= _maxSteps),
      ],
    );
  }

  Widget _buildActionButtons() {
    final activeStepCount = widget.steps
        .where((s) => s['isDeleted'] != true)
        .length;
    final isAtMax = activeStepCount >= _maxSteps;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildActionButton(
              onPressed: isAtMax ? null : widget.onAddStep,
              icon: Icons.add,
              label: 'steps.addStep'.tr(),
              isDisabled: isAtMax,
            ),
            SizedBox(width: 12.w),
            _buildActionButton(
              onPressed: isAtMax ? null : _pickMultipleStepImages,
              icon: Icons.photo_library,
              label: 'steps.addMultiple'.tr(),
              isDisabled: isAtMax,
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Text(
          'recipe.stepsMaxInfo'.tr(),
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    bool isDisabled = false,
  }) {
    return GestureDetector(
      onTap: isDisabled ? null : onPressed,
      child: Opacity(
        opacity: isDisabled ? 0.5 : 1.0,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          decoration: AppInputStyles.addButtonDecoration,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18.sp, color: AppColors.inheritedInteractive),
              SizedBox(width: 6.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDescriptionField(Map<String, dynamic> step, bool isOriginal) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      decoration: BoxDecoration(
        // Orange background for editable fields, grey for inherited
        color: isOriginal ? Colors.grey[200] : AppColors.editableBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: isOriginal ? Colors.grey[300]! : AppColors.editableBorder),
      ),
      child: TextField(
        readOnly: isOriginal, // 💡 기존 단계 텍스트 수정 불가
        onChanged: (v) {
          step["description"] = v;
          widget.onStateChanged();
        },
        controller: TextEditingController(text: step["description"])
          ..selection = TextSelection.collapsed(
            offset: step["description"]?.length ?? 0,
          ),
        maxLines: null,
        style: TextStyle(
          color: isOriginal ? Colors.grey[600] : Colors.black,
        ),
        decoration: InputDecoration(
          hintText: isOriginal ? "" : 'recipe.step.hintText'.tr(),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 8.h),
        ),
      ),
    );
  }

  Widget _buildImageSlot(int index, Map<String, dynamic> step) {
    final item = step['uploadItem'] as UploadItem?;
    final String? remoteUrl = step['imageUrl'];
    final bool isOriginal = step['isOriginal'] ?? false;
    final bool hasImage = item?.file != null || (remoteUrl != null && remoteUrl.isNotEmpty);

    // For remote URLs, use CachedNetworkImageProvider with platform URL resolution
    ImageProvider? imageProvider;
    if (item?.file != null) {
      imageProvider = FileImage(item!.file!);
    } else if (remoteUrl != null && remoteUrl.isNotEmpty) {
      final adjustedUrl = PlatformUrlResolver.adjustUrlForPlatform(remoteUrl);
      imageProvider = CachedNetworkImageProvider(adjustedUrl);
    }

    return GestureDetector(
      onTap: () => ImageSourceSheet.show(
        context: context,
        onSourceSelected: (s) => _pickStepImage(index, s),
      ),
      child: Container(
        width: 60.w,
        height: 60.w,
        decoration: BoxDecoration(
          color: hasImage ? null : (isOriginal ? Colors.grey[100] : AppColors.editableBackground),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: isOriginal ? Colors.grey[300]! : AppColors.editableBorder),
          image: imageProvider != null
              ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
              : null,
        ),
        child: (item == null && (remoteUrl == null || remoteUrl.isEmpty))
            ? Icon(Icons.camera_alt, size: 20.sp, color: isOriginal ? Colors.grey : AppColors.inheritedInteractive)
            : null,
      ),
    );
  }

  Widget _buildStepNumber(int number) => Text(
    "$number",
    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
  );

  Widget _buildDeletedSection(List<MapEntry<int, Map<String, dynamic>>> items, {required bool isAtMax}) {
    return Container(
      margin: EdgeInsets.only(top: 8.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'recipe.step.deleted'.tr(),
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          ...items.take(5).map((e) => _buildDeletedRow(e.key, e.value, isAtMax: isAtMax)),
        ],
      ),
    );
  }

  Widget _buildDeletedRow(int index, Map<String, dynamic> step, {required bool isAtMax}) {
    final description = step['description'] ?? '';
    final displayText = description.length > 30
        ? '${description.substring(0, 30)}...'
        : description;

    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'recipe.step.stepLabel'.tr(namedArgs: {'text': displayText}),
              style: TextStyle(
                decoration: TextDecoration.lineThrough,
                color: Colors.grey[500],
                fontSize: 13.sp,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Opacity(
            opacity: isAtMax ? 0.5 : 1.0,
            child: TextButton.icon(
              onPressed: isAtMax ? null : () => widget.onRestoreStep(index),
              icon: Icon(Icons.undo, size: 16.sp),
              label: Text('recipe.step.restore'.tr(), style: TextStyle(fontSize: 12.sp)),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
