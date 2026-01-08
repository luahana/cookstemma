import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/core/widgets/app_cached_image.dart';
import 'package:pairing_planet2_frontend/core/widgets/image_source_sheet.dart';
import 'package:pairing_planet2_frontend/domain/entities/log_post/create_log_post_request.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_detail.dart';
import 'package:pairing_planet2_frontend/features/log_post/providers/log_post_providers.dart';
import 'package:pairing_planet2_frontend/features/recipe/presentation/widgets/hashtag_input_section.dart';
import 'package:pairing_planet2_frontend/shared/data/model/upload_item_model.dart';
import '../../../../core/providers/image_providers.dart'; // 💡 이미지 프로바이더 추가

class LogPostCreateScreen extends ConsumerStatefulWidget {
  final RecipeDetail recipe;

  const LogPostCreateScreen({super.key, required this.recipe});

  @override
  ConsumerState<LogPostCreateScreen> createState() =>
      _LogPostCreateScreenState();
}

class _LogPostCreateScreenState extends ConsumerState<LogPostCreateScreen> {
  final _contentController = TextEditingController();
  final List<UploadItem> _images = []; // 💡 업로드 이미지 리스트
  final List<String> _hashtags = []; // 해시태그 리스트
  String _selectedOutcome = 'SUCCESS'; // 💡 요리 결과 (SUCCESS, PARTIAL, FAILED)
  bool _isLoading = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  // 💡 1. 이미지 선택 및 업로드 로직 (HookSection과 동일 패턴)
  Future<void> _pickImage(ImageSource source) async {
    if (_images.length >= 3) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('logPost.maxPhotosError'.tr())));
      return;
    }
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      imageQuality: 70,
    );
    if (image != null) {
      final newItem = UploadItem(file: File(image.path));
      setState(() => _images.add(newItem));
      _handleImageUpload(newItem);
    }
  }

  Future<void> _handleImageUpload(UploadItem item) async {
    setState(() => item.status = UploadStatus.uploading);
    final result = await ref
        .read(uploadImageWithTrackingUseCaseProvider)
        .execute(file: item.file, type: "LOG_POST");
    result.fold((f) => setState(() => item.status = UploadStatus.error), (res) {
      setState(() {
        item.status = UploadStatus.success;
        item.publicId = res.imagePublicId;
      });
    });
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  Future<void> _submit() async {
    if (_contentController.text.trim().isEmpty) return;

    setState(() => _isLoading = true); // 로딩 시작

    final imagePublicIds = _images
        .where((img) => img.status == UploadStatus.success)
        .map((img) => img.publicId!)
        .toList();

    final request = CreateLogPostRequest(
      recipePublicId: widget.recipe.publicId,
      content: _contentController.text,
      outcome: _selectedOutcome,
      imagePublicIds: imagePublicIds,
      hashtags: _hashtags.isNotEmpty ? _hashtags : null,
    );

    try {
      // 1. 함수 호출 (내부 state가 AsyncValue<LogPostDetail?>로 변경됨)
      await ref.read(logPostCreationProvider.notifier).createLog(request);

      if (mounted) {
        final currentState = ref.read(logPostCreationProvider);

        if (currentState.hasError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('logPost.submitFailed'.tr(namedArgs: {'error': currentState.error.toString()}))),
          );
          return;
        }

        // 💡 이제 currentState.value가 LogPostDetail? 타입이므로 에러가 발생하지 않습니다.
        final logDetail = currentState.value;

        if (logDetail != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('logPost.createSuccess'.tr())));

          // 성공한 데이터의 publicId를 사용하여 상세 페이지로 이동
          context.pushReplacement(
            RouteConstants.logPostDetailPath(logDetail.publicId),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false); // 로딩 종료
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text('logPost.createTitle'.tr()),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRecipeSummary(),
                    const SizedBox(height: 32),

                    // 💡 2. 이미지 업로드 섹션 추가
                    Text(
                      'logPost.photosMax'.tr(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildImagePickerList(),
                    const SizedBox(height: 32),

                    // 💡 3. 요리 결과 섹션 (이모지 선택)
                    Text(
                      'logPost.howWasIt'.tr(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildOutcomeSelector(),
                    const SizedBox(height: 32),

                    Text(
                      'logPost.howWasToday'.tr(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildContentField(),
                    const SizedBox(height: 32),

                    // 해시태그 입력 섹션
                    HashtagInputSection(
                      hashtags: _hashtags,
                      onHashtagsChanged: (tags) => setState(() {
                        _hashtags.clear();
                        _hashtags.addAll(tags);
                      }),
                    ),
                  ],
                ),
              ),
            ),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  // ... (레시피 요약 위젯은 기존과 동일)
  Widget _buildRecipeSummary() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          if (widget.recipe.imageUrls.isNotEmpty)
            AppCachedImage(
              imageUrl: widget.recipe.imageUrls.first,
              width: 60,
              height: 60,
              borderRadius: 8,
            ),
          if (widget.recipe.imageUrls.isNotEmpty)
            const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.recipe.foodName,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.indigo[900],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.recipe.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 💡 이미지 리스트 및 추가 버튼 UI
  Widget _buildImagePickerList() {
    return SizedBox(
      height: 110, // 버튼 잘림 방지를 위한 높이
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _images.length + 1,
        itemBuilder: (context, index) {
          if (index == _images.length) {
            if (_images.length >= 3) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 10),
              child: _buildAddButton(),
            );
          }
          final item = _images[index];
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
        height: 100,
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

  // 💡 개별 이미지 아이템 UI (로딩, 성공, 에러 오버레이 포함)
  Widget _buildImageItem(UploadItem item, int index) {
    return SizedBox(
      width: 112,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10, right: 12),
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(
                      item.file,
                      fit: BoxFit.cover,
                      opacity: AlwaysStoppedAnimation(
                        item.status == UploadStatus.uploading
                            ? 0.7
                            : (item.status == UploadStatus.error ? 0.5 : 1.0),
                      ),
                    ),
                    _buildStatusOverlay(item), // 상태별 오버레이
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            // 삭제 버튼
            top: 2,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeImage(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
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

  // 💡 요리 결과 이모지 선택 UI
  Widget _buildOutcomeSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildOutcomeOption('SUCCESS', '😊', 'logPost.successLabel'.tr()),
        _buildOutcomeOption('PARTIAL', '😐', 'logPost.partialLabel'.tr()),
        _buildOutcomeOption('FAILED', '😢', 'logPost.failedLabel'.tr()),
      ],
    );
  }

  Widget _buildOutcomeOption(String value, String emoji, String label) {
    final isSelected = _selectedOutcome == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedOutcome = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.indigo[50] : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.indigo : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.indigo : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TextField(
        controller: _contentController,
        maxLines: 5,
        decoration: InputDecoration(
          hintText: 'logPost.contentHint'.tr(),
          border: InputBorder.none,
          hintStyle: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A237E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            _isLoading ? 'logPost.submitting'.tr() : 'logPost.submit'.tr(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
