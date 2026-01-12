import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_detail.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/update_recipe_request.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/ingredient.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_step.dart';
import 'package:pairing_planet2_frontend/features/recipe/presentation/widgets/ingredient_section.dart';
import 'package:pairing_planet2_frontend/features/recipe/providers/recipe_providers.dart';
import 'package:pairing_planet2_frontend/shared/data/model/upload_item_model.dart';
import '../widgets/hook_section.dart';
import '../widgets/step_section.dart';
import '../widgets/hashtag_input_section.dart';
import '../widgets/servings_cooking_time_section.dart';

/// Recipe edit screen for modifying an existing recipe.
/// Only available when the recipe has no child variants or associated logs.
class RecipeEditScreen extends ConsumerStatefulWidget {
  final String recipeId;

  const RecipeEditScreen({super.key, required this.recipeId});

  @override
  ConsumerState<RecipeEditScreen> createState() => _RecipeEditScreenState();
}

class _RecipeEditScreenState extends ConsumerState<RecipeEditScreen> {
  final _titleController = TextEditingController();
  final _foodNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _localeController = TextEditingController();

  final List<Map<String, dynamic>> _ingredients = [];
  final List<Map<String, dynamic>> _steps = [];
  final List<UploadItem> _finishedImages = [];
  final List<Map<String, dynamic>> _hashtags = [];

  bool _isLoading = false;
  bool _dataInitialized = false;

  // Servings and cooking time
  int _servings = 2;
  String _cookingTimeRange = 'MIN_30_TO_60';

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_rebuild);
    _foodNameController.addListener(_rebuild);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _foodNameController.dispose();
    _descriptionController.dispose();
    _localeController.dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  /// Initialize form with existing recipe data
  void _initializeFromRecipe(RecipeDetail recipe) {
    if (_dataInitialized) return;
    _dataInitialized = true;

    _titleController.text = recipe.title;
    _descriptionController.text = recipe.description ?? '';
    _foodNameController.text = recipe.foodName;
    _localeController.text = recipe.culinaryLocale ?? 'ko-KR';

    // Load ingredients
    for (var ing in recipe.ingredients) {
      _ingredients.add({
        'name': ing.name,
        'amount': ing.amount,
        'quantity': ing.quantity,
        'unit': ing.unit,
        'type': ing.type,
        'isOriginal': false, // Not variant mode
        'isDeleted': false,
      });
    }

    // Load steps
    for (var step in recipe.steps) {
      _steps.add({
        'stepNumber': step.stepNumber,
        'description': step.description,
        'imageUrl': step.imageUrl,
        'imagePublicId': step.imagePublicId,
        'uploadItem': null,
        'isOriginal': false, // Not variant mode
        'isDeleted': false,
      });
    }

    // Load images as UploadItems (already uploaded, so we mark them as success)
    for (int i = 0; i < recipe.imageUrls.length; i++) {
      final imageUrl = recipe.imageUrls[i];
      final publicId = i < recipe.imagePublicIds.length ? recipe.imagePublicIds[i] : null;
      _finishedImages.add(UploadItem(
        file: File(''), // Placeholder - image already uploaded
        status: UploadStatus.success,
        serverUrl: imageUrl,
        publicId: publicId,
      ));
    }

    // Load hashtags as map structure (no isOriginal in edit mode)
    for (final tag in recipe.hashtags) {
      _hashtags.add({
        'name': tag.name,
        'isOriginal': false,
        'isDeleted': false,
      });
    }

    // Load servings and cooking time
    _servings = recipe.servings;
    _cookingTimeRange = recipe.cookingTimeRange;
  }

  /// Extract active (non-deleted) hashtag names as a string list for API
  List<String>? _getActiveHashtagNames() {
    final active = _hashtags
        .where((h) => h['isDeleted'] != true)
        .map((h) => h['name'] as String)
        .toList();
    return active.isNotEmpty ? active : null;
  }

  void _addIngredient(String type) {
    setState(() {
      _ingredients.add({
        'name': '',
        'amount': null,
        'quantity': null,
        'unit': null,
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

  void _onReorderSteps(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final step = _steps.removeAt(oldIndex);
      _steps.insert(newIndex, step);
      // Renumber steps
      for (int i = 0; i < _steps.length; i++) {
        _steps[i]['stepNumber'] = i + 1;
      }
    });
  }

  Future<void> _handleSubmit() async {
    setState(() => _isLoading = true);
    try {
      final request = UpdateRecipeRequest(
        title: _titleController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        culinaryLocale: _localeController.text.isEmpty
            ? 'ko-KR'
            : _localeController.text,
        ingredients: _ingredients
            .where((i) => i['isDeleted'] != true)
            .map(
              (i) => Ingredient(
                name: i['name'],
                amount: i['amount'],
                quantity: i['quantity'] as double?,
                unit: i['unit'] as String?,
                type: i['type'],
              ),
            )
            .toList(),
        steps: _steps
            .where((s) => s['isDeleted'] != true)
            .map(
              (s) => RecipeStep(
                stepNumber: s['stepNumber'],
                description: s['description'],
                imagePublicId: s['imagePublicId'],
              ),
            )
            .toList(),
        imagePublicIds: _finishedImages
            .where((img) => img.status == UploadStatus.success && img.publicId != null)
            .map((img) => img.publicId!)
            .toList(),
        hashtags: _getActiveHashtagNames(),
        servings: _servings,
        cookingTimeRange: _cookingTimeRange,
      );

      await ref.read(recipeUpdateProvider.notifier).updateRecipe(
            widget.recipeId,
            request,
          );

      if (!mounted) return;

      final state = ref.read(recipeUpdateProvider);
      state.when(
        data: (updatedRecipe) {
          if (updatedRecipe != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('recipe.updated'.tr())),
            );
            // Invalidate the recipe detail provider to refresh data
            ref.invalidate(recipeDetailProvider(widget.recipeId));
            // Navigate back to detail screen
            context.pop();
          }
        },
        error: (error, _) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('common.errorWithMessage'.tr(namedArgs: {'message': error.toString()})),
          ),
        ),
        loading: () {},
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleClose() {
    if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipeAsync = ref.watch(recipeDetailProvider(widget.recipeId));

    return recipeAsync.when(
      data: (recipe) {
        // Initialize form data when recipe loads
        _initializeFromRecipe(recipe);

        return PopScope(
          canPop: true,
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Scaffold(
              backgroundColor: Colors.white,
              appBar: _buildAppBar(),
              body: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Column(
                        children: [
                          HookSection(
                            titleController: _titleController,
                            foodNameController: _foodNameController,
                            descriptionController: _descriptionController,
                            localeController: _localeController,
                            finishedImages: _finishedImages,
                            isReadOnly: true, // Food name and locale can't be changed in edit mode
                            onFoodPublicIdSelected: (_) {}, // No-op for edit mode
                            onStateChanged: () => setState(() {}),
                            onReorder: (oldIndex, newIndex) {
                              setState(() {
                                if (newIndex > oldIndex) newIndex--;
                                final item = _finishedImages.removeAt(oldIndex);
                                _finishedImages.insert(newIndex, item);
                              });
                            },
                          ),
                          SizedBox(height: 32.h),
                          ServingsCookingTimeSection(
                            servings: _servings,
                            cookingTimeRange: _cookingTimeRange,
                            onServingsChanged: (value) => setState(() => _servings = value),
                            onCookingTimeChanged: (value) => setState(() => _cookingTimeRange = value),
                          ),
                          SizedBox(height: 24.h),
                          HashtagInputSection(
                            hashtags: _hashtags,
                            onHashtagsChanged: (tags) => setState(() {
                              _hashtags.clear();
                              _hashtags.addAll(tags);
                            }),
                          ),
                          SizedBox(height: 32.h),
                          IngredientSection(
                            ingredients: _ingredients,
                            onAddIngredient: _addIngredient,
                            onRemoveIngredient: _onRemoveIngredient,
                            onRestoreIngredient: _onRestoreIngredient,
                          ),
                          SizedBox(height: 32.h),
                          StepSection(
                            steps: _steps,
                            onAddStep: _addStep,
                            onAddMultipleSteps: _addMultipleSteps,
                            onRemoveStep: _onRemoveStep,
                            onRestoreStep: _onRestoreStep,
                            onReorder: _onReorderSteps,
                            onStateChanged: () => setState(() {}),
                          ),
                          SizedBox(height: 120.h),
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
      },
      loading: () => Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('common.errorWithMessage'.tr(namedArgs: {'message': err.toString()})),
              SizedBox(height: 16.h),
              ElevatedButton(
                onPressed: () => ref.refresh(recipeDetailProvider(widget.recipeId)),
                child: Text('common.tryAgain'.tr()),
              ),
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
        title: Text('recipe.editTitle'.tr()),
      );

  Widget _buildSubmitButton() {
    final bool hasBaseInfo =
        _titleController.text.isNotEmpty && _ingredients.isNotEmpty;

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 30.h),
      child: SizedBox(
        width: double.infinity,
        height: 56.h,
        child: ElevatedButton(
          onPressed: hasBaseInfo && !_isLoading ? _handleSubmit : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
          ),
          child: Text(
            _isLoading ? 'recipe.updating'.tr() : 'recipe.update'.tr(),
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
