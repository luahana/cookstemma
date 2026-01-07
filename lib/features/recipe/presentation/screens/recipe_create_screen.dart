import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/create_recipe_request.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/ingredient.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_step.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_detail.dart'; // 💡 추가
import 'package:pairing_planet2_frontend/features/recipe/presentation/widgets/ingredient_section.dart';
import 'package:pairing_planet2_frontend/features/recipe/providers/recipe_providers.dart';
import 'package:pairing_planet2_frontend/features/profile/providers/profile_provider.dart';
import 'package:pairing_planet2_frontend/shared/data/model/upload_item_model.dart';
import '../widgets/hook_section.dart';
import '../widgets/step_section.dart';
import '../widgets/hashtag_input_section.dart';

class RecipeCreateScreen extends ConsumerStatefulWidget {
  final RecipeDetail? parentRecipe; // 💡 변경: ID 대신 객체 수신

  const RecipeCreateScreen({super.key, this.parentRecipe});

  @override
  ConsumerState<RecipeCreateScreen> createState() => _RecipeCreateScreenState();
}

class _RecipeCreateScreenState extends ConsumerState<RecipeCreateScreen> {
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

  @override
  void initState() {
    super.initState();
    if (isVariantMode) {
      _initVariantData(); // 💡 변형 데이터 초기화
    } else {
      _addIngredient('MAIN');
      _addStep();
    }
    _titleController.addListener(_rebuild);
    _foodNameController.addListener(_rebuild);
  }

  void _initVariantData() {
    final p = widget.parentRecipe!;
    _titleController.text = "${p.title} (변형)";
    _descriptionController.text = p.description ?? "";
    _foodNameController.text = p.foodName; // 💡 실제 요리명 매핑 권장

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
    _titleController.dispose();
    _foodNameController.dispose();
    _descriptionController.dispose();
    _localeController.dispose();
    _changeReasonController.dispose();
    super.dispose();
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
      ).showSnackBar(const SnackBar(content: Text('레시피를 변형한 이유를 입력해주세요.')));
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
            // Invalidate profile providers so they refresh when user visits profile
            ref.invalidate(myRecipesProvider);
            ref.invalidate(myProfileProvider);
            context.go(ApiEndpoints.recipeDetail(newId));
          }
        },
        error: (error, _) => ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('실패: $error'))),
        loading: () {},
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
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
                      finishedImages: _finishedImages,
                      isReadOnly: isVariantMode, // 요리명 수정 불가 제약
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
    );
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
    backgroundColor: Colors.white,
    leading: IconButton(
      icon: const Icon(Icons.close),
      onPressed: () => context.pop(),
    ),
    title: Text(isVariantMode ? "레시피 변형하기" : "새 레시피 등록"),
  );

  Widget _buildChangeReasonField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome, color: Colors.orange, size: 20),
            const SizedBox(width: 8),
            const Text(
              "변경 이유 (필수)",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
            decoration: const InputDecoration(
              hintText: "예: 더 매콤한 맛을 위해 청양고추를 추가하고 조리 순서를 바꿨어요.",
              hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
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
            _isLoading ? "등록 중..." : "등록 완료",
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
