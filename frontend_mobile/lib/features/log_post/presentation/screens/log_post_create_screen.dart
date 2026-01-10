import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/core/widgets/app_cached_image.dart';
import 'package:pairing_planet2_frontend/core/widgets/image_source_sheet.dart';
import 'package:pairing_planet2_frontend/core/widgets/reorderable_image_picker.dart';
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

  void _reorderImages(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _images.removeAt(oldIndex);
      _images.insert(newIndex, item);
    });
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
                padding: EdgeInsets.all(20.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRecipeSummary(),
                    SizedBox(height: 32.h),

                    // 💡 2. 이미지 업로드 섹션 추가
                    Text(
                      'logPost.photosMax'.tr(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                      ),
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
                    ),
                    SizedBox(height: 32.h),

                    // 💡 3. 요리 결과 섹션 (이모지 선택)
                    Text(
                      'logPost.howWasIt'.tr(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    _buildOutcomeSelector(),
                    SizedBox(height: 32.h),

                    Text(
                      'logPost.howWasToday'.tr(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    _buildContentField(),
                    SizedBox(height: 32.h),

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
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          if (widget.recipe.imageUrls.isNotEmpty)
            AppCachedImage(
              imageUrl: widget.recipe.imageUrls.first,
              width: 60.w,
              height: 60.w,
              borderRadius: 8.r,
            ),
          if (widget.recipe.imageUrls.isNotEmpty)
            SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.recipe.foodName,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.recipe.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15.sp,
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
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? Colors.indigo : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: TextStyle(fontSize: 32.sp)),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
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
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TextField(
        controller: _contentController,
        maxLines: 5,
        decoration: InputDecoration(
          hintText: 'logPost.contentHint'.tr(),
          border: InputBorder.none,
          hintStyle: TextStyle(fontSize: 14.sp),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 30.h),
      child: SizedBox(
        width: double.infinity,
        height: 56.h,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
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
