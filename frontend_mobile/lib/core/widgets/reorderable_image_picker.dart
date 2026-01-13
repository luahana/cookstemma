import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/core/theme/app_input_styles.dart';
import 'package:pairing_planet2_frontend/core/widgets/app_cached_image.dart';
import 'package:pairing_planet2_frontend/shared/data/model/upload_item_model.dart';

/// Reorderable horizontal image picker with thumbnail badge support.
/// Used by both recipe creation and log post creation.
class ReorderableImagePicker extends StatelessWidget {
  final List<UploadItem> images;
  final int maxImages;
  final Function(int oldIndex, int newIndex) onReorder;
  final Function(int index) onRemove;
  final Function(UploadItem item) onRetry;
  final VoidCallback onAdd;
  final bool showThumbnailBadge;

  const ReorderableImagePicker({
    super.key,
    required this.images,
    this.maxImages = 3,
    required this.onReorder,
    required this.onRemove,
    required this.onRetry,
    required this.onAdd,
    this.showThumbnailBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110.h,
      child: ReorderableListView.builder(
        scrollDirection: Axis.horizontal,
        buildDefaultDragHandles: false,
        itemCount: images.length + 1,
        onReorder: (oldIndex, newIndex) {
          // Don't allow reordering the add button
          if (oldIndex >= images.length) return;
          if (newIndex > images.length) {
            newIndex = images.length;
          }
          onReorder(oldIndex, newIndex);
        },
        itemBuilder: (context, index) {
          if (index == images.length) {
            if (images.length >= maxImages) {
              return SizedBox.shrink(key: const ValueKey('empty'));
            }
            return _buildAddButton();
          }

          final item = images[index];
          return _buildImageItem(context, item, index);
        },
      ),
    );
  }

  Widget _buildAddButton() {
    return SizedBox(
      key: const ValueKey('add_button'),
      width: 112.w,
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(top: 10.h, right: 12.w),
            child: GestureDetector(
              onTap: onAdd,
              child: Container(
                width: 100.w,
                height: 100.w,
                decoration: AppInputStyles.addButtonDecoration,
                child: Icon(Icons.add_a_photo, color: AppColors.inheritedInteractive),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageItem(BuildContext context, UploadItem item, int index) {
    final bool isThumbnail = index == 0 && showThumbnailBadge;

    // Use stable unique key (file path or remoteUrl) instead of index to prevent
    // widget state desync during concurrent uploads
    final stableKey = item.file?.path ?? item.remoteUrl ?? 'image_$index';
    return ReorderableDragStartListener(
      key: ValueKey(stableKey),
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
                  borderRadius: BorderRadius.circular(10.r),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildImageWidget(context, item),
                      _buildStatusOverlay(item),
                    ],
                  ),
                ),
              ),
            ),
            // Thumbnail badge
            if (isThumbnail)
              Positioned(
                bottom: 6.h,
                left: 6.w,
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    'recipe.hook.thumbnail'.tr(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            // Delete button
            Positioned(
              top: 2.h,
              right: 4.w,
              child: GestureDetector(
                onTap: () => onRemove(index),
                child: Container(
                  padding: EdgeInsets.all(4.r),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4.r,
                        offset: Offset(0, 2.h),
                      ),
                    ],
                  ),
                  child: Icon(Icons.close, size: 14.sp, color: Colors.black),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget(BuildContext context, UploadItem item) {
    final opacity = item.status == UploadStatus.uploading
        ? 0.6
        : (item.status == UploadStatus.error ? 0.4 : 1.0);

    if (item.isRemote) {
      // Remote image (existing)
      return Opacity(
        opacity: opacity,
        child: AppCachedImage(
          imageUrl: item.remoteUrl,
          width: 100.w,
          height: 100.w,
          borderRadius: 10.r,
        ),
      );
    } else {
      // Local file (new upload)
      // Use cacheWidth/cacheHeight to reduce memory footprint
      // Display is 100x100, multiply by devicePixelRatio
      final cacheSize = (100 * MediaQuery.devicePixelRatioOf(context)).toInt();
      return Image.file(
        item.file!,
        fit: BoxFit.cover,
        opacity: AlwaysStoppedAnimation(opacity),
        cacheWidth: cacheSize,
        cacheHeight: cacheSize,
      );
    }
  }

  Widget _buildStatusOverlay(UploadItem item) {
    switch (item.status) {
      case UploadStatus.uploading:
        return Container(
          color: Colors.black12,
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
        );
      case UploadStatus.success:
        return Align(
          alignment: Alignment.bottomRight,
          child: Container(
            margin: EdgeInsets.all(6.r),
            padding: EdgeInsets.all(2.r),
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check, size: 14.sp, color: Colors.white),
          ),
        );
      case UploadStatus.error:
        return Container(
          color: Colors.black38,
          child: Center(
            child: IconButton(
              icon: Icon(Icons.refresh, color: Colors.white, size: 28.sp),
              onPressed: () => onRetry(item),
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
