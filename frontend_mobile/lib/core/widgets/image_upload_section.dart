import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pairing_planet2_frontend/core/providers/image_providers.dart';
import 'package:pairing_planet2_frontend/core/widgets/image_source_sheet.dart';
import 'package:pairing_planet2_frontend/shared/data/model/upload_item_model.dart';

class ImageUploadSection extends ConsumerStatefulWidget {
  final List<UploadItem> images;
  final int maxImages;
  final String uploadType; // "THUMBNAIL" or "LOG_POST"
  final bool setServerUrl; // true for recipes, false for log posts
  final VoidCallback? onStateChanged;
  final ValueChanged<List<UploadItem>> onImagesChanged;

  const ImageUploadSection({
    super.key,
    required this.images,
    required this.maxImages,
    required this.uploadType,
    required this.onImagesChanged,
    this.setServerUrl = false,
    this.onStateChanged,
  });

  @override
  ConsumerState<ImageUploadSection> createState() => _ImageUploadSectionState();
}

class _ImageUploadSectionState extends ConsumerState<ImageUploadSection> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    if (widget.images.length >= widget.maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('최대 ${widget.maxImages}장까지 업로드 가능합니다.')),
      );
      return;
    }

    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      final newItem = UploadItem(file: File(pickedFile.path));
      final updatedImages = [...widget.images, newItem];
      widget.onImagesChanged(updatedImages);
      await _handleImageUpload(newItem);
    }
  }

  Future<void> _handleImageUpload(UploadItem item) async {
    final index = widget.images.indexOf(item);
    if (index == -1) return;

    item.status = UploadStatus.uploading;
    widget.onImagesChanged([...widget.images]);
    widget.onStateChanged?.call();

    try {
      // Use the tracking use case to log photo uploads
      final uploadUseCase = ref.read(uploadImageWithTrackingUseCaseProvider);
      final result = await uploadUseCase.execute(
        file: item.file!,
        type: widget.uploadType,
      );

      result.fold(
        (failure) {
          item.status = UploadStatus.error;
        },
        (response) {
          item.status = UploadStatus.success;
          item.publicId = response.imagePublicId;
          if (widget.setServerUrl) {
            item.serverUrl = response.imageUrl;
          }
        },
      );
    } catch (e) {
      item.status = UploadStatus.error;
    }

    widget.onImagesChanged([...widget.images]);
    widget.onStateChanged?.call();
  }

  void _removeImage(int index) {
    final updatedImages = List<UploadItem>.from(widget.images)..removeAt(index);
    widget.onImagesChanged(updatedImages);
    widget.onStateChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: [
        ..._buildImageList(),
        if (widget.images.length < widget.maxImages) _buildAddButton(),
      ],
    );
  }

  List<Widget> _buildImageList() {
    return widget.images.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      return _buildImageItem(item, index);
    }).toList();
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: () {
        ImageSourceSheet.show(
          context: context,
          onSourceSelected: (source) {
            _pickImage(source);
          },
        );
      },
      child: Container(
        width: 100.w,
        height: 100.w,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: const Icon(Icons.add_a_photo, color: Colors.grey),
      ),
    );
  }

  Widget _buildImageItem(UploadItem item, int index) {
    return Container(
      width: 100.w,
      height: 100.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        image: DecorationImage(
          image: FileImage(item.file!),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          // Delete button
          Positioned(
            top: 4.h,
            right: 4.w,
            child: GestureDetector(
              onTap: () => _removeImage(index),
              child: Container(
                padding: EdgeInsets.all(4.r),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close, color: Colors.white, size: 16.sp),
              ),
            ),
          ),
          // Status overlay
          if (item.status != UploadStatus.initial)
            _buildStatusOverlay(item),
        ],
      ),
    );
  }

  Widget _buildStatusOverlay(UploadItem item) {
    if (item.status == UploadStatus.uploading) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (item.status == UploadStatus.success) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Center(
          child: Icon(Icons.check_circle, color: Colors.green, size: 30.sp),
        ),
      );
    }

    // Error state
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Center(
        child: IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: () => _handleImageUpload(item),
        ),
      ),
    );
  }
}
