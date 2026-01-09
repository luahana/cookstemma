import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pairing_planet2_frontend/core/providers/autocomplete_providers.dart';
import 'package:pairing_planet2_frontend/core/providers/locale_provider.dart';
import 'package:pairing_planet2_frontend/core/widgets/image_source_sheet.dart';
import 'package:pairing_planet2_frontend/core/widgets/reorderable_image_picker.dart';
import 'package:pairing_planet2_frontend/domain/entities/autocomplete/autocomplete_result.dart';
import 'package:pairing_planet2_frontend/shared/data/model/upload_item_model.dart';
import '../../../../core/providers/image_providers.dart';
import 'locale_dropdown.dart';
import 'minimal_header.dart';

class HookSection extends ConsumerStatefulWidget {
  final TextEditingController titleController;
  final TextEditingController foodNameController;
  final TextEditingController descriptionController;
  final TextEditingController localeController;
  final List<UploadItem> finishedImages; // 💡 상위에서 관리되는 완료 이미지 리스트
  final Function(String?) onFoodPublicIdSelected;
  final VoidCallback onStateChanged;
  final Function(int oldIndex, int newIndex) onReorder;
  final bool isReadOnly;

  const HookSection({
    super.key,
    required this.titleController,
    required this.foodNameController,
    required this.descriptionController,
    required this.localeController,
    required this.finishedImages,
    required this.onFoodPublicIdSelected,
    required this.onStateChanged,
    required this.onReorder,
    this.isReadOnly = false,
  });

  @override
  ConsumerState<HookSection> createState() => _HookSectionState();
}

class _HookSectionState extends ConsumerState<HookSection> {
  // 💡 이미지 선택 및 업로드 프로세스 시작
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      imageQuality: 70,
    );
    if (image != null) {
      final newItem = UploadItem(file: File(image.path));
      setState(() => widget.finishedImages.add(newItem));
      _handleImageUpload(newItem);
    }
  }

  Future<void> _handleImageUpload(UploadItem item) async {
    setState(() => item.status = UploadStatus.uploading);
    widget.onStateChanged();
    final result = await ref
        .read(uploadImageWithTrackingUseCaseProvider)
        .execute(file: item.file, type: "THUMBNAIL");
    result.fold((f) => setState(() => item.status = UploadStatus.error), (res) {
      setState(() {
        item.status = UploadStatus.success;
        item.serverUrl = res.imageUrl;
        item.publicId = res.imagePublicId;
      });
    });
    widget.onStateChanged();
  }

  void _removeImage(int index) {
    setState(() {
      widget.finishedImages.removeAt(index);
    });
    widget.onStateChanged();
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = ref.watch(localeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MinimalHeader(icon: Icons.edit_note, title: 'recipe.hook.basicInfo'.tr()),
        const SizedBox(height: 16),

        // 1. 이미지 등록 섹션 추가
        Text(
          'recipe.hook.finishedPhotos'.tr(),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ReorderableImagePicker(
          images: widget.finishedImages,
          maxImages: 3,
          onReorder: widget.onReorder,
          onRemove: _removeImage,
          onRetry: _handleImageUpload,
          onAdd: () => ImageSourceSheet.show(
            context: context,
            onSourceSelected: _pickImage,
          ),
        ),
        const SizedBox(height: 24),

        _buildTextField(
          controller: widget.titleController,
          label: 'recipe.hook.title'.tr(),
          hint: 'recipe.hook.titleHint'.tr(),
        ),
        const SizedBox(height: 16),

        Text(
          'recipe.hook.foodName'.tr(),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Autocomplete<AutocompleteResult>(
          displayStringForOption: (option) => option.name,
          optionsBuilder: (TextEditingValue textEditingValue) async {
            // 변형 모드이거나 입력값이 없으면 검색 안함
            if (widget.isReadOnly || textEditingValue.text.isEmpty)
              return const Iterable.empty();
            final result = await ref
                .read(getAutocompleteUseCaseProvider)
                .execute(textEditingValue.text, currentLocale);
            return result.fold((_) => const Iterable.empty(), (list) => list);
          },
          onSelected: (selection) {
            widget.foodNameController.text = selection.name;
            // Only set publicId for FOOD type, not CATEGORY
            if (selection.type == 'FOOD') {
              widget.onFoodPublicIdSelected(selection.publicId);
            } else {
              widget.onFoodPublicIdSelected(null); // Will use newFoodName instead
            }
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            // 초기값 동기화
            if (controller.text != widget.foodNameController.text) {
              controller.text = widget.foodNameController.text;
            }
            // Sync internal controller back to foodNameController
            controller.addListener(() {
              if (widget.foodNameController.text != controller.text) {
                widget.foodNameController.text = controller.text;
              }
            });
            return _buildTextFieldRaw(
              controller: controller,
              focusNode: focusNode,
              hint: 'recipe.hook.foodNameHint'.tr(),
              enabled: !widget.isReadOnly,
              backgroundColor: widget.isReadOnly
                  ? Colors.grey[100]
                  : Colors.grey[50],
            );
          },
          optionsViewBuilder: (context, onSelected, options) =>
              _buildOptionsView(onSelected, options),
        ),
        const SizedBox(height: 16),

        _buildTextField(
          controller: widget.descriptionController,
          label: 'recipe.hook.description'.tr(),
          hint: 'recipe.hook.descriptionHint'.tr(),
          maxLines: 3,
        ),
        const SizedBox(height: 16),

        // Culinary locale dropdown
        LocaleDropdown(
          value: widget.localeController.text.isNotEmpty
              ? widget.localeController.text
              : null,
          enabled: !widget.isReadOnly,
          onChanged: (value) {
            if (value != null) {
              widget.localeController.text = value;
              widget.onStateChanged();
            }
          },
        ),
      ],
    );
  }

  Widget _buildOptionsView(
    Function(AutocompleteResult) onSelected,
    Iterable<AutocompleteResult> options,
  ) {
    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: MediaQuery.of(context).size.width - 40,
          constraints: const BoxConstraints(maxHeight: 200),
          child: ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options.elementAt(index);
              return ListTile(
                title: Text(option.name),
                onTap: () => onSelected(option),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildTextFieldRaw(
          controller: controller,
          hint: hint,
          maxLines: maxLines,
        ),
      ],
    );
  }

  // 💡 순수 텍스트 필드 위젯
  Widget _buildTextFieldRaw({
    required TextEditingController controller,
    required String hint,
    FocusNode? focusNode,
    int maxLines = 1,
    bool enabled = true,
    Color? backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        enabled: enabled,
        maxLines: maxLines,
        style: TextStyle(color: enabled ? Colors.black : Colors.grey[600]),
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ),
    );
  }

}
