import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/core/widgets/app_cached_image.dart';
import 'package:pairing_planet2_frontend/core/widgets/login_prompt_sheet.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_detail.dart';
import 'package:pairing_planet2_frontend/features/auth/providers/auth_provider.dart';
import 'package:pairing_planet2_frontend/features/log_post/presentation/widgets/quick_log_sheet.dart';
import 'package:pairing_planet2_frontend/features/log_post/providers/quick_log_draft_provider.dart';
import '../../providers/recipe_providers.dart';
import '../widgets/lineage_breadcrumb.dart';
import '../widgets/recent_logs_gallery.dart';
import '../widgets/variants_gallery.dart';
import '../widgets/hashtag_chips.dart';
import '../widgets/share_bottom_sheet.dart';
import '../widgets/locale_badge.dart';
// Living Blueprint widgets
import '../widgets/kitchen_proof_ingredients.dart';
import '../widgets/change_diff_section.dart';
import '../widgets/recipe_family_section.dart';
import '../widgets/action_hub_bar.dart';

class RecipeDetailScreen extends ConsumerStatefulWidget {
  final String recipeId;
  const RecipeDetailScreen({super.key, required this.recipeId});

  @override
  ConsumerState<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends ConsumerState<RecipeDetailScreen> {
  bool _saveStateInitialized = false;

  @override
  Widget build(BuildContext context) {
    // Use the tracking provider to log recipe views
    final recipeAsync = ref.watch(recipeDetailWithTrackingProvider(widget.recipeId));
    final saveState = ref.watch(saveRecipeProvider(widget.recipeId));

    // P1: 레시피 데이터 로드 시 저장 상태 초기화
    ref.listen(recipeDetailWithTrackingProvider(widget.recipeId), (_, next) {
      next.whenData((recipe) {
        if (!_saveStateInitialized && recipe.isSavedByCurrentUser != null) {
          ref.read(saveRecipeProvider(widget.recipeId).notifier)
              .setInitialState(recipe.isSavedByCurrentUser!);
          _saveStateInitialized = true;
        }
      });
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('recipe.detail'.tr()),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          // Share button
          recipeAsync.maybeWhen(
            data: (recipe) => IconButton(
              icon: Icon(Icons.share, color: Colors.grey[600]),
              onPressed: () {
                ShareBottomSheet.show(
                  context,
                  recipePublicId: widget.recipeId,
                  recipeTitle: recipe.title,
                );
              },
            ),
            orElse: () => IconButton(
              icon: Icon(Icons.share, color: Colors.grey[400]),
              onPressed: null,
            ),
          ),
          // P1: 북마크 버튼
          saveState.when(
            data: (isSaved) => IconButton(
              icon: Icon(
                isSaved ? Icons.bookmark : Icons.bookmark_border,
                color: isSaved ? AppColors.primary : Colors.grey[600],
              ),
              onPressed: () {
                final authStatus = ref.read(authStateProvider).status;
                if (authStatus != AuthStatus.authenticated) {
                  LoginPromptSheet.show(
                    context: context,
                    actionKey: 'guest.signInToSave',
                    pendingAction: () {
                      ref.read(saveRecipeProvider(widget.recipeId).notifier).toggle();
                    },
                  );
                  return;
                }
                ref.read(saveRecipeProvider(widget.recipeId).notifier).toggle();
              },
            ),
            loading: () => const Padding(
              padding: EdgeInsets.all(12.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (_, __) => IconButton(
              icon: Icon(Icons.bookmark_border, color: Colors.grey[400]),
              onPressed: null,
            ),
          ),
        ],
      ),
      body: recipeAsync.when(
        data: (recipe) => Column(
          children: [
            // Lineage breadcrumb at TOP (for variant recipes)
            LineageBreadcrumb(
              rootInfo: recipe.rootInfo,
              parentInfo: recipe.parentInfo,
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImageHeader(recipe),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLineageTag(recipe),
                          const SizedBox(height: 12),
                          Text(
                            "[${recipe.foodName}]",
                            style: TextStyle(
                              fontSize: 18,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  recipe.title,
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              LocaleBadgeLarge(localeCode: recipe.culinaryLocale),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            recipe.description ?? "",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                              height: 1.5,
                            ),
                          ),
                          // Hashtags section
                          if (recipe.hashtags.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            HashtagChips(hashtags: recipe.hashtags),
                          ],
                        ],
                      ),
                    ),
                    // Recipe Family Section (for variant recipes - star layout)
                    if (recipe.isVariant && recipe.rootInfo != null) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: RecipeFamilySection(
                          rootInfo: recipe.rootInfo!,
                          allVariants: recipe.variants,
                          currentRecipeId: recipe.publicId,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    // Change Diff Section (for variant recipes)
                    if (recipe.isVariant && recipe.hasChanges) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: ChangeDiffSection(
                          changeDiff: recipe.changeDiff!,
                          changeCategories: recipe.changeCategories,
                          changeReason: recipe.changeReason,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    // Kitchen-Proof Ingredients Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: KitchenProofIngredients(
                        ingredients: recipe.ingredients,
                        changeDiff: recipe.changeDiff,
                        showDiffBadges: recipe.isVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Steps Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.format_list_numbered, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'recipe.steps'.tr(),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ...recipe.steps.map((step) => _buildStepItem(step)),
                        ],
                      ),
                    ),
                    // Variants Gallery section (only for ROOT recipes with variants)
                    if (recipe.variants.isNotEmpty && !recipe.isVariant) ...[
                      const SizedBox(height: 24),
                      VariantsGallery(
                        variants: recipe.variants,
                        recipeId: recipe.publicId,
                      ),
                    ],
                    // Recent Logs Gallery section
                    const SizedBox(height: 24),
                    RecentLogsGallery(
                      logs: recipe.logs,
                      recipeId: recipe.publicId,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            // Action Hub Bar
            ActionHubBar(
              onLogPressed: () => _handleLogPress(context, recipe),
              onVariationPressed: () => _handleVariationPress(context, recipe),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('common.errorWithMessage'.tr(namedArgs: {'message': err.toString()})),
              const SizedBox(height: 16),
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

  // Handle log button press - opens QuickLogSheet with pre-selected recipe
  void _handleLogPress(BuildContext context, RecipeDetail recipe) {
    final authStatus = ref.read(authStateProvider).status;
    if (authStatus != AuthStatus.authenticated) {
      LoginPromptSheet.show(
        context: context,
        actionKey: 'guest.signInToCreate',
        pendingAction: () {
          _showQuickLogSheet(context, recipe);
        },
      );
      return;
    }
    _showQuickLogSheet(context, recipe);
  }

  // Show QuickLogSheet with recipe pre-selected
  void _showQuickLogSheet(BuildContext context, RecipeDetail recipe) {
    HapticFeedback.mediumImpact();
    // Pre-select the recipe before showing the sheet
    ref.read(quickLogDraftProvider.notifier).startFlowWithRecipe(
      recipe.publicId,
      recipe.title,
    );
    QuickLogSheet.show(context);
  }

  // Handle variation button press
  void _handleVariationPress(BuildContext context, RecipeDetail recipe) {
    final authStatus = ref.read(authStateProvider).status;
    if (authStatus != AuthStatus.authenticated) {
      LoginPromptSheet.show(
        context: context,
        actionKey: 'guest.signInToCreate',
        pendingAction: () {
          context.push(RouteConstants.recipeCreate, extra: recipe);
        },
      );
      return;
    }
    context.push(RouteConstants.recipeCreate, extra: recipe);
  }

  Widget _buildLineageTag(RecipeDetail recipe) {
    final isVariant = recipe.parentInfo != null || recipe.rootInfo != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isVariant ? Colors.orange[50] : AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isVariant ? 'recipe.variantRecipe'.tr() : 'recipe.originalRecipe'.tr(),
        style: TextStyle(
          color: isVariant ? Colors.orange[800] : AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStepItem(dynamic step) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: AppColors.primary,
                child: Text(
                  "${step.stepNumber}",
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              const SizedBox(width: 12),
              Text('steps.step'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          if (step.imageUrl != null && step.imageUrl!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCachedImage(
                imageUrl: step.imageUrl!,
                width: double.infinity,
                height: 200,
                borderRadius: 12,
              ),
            ),
          Text(
            step.description,
            style: const TextStyle(fontSize: 15, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildImageHeader(RecipeDetail recipe) {
    return AppCachedImage(
      imageUrl: recipe.imageUrls.isNotEmpty
          ? recipe.imageUrls.first
          : 'https://via.placeholder.com/400x250',
      width: double.infinity,
      height: 300,
      borderRadius: 0,
    );
  }
}
