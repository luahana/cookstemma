import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
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
      height: 110,
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
            return Padding(
              key: const ValueKey('add_button'),
              padding: const EdgeInsets.only(top: 10),
              child: _buildAddButton(),
            );
          }

          final item = images[index];
          return _buildImageItem(item, index);
        },
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: onAdd,
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: const Icon(Icons.add_a_photo, color: Colors.grey),
      ),
    );
  }

  Widget _buildImageItem(UploadItem item, int index) {
    final bool isThumbnail = index == 0 && showThumbnailBadge;

    return ReorderableDragStartListener(
      key: ValueKey('image_$index'),
      index: index,
      child: SizedBox(
        width: 112,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Image container
            Padding(
              padding: const EdgeInsets.only(top: 10, right: 12),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: isThumbnail
                      ? Border.all(color: AppColors.primary, width: 2)
                      : null,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(
                        item.file,
                        fit: BoxFit.cover,
                        opacity: AlwaysStoppedAnimation(
                          item.status == UploadStatus.uploading
                              ? 0.6
                              : (item.status == UploadStatus.error ? 0.4 : 1.0),
                        ),
                      ),
                      _buildStatusOverlay(item),
                    ],
                  ),
                ),
              ),
            ),
            // Thumbnail badge
            if (isThumbnail)
              Positioned(
                bottom: 6,
                left: 6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'recipe.hook.thumbnail'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            // Delete button
            Positioned(
              top: 2,
              right: 4,
              child: GestureDetector(
                onTap: () => onRemove(index),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.close, size: 14, color: Colors.black),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
            margin: const EdgeInsets.all(6),
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, size: 14, color: Colors.white),
          ),
        );
      case UploadStatus.error:
        return Container(
          color: Colors.black38,
          child: Center(
            child: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white, size: 28),
              onPressed: () => onRetry(item),
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
