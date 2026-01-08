import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/create_recipe_request.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/ingredient.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_step.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_detail.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_draft.dart';
import 'package:pairing_planet2_frontend/features/recipe/presentation/widgets/ingredient_section.dart';
import 'package:pairing_planet2_frontend/features/recipe/providers/recipe_providers.dart';
import 'package:pairing_planet2_frontend/features/profile/providers/profile_provider.dart';
import 'package:pairing_planet2_frontend/core/providers/locale_provider.dart';
import 'package:pairing_planet2_frontend/shared/data/model/upload_item_model.dart';
import 'package:uuid/uuid.dart';
import '../widgets/hook_section.dart';
import '../widgets/step_section.dart';
import '../widgets/hashtag_input_section.dart';
import '../widgets/draft_status_indicator.dart';
import '../widgets/continue_draft_dialog.dart';

class RecipeCreateScreen extends ConsumerStatefulWidget {
  final RecipeDetail? parentRecipe; // 💡 변경: ID 대신 객체 수신

  const RecipeCreateScreen({super.key, this.parentRecipe});

  @override
  ConsumerState<RecipeCreateScreen> createState() => _RecipeCreateScreenState();
}

class _RecipeCreateScreenState extends ConsumerState<RecipeCreateScreen>
    with WidgetsBindingObserver {
  final _titleController = TextEditingController();
  final _foodNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _localeController = TextEditingController();
  final _changeReasonController = TextEditingController();

  bool get isVariantMode => widget.parentRecipe != null;

  final List<Map<String, dynamic>> _ingredients = [];
  final List<Map<String, dynamic>> _steps = [];
  final List<UploadItem> _finishedImages = [];
  final List<String> _hashtags = [];

  String? _food1MasterPublicId;
  bool _isLoading = false;
  String? _draftId;
  bool _draftChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (isVariantMode) {
      _initVariantData();
      _draftChecked = true; // Skip draft check in variant mode
    } else {
      _addIngredient('MAIN');
      _addStep();
      // Set default locale and check for existing draft after frame is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_localeController.text.isEmpty) {
          final userLocale = ref.read(localeProvider);
          _localeController.text = userLocale;
        }
        _checkForExistingDraft();
      });
    }
    _titleController.addListener(_rebuild);
    _foodNameController.addListener(_rebuild);

    // Start auto-save timer (skip for variant mode)
    if (!isVariantMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(recipeDraftProvider.notifier).startAutoSave(_collectCurrentDraft);
      });
    }
  }

  void _initVariantData() {
    final p = widget.parentRecipe!;
    _titleController.text = "${p.title} ${'recipe.variantSuffix'.tr()}";
    _descriptionController.text = p.description ?? "";
    _foodNameController.text = p.foodName; // 💡 실제 요리명 매핑 권장
    _localeController.text = p.culinaryLocale ?? "ko-KR"; // Inherit locale from parent

    _food1MasterPublicId = p.foodMasterPublicId;

    // 💡 기존 재료 복사 (수정 불가 마킹)
    for (var ing in p.ingredients) {
      _ingredients.add({
        'name': ing.name,
        'amount': ing.amount,
        'type': ing.type, // Already a string in domain entity
        'isOriginal': true,
        'isDeleted': false,
      });
    }
    // 💡 기존 단계 복사 (수정 불가 마킹)
    for (var step in p.steps) {
      _steps.add({
        'stepNumber': step.stepNumber,
        'description': step.description,
        'imageUrl': step.imageUrl,
        'imagePublicId': step.imagePublicId,
        'isOriginal': true,
        'isDeleted': false,
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (!isVariantMode) {
      ref.read(recipeDraftProvider.notifier).stopAutoSave();
    }
    _titleController.dispose();
    _foodNameController.dispose();
    _descriptionController.dispose();
    _localeController.dispose();
    _changeReasonController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Save draft when app goes to background
    if (!isVariantMode &&
        (state == AppLifecycleState.paused ||
            state == AppLifecycleState.inactive)) {
      _triggerSave();
    }
  }

  /// Collect current form state into a RecipeDraft object
  RecipeDraft _collectCurrentDraft() {
    final now = DateTime.now();
    return RecipeDraft(
      id: _draftId ?? const Uuid().v4(),
      title: _titleController.text,
      description: _descriptionController.text,
      culinaryLocale:
          _localeController.text.isEmpty ? null : _localeController.text,
      food1MasterPublicId: _food1MasterPublicId,
      foodName: _foodNameController.text.isEmpty
          ? null
          : _foodNameController.text,
      ingredients: _ingredients
          .map((i) => DraftIngredient(
                name: i['name'] as String,
                amount: i['amount'] as String?,
                type: i['type'] as String,
                isOriginal: i['isOriginal'] as bool? ?? false,
                isDeleted: i['isDeleted'] as bool? ?? false,
              ))
          .toList(),
      steps: _steps
          .map((s) => DraftStep(
                stepNumber: s['stepNumber'] as int,
                description: s['description'] as String?,
                imageUrl: s['imageUrl'] as String?,
                imagePublicId: s['imagePublicId'] as String?,
                localImagePath: (s['uploadItem'] as UploadItem?)?.file.path,
                isOriginal: s['isOriginal'] as bool? ?? false,
                isDeleted: s['isDeleted'] as bool? ?? false,
              ))
          .toList(),
      images: _finishedImages
          .map((img) => DraftImage(
                localPath: img.file.path,
                serverUrl: img.serverUrl,
                publicId: img.publicId,
                status: img.status.name,
              ))
          .toList(),
      hashtags: _hashtags,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Trigger a save of the current draft
  Future<void> _triggerSave() async {
    if (isVariantMode) return;
    final draft = _collectCurrentDraft();
    if (draft.hasContent) {
      await ref.read(recipeDraftProvider.notifier).saveDraft(draft);
    }
  }

  /// Check for existing draft and show dialog
  Future<void> _checkForExistingDraft() async {
    if (_draftChecked || isVariantMode) return;
    _draftChecked = true;

    final draft = await ref.read(recipeDraftProvider.notifier).loadDraft();

    if (draft != null && mounted) {
      final shouldContinue = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => ContinueDraftDialog(
          draft: draft,
          onContinue: () => Navigator.pop(context, true),
          onDiscard: () => Navigator.pop(context, false),
        ),
      );

      if (shouldContinue == true) {
        _restoreDraft(draft);
      } else {
        await ref.read(recipeDraftProvider.notifier).clearDraft();
      }
    }
  }

  /// Restore form state from a draft
  void _restoreDraft(RecipeDraft draft) {
    _draftId = draft.id;
    _titleController.text = draft.title;
    _descriptionController.text = draft.description;
    _localeController.text = draft.culinaryLocale ?? '';
    _foodNameController.text = draft.foodName ?? '';
    _food1MasterPublicId = draft.food1MasterPublicId;

    // Restore ingredients
    _ingredients.clear();
    for (final ing in draft.ingredients) {
      _ingredients.add({
        'name': ing.name,
        'amount': ing.amount,
        'type': ing.type,
        'isOriginal': ing.isOriginal,
        'isDeleted': ing.isDeleted,
      });
    }
    // Add default ingredient if empty
    if (_ingredients.isEmpty) {
      _addIngredient('MAIN');
    }

    // Restore steps
    _steps.clear();
    for (final step in draft.steps) {
      UploadItem? uploadItem;
      // Check if local image file still exists
      if (step.localImagePath != null) {
        final file = File(step.localImagePath!);
        if (file.existsSync()) {
          uploadItem = UploadItem(
            file: file,
            status: step.imagePublicId != null
                ? UploadStatus.success
                : UploadStatus.initial,
            serverUrl: step.imageUrl,
            publicId: step.imagePublicId,
          );
        }
      }
      _steps.add({
        'stepNumber': step.stepNumber,
        'description': step.description,
        'imageUrl': step.imageUrl,
        'imagePublicId': step.imagePublicId,
        'uploadItem': uploadItem,
        'isOriginal': step.isOriginal,
        'isDeleted': step.isDeleted,
      });
    }
    // Add default step if empty
    if (_steps.isEmpty) {
      _addStep();
    }

    // Restore finished images
    _finishedImages.clear();
    for (final img in draft.images) {
      final file = File(img.localPath);
      if (file.existsSync()) {
        _finishedImages.add(UploadItem(
          file: file,
          status: _parseUploadStatus(img.status),
          serverUrl: img.serverUrl,
          publicId: img.publicId,
        ));
      }
    }

    // Restore hashtags
    _hashtags.clear();
    _hashtags.addAll(draft.hashtags);

    setState(() {});
  }

  UploadStatus _parseUploadStatus(String status) {
    switch (status) {
      case 'uploading':
        return UploadStatus.uploading;
      case 'success':
        return UploadStatus.success;
      case 'error':
        return UploadStatus.error;
      default:
        return UploadStatus.initial;
    }
  }

  /// Handle back navigation with draft save
  Future<void> _handleClose() async {
    if (!isVariantMode) {
      await _triggerSave();
    }
    if (mounted) {
      context.pop();
    }
  }

  void _rebuild() => setState(() {});

  void _addIngredient(String type) {
    setState(() {
      _ingredients.add({
        'name': '',
        'amount': '',
        'type': type,
        'isOriginal': false,
        'isDeleted': false,
      });
    });
  }

  void _onRemoveIngredient(int index) {
    setState(() {
      _ingredients[index]['isDeleted'] = true;
    });
  }

  void _onRestoreIngredient(int index) {
    setState(() {
      _ingredients[index]['isDeleted'] = false;
    });
  }

  void _addStep() {
    setState(() {
      _steps.add({
        'stepNumber': _steps.length + 1,
        'description': '',
        'imageUrl': '',
        'imagePublicId': null,
        'uploadItem': null,
        'isOriginal': false,
        'isDeleted': false,
      });
    });
  }

  void _addMultipleSteps(List<File> images) {
    setState(() {
      for (final image in images) {
        _steps.add({
          'stepNumber': _steps.length + 1,
          'description': '',
          'imageUrl': '',
          'imagePublicId': null,
          'uploadItem': UploadItem(file: image),
          'isOriginal': false,
          'isDeleted': false,
        });
      }
    });
  }

  void _onRemoveStep(int index) {
    setState(() {
      _steps[index]['isDeleted'] = true;
    });
  }

  void _onRestoreStep(int index) {
    setState(() {
      _steps[index]['isDeleted'] = false;
    });
  }

  // 💡 드래그 앤 드롭 정렬 로직
  void _onReorderSteps(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final step = _steps.removeAt(oldIndex);
      _steps.insert(newIndex, step);
      // 단계 번호 재정렬
      for (int i = 0; i < _steps.length; i++) {
        _steps[i]['stepNumber'] = i + 1;
      }
    });
  }

  /// Phase 7-3: Compute change diff between parent and current variation
  Map<String, dynamic>? _computeChangeDiff() {
    if (!isVariantMode) return null;

    // Track ingredient changes
    final removedIngredients = <String>[];
    final addedIngredients = <String>[];

    // Find removed ingredients (original items marked as deleted)
    for (final ing in _ingredients) {
      if (ing['isOriginal'] == true && ing['isDeleted'] == true) {
        removedIngredients.add('${ing['name']} ${ing['amount']}'.trim());
      }
    }

    // Find added ingredients (new items not deleted)
    for (final ing in _ingredients) {
      if (ing['isOriginal'] != true && ing['isDeleted'] != true) {
        final name = ing['name'] as String?;
        if (name != null && name.isNotEmpty) {
          addedIngredients.add('${ing['name']} ${ing['amount']}'.trim());
        }
      }
    }

    // Track step changes
    final removedSteps = <String>[];
    final addedSteps = <String>[];

    // Find removed steps (original items marked as deleted)
    for (final step in _steps) {
      if (step['isOriginal'] == true && step['isDeleted'] == true) {
        removedSteps.add(step['description'] as String? ?? '');
      }
    }

    // Find added steps (new items not deleted)
    for (final step in _steps) {
      if (step['isOriginal'] != true && step['isDeleted'] != true) {
        final desc = step['description'] as String?;
        if (desc != null && desc.isNotEmpty) {
          addedSteps.add(desc);
        }
      }
    }

    return {
      'ingredients': {
        'removed': removedIngredients,
        'added': addedIngredients,
        'modified': <Map<String, String>>[],
      },
      'steps': {
        'removed': removedSteps,
        'added': addedSteps,
        'modified': <Map<String, String>>[],
      },
    };
  }

  Future<void> _handleSubmit() async {
    if (isVariantMode && _changeReasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('recipe.changeReasonError'.tr())));
      return;
    }
    setState(() => _isLoading = true);
    try {
      // Phase 7-3: Compute change diff for variations
      final changeDiff = _computeChangeDiff();

      final request = CreateRecipeRequest(
        title: _titleController.text,
        description: _descriptionController.text,
        culinaryLocale: _localeController.text.isEmpty
            ? "ko"
            : _localeController.text,
        food1MasterPublicId: _food1MasterPublicId,
        newFoodName: isVariantMode ? null : _foodNameController.text.trim(),
        ingredients: _ingredients
            .where((i) => i['isDeleted'] != true)  // Exclude deleted items
            .map(
              (i) => Ingredient(
                name: i['name'],
                amount: i['amount'],
                type: i['type'],
              ),
            )
            .toList(),
        steps: _steps
            .where((s) => s['isDeleted'] != true)  // Exclude deleted items
            .map(
              (s) => RecipeStep(
                stepNumber: s['stepNumber'],
                description: s['description'],
                imagePublicId: s['imagePublicId'],
              ),
            )
            .toList(),
        imagePublicIds: _finishedImages
            .where((img) => img.status == UploadStatus.success)
            .map((img) => img.publicId!)
            .toList(),
        changeCategory: _changeReasonController.text,
        parentPublicId: widget.parentRecipe?.publicId,
        rootPublicId:
            widget.parentRecipe?.rootInfo?.publicId ??
            widget.parentRecipe?.publicId,
        changeDiff: changeDiff,
        changeReason: isVariantMode ? _changeReasonController.text.trim() : null,
        hashtags: _hashtags.isNotEmpty ? _hashtags : null,
      );

      // Use the new provider with analytics tracking
      await ref.read(recipeCreationProvider.notifier).createRecipe(request);

      if (!mounted) return;

      final state = ref.read(recipeCreationProvider);
      state.when(
        data: (newId) {
          if (newId != null) {
            // Clear draft on successful publish (skip for variants)
            if (!isVariantMode) {
              ref.read(recipeDraftProvider.notifier).clearDraft();
            }
            // Invalidate profile providers so they refresh when user visits profile
            ref.invalidate(myRecipesProvider);
            ref.invalidate(myProfileProvider);
            context.go(ApiEndpoints.recipeDetail(newId));
          }
        },
        error: (error, _) => ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('recipe.submitFailed'.tr(namedArgs: {'error': error.toString()})))),
        loading: () {},
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleClose();
      },
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          // Trigger save on unfocus (skip for variants)
          if (!isVariantMode) {
            _triggerSave();
          }
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: _buildAppBar(),
          body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    HookSection(
                      titleController: _titleController,
                      foodNameController: _foodNameController,
                      descriptionController: _descriptionController,
                      localeController: _localeController,
                      finishedImages: _finishedImages,
                      isReadOnly: isVariantMode, // 요리명 및 로케일 수정 불가 제약
                      // 💡 누락된 필수 파라미터 추가
                      onFoodPublicIdSelected: (publicId) =>
                          setState(() => _food1MasterPublicId = publicId),

                      onStateChanged: () => setState(() {}),
                    ),

                    const SizedBox(height: 24),
                    HashtagInputSection(
                      hashtags: _hashtags,
                      onHashtagsChanged: (tags) => setState(() {
                        _hashtags.clear();
                        _hashtags.addAll(tags);
                      }),
                    ),

                    if (isVariantMode) ...[
                      const SizedBox(height: 32),
                      _buildChangeReasonField(),
                    ],

                    const SizedBox(height: 32),
                    IngredientSection(
                      ingredients: _ingredients,
                      onAddIngredient: _addIngredient,
                      onRemoveIngredient: _onRemoveIngredient,
                      onRestoreIngredient: _onRestoreIngredient,
                    ),
                    const SizedBox(height: 32),
                    StepSection(
                      steps: _steps,
                      onAddStep: _addStep,
                      onAddMultipleSteps: _addMultipleSteps,
                      onRemoveStep: _onRemoveStep,
                      onRestoreStep: _onRestoreStep,
                      onReorder: _onReorderSteps,
                      onStateChanged: () => setState(() {}),
                    ),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
            _buildSubmitButton(),
          ],
        ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
    backgroundColor: Colors.white,
    leading: IconButton(
      icon: const Icon(Icons.close),
      onPressed: _handleClose,
    ),
    title: Text(isVariantMode ? 'recipe.createVariantTitle'.tr() : 'recipe.createNew'.tr()),
    actions: [
      // Show draft status indicator (only for new recipes, not variants)
      if (!isVariantMode)
        const Padding(
          padding: EdgeInsets.only(right: 16),
          child: DraftStatusIndicator(),
        ),
    ],
  );

  Widget _buildChangeReasonField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome, color: Colors.orange, size: 20),
            const SizedBox(width: 8),
            Text(
              'recipe.changeReasonRequired'.tr(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange[100]!),
          ),
          child: TextField(
            controller: _changeReasonController, // 💡 사용자가 언급한 컨트롤러 연결
            onChanged: (_) => setState(() {}), // 💡 입력 시 등록 버튼 활성화를 위해 호출
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'recipe.changeReasonHint'.tr(),
              hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    final bool hasBaseInfo =
        _titleController.text.isNotEmpty && _ingredients.isNotEmpty;

    // 2. 변형 모드일 경우 변경 이유 입력 여부 체크
    final bool hasChangeReason =
        !isVariantMode || _changeReasonController.text.trim().isNotEmpty;

    // 💡 두 조건이 모두 충족되어야 버튼 활성화
    final bool isReady = hasBaseInfo && hasChangeReason;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: isReady && !_isLoading ? _handleSubmit : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A237E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            _isLoading ? 'recipe.submitting'.tr() : 'recipe.submit'.tr(),
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
