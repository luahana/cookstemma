import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pairing_planet2_frontend/core/providers/autocomplete_providers.dart';
import 'package:pairing_planet2_frontend/core/providers/locale_provider.dart';
import 'package:pairing_planet2_frontend/core/widgets/image_source_sheet.dart';
import 'package:pairing_planet2_frontend/domain/entities/autocomplete/autocomplete_result.dart';
import 'package:pairing_planet2_frontend/shared/data/model/upload_item_model.dart';
import '../../../../core/providers/image_providers.dart';
import 'minimal_header.dart';

class HookSection extends ConsumerStatefulWidget {
  final TextEditingController titleController;
  final TextEditingController foodNameController;
  final TextEditingController descriptionController;
  final List<UploadItem> finishedImages; // 💡 상위에서 관리되는 완료 이미지 리스트
  final Function(String?) onFoodPublicIdSelected;
  final VoidCallback onStateChanged;
  final bool isReadOnly;

  const HookSection({
    super.key,
    required this.titleController,
    required this.foodNameController,
    required this.descriptionController,
    required this.finishedImages,
    required this.onFoodPublicIdSelected,
    required this.onStateChanged,
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
        const MinimalHeader(icon: Icons.edit_note, title: "레시피 기본 정보"),
        const SizedBox(height: 16),

        // 1. 이미지 등록 섹션 추가
        const Text(
          "완성 사진 (최대 5장)",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildImagePickerList(),
        const SizedBox(height: 24),

        _buildTextField(
          controller: widget.titleController,
          label: "레시피 제목",
          hint: "예: 나만의 매콤한 김치찌개",
        ),
        const SizedBox(height: 16),

        const Text(
          "요리명",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
              hint: "어떤 요리인가요? (예: 김치찌개)",
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
          label: "레시피 설명",
          hint: "이 레시피의 특징을 간단히 적어주세요.",
          maxLines: 3,
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

  // 💡 가로 스크롤 형태의 이미지 리스트 UI
  Widget _buildImagePickerList() {
    return SizedBox(
      // 💡 높이를 110으로 늘려 상단 'X' 버튼이 잘리지 않게 합니다.
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.finishedImages.length + 1,
        itemBuilder: (context, index) {
          if (index == widget.finishedImages.length) {
            if (widget.finishedImages.length >= 5)
              return const SizedBox.shrink();
            // 💡 추가 버튼도 높이를 맞춰줍니다.
            return Padding(
              padding: const EdgeInsets.only(top: 10),
              child: _buildAddButton(),
            );
          }

          final item = widget.finishedImages[index];
          return _buildImageItem(item, index);
        },
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: () =>
          ImageSourceSheet.show(context: context, onSourceSelected: _pickImage),
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
    return Container(
      width: 112, // 마진 포함 너비
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 💡 이미지를 보여주는 메인 컨테이너
          Padding(
            padding: const EdgeInsets.only(top: 10, right: 12),
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[200], // 이미지 로딩 전 배경색
                borderRadius: BorderRadius.circular(12),
              ),
              // 💡 DecorationImage 대신 ClipRRect + Image.file 사용 (더 안정적임)
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(
                      item.file,
                      fit: BoxFit.cover,
                      // 💡 상태에 따른 불투명도 조절
                      opacity: AlwaysStoppedAnimation(
                        item.status == UploadStatus.uploading
                            ? 0.6
                            : (item.status == UploadStatus.error ? 0.4 : 1.0),
                      ),
                    ),
                    // 💡 이미지 위에 업로드 상태 표시 (스피너 등)
                    _buildStatusOverlay(item),
                  ],
                ),
              ),
            ),
          ),
          // 💡 삭제 버튼 (위치를 더 정확히 조정)
          Positioned(
            top: 2,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeImage(index),
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
              onPressed: () => _handleImageUpload(item),
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
