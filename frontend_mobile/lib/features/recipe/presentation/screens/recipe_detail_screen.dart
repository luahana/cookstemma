import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/core/constants/cooking_time_range.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/core/widgets/app_cached_image.dart';
import 'package:pairing_planet2_frontend/core/widgets/login_prompt_sheet.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_detail.dart';
import 'package:pairing_planet2_frontend/features/auth/providers/auth_provider.dart';
import 'package:pairing_planet2_frontend/features/profile/providers/profile_provider.dart';
import 'package:pairing_planet2_frontend/features/log_post/presentation/widgets/quick_log_sheet.dart';
import 'package:pairing_planet2_frontend/features/log_post/providers/quick_log_draft_provider.dart';
import '../../providers/recipe_providers.dart';
import '../widgets/recent_logs_gallery.dart';
import '../widgets/hashtag_chips.dart';
import '../widgets/share_bottom_sheet.dart';
import '../widgets/locale_badge.dart';
// Living Blueprint widgets
import '../widgets/kitchen_proof_ingredients.dart';
import '../widgets/change_diff_section.dart';
import '../widgets/recipe_family_section.dart';
import '../widgets/action_hub_bar.dart';
import '../widgets/recipe_action_menu.dart';
import 'cooking_mode_screen.dart';

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
        title: recipeAsync.maybeWhen(
          data: (recipe) => Text(recipe.foodName, overflow: TextOverflow.ellipsis),
          orElse: () => Text('recipe.detail'.tr()),
        ),
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
            loading: () => Padding(
              padding: EdgeInsets.all(12.r),
              child: SizedBox(
                width: 24.w,
                height: 24.w,
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (_, _) => IconButton(
              icon: Icon(Icons.bookmark_border, color: Colors.grey[400]),
              onPressed: null,
            ),
          ),
          // Recipe action menu (edit/delete) - only shown for owner
          RecipeActionMenu(recipePublicId: widget.recipeId),
        ],
      ),
      body: recipeAsync.when(
        data: (recipe) => Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImageHeader(recipe),
                    Padding(
                      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _buildLineageTag(recipe),
                              SizedBox(width: 8.w),
                              LocaleBadgeStyled(localeCode: recipe.culinaryLocale),
                            ],
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            recipe.title,
                            style: TextStyle(
                              fontSize: 26.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          GestureDetector(
                            onTap: recipe.creatorPublicId != null
                                ? () {
                                    HapticFeedback.selectionClick();
                                    // Check if this is the current user's own profile
                                    final myProfile = ref.read(myProfileProvider);
                                    final isOwnProfile = myProfile.maybeWhen(
                                      data: (profile) => profile.user.id == recipe.creatorPublicId,
                                      orElse: () => false,
                                    );

                                    if (isOwnProfile) {
                                      // Navigate to My Profile tab to avoid key conflicts
                                      context.go(RouteConstants.profile);
                                    } else {
                                      // Navigate to other user's profile
                                      context.push(RouteConstants.userProfilePath(recipe.creatorPublicId!));
                                    }
                                  }
                                : null,
                            child: Text(
                              'recipe.by'.tr(args: [recipe.creatorName]),
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: recipe.creatorPublicId != null ? AppColors.primary : Colors.grey[600],
                                fontWeight: recipe.creatorPublicId != null ? FontWeight.w500 : FontWeight.normal,
                              ),
                            ),
                          ),
                          SizedBox(height: 12.h),
                          // Servings and cooking time info
                          Row(
                            children: [
                              Icon(Icons.people_outline, size: 16.sp, color: Colors.grey[600]),
                              SizedBox(width: 4.w),
                              Text(
                                'recipe.servings.count'.tr(namedArgs: {'count': recipe.servings.toString()}),
                                style: TextStyle(fontSize: 13.sp, color: Colors.grey[600]),
                              ),
                              SizedBox(width: 16.w),
                              Icon(Icons.timer_outlined, size: 16.sp, color: Colors.grey[600]),
                              SizedBox(width: 4.w),
                              Text(
                                CookingTimeRange.fromCode(recipe.cookingTimeRange).translationKey.tr(),
                                style: TextStyle(fontSize: 13.sp, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                          if (!recipe.isVariant && recipe.description != null && recipe.description!.isNotEmpty) ...[
                            SizedBox(height: 20.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '"',
                                  style: TextStyle(
                                    fontSize: 28.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                    height: 0.8,
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Flexible(
                                  child: Text(
                                    recipe.description ?? "",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 15.sp,
                                      fontStyle: FontStyle.italic,
                                      color: AppColors.primary,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  '"',
                                  style: TextStyle(
                                    fontSize: 28.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                    height: 0.8,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12.h),
                          ],
                        ],
                      ),
                    ),
                    // Hashtags section (after metadata, Instagram-style no header)
                    if (recipe.hashtags.isNotEmpty) ...[
                      SizedBox(height: 12.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: HashtagChips(
                          hashtags: recipe.hashtags,
                          onHashtagTap: (tag) {
                            context.push('${RouteConstants.search}?q=%23$tag');
                          },
                        ),
                      ),
                    ],
                    // Recipe Family Section (for variant recipes - star layout)
                    // Recipe Family Section
                    // - For variants: Shows "Based on" with root recipe
                    // - For originals: Shows "Variations" (with empty state if none)
                    if (recipe.rootInfo != null || !recipe.isVariant) ...[
                      SizedBox(height: 20.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: RecipeFamilySection(
                          isOriginal: !recipe.isVariant,
                          rootInfo: recipe.rootInfo,
                          variants: recipe.variants,
                          currentRecipeId: recipe.publicId,
                        ),
                      ),
                      SizedBox(height: 20.h),
                    ],
                    // Change Reason Section (for variant recipes)
                    if (recipe.isVariant && recipe.changeReason != null && recipe.changeReason!.isNotEmpty) ...[
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 40.w),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '"',
                              style: TextStyle(
                                fontSize: 28.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                height: 0.8,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Flexible(
                              child: Text(
                                recipe.changeReason!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.primary,
                                  height: 1.5,
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              '"',
                              style: TextStyle(
                                fontSize: 28.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                height: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 12.h),
                    ],
                    // Change Diff Section (for variant recipes)
                    if (recipe.isVariant && recipe.hasChanges) ...[
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: ChangeDiffSection(
                          changeDiff: recipe.changeDiff!,
                        ),
                      ),
                      SizedBox(height: 20.h),
                    ],
                    // Kitchen-Proof Ingredients Section
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: KitchenProofIngredients(
                        ingredients: recipe.ingredients,
                      ),
                    ),
                    SizedBox(height: 24.h),
                    // Steps Section - header outside, content in box (matching Ingredients style)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header outside box
                          Row(
                            children: [
                              Icon(Icons.format_list_numbered, size: 20.sp),
                              SizedBox(width: 8.w),
                              Text(
                                'recipe.steps'.tr(),
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12.h),
                          // Steps content in box
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(color: AppColors.border),
                            ),
                            padding: EdgeInsets.all(16.r),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: recipe.steps.asMap().entries.map((entry) => _buildStepItem(entry.value, entry.key + 1)).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Recent Logs Gallery section
                    SizedBox(height: 24.h),
                    RecentLogsGallery(
                      logs: recipe.logs,
                      recipeId: recipe.publicId,
                    ),
                    SizedBox(height: 20.h),
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
            // FAB for cooking mode - positioned right side, 1/3 from bottom
            if (recipe.steps.isNotEmpty)
              Positioned(
                right: 16.w,
                bottom: MediaQuery.of(context).size.height / 3,
                child: FloatingActionButton(
                  onPressed: () => _handleCookingPress(context, recipe),
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.restaurant_menu, size: 24.sp, color: Colors.white),
                ),
              ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
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

  // Handle cooking mode button press
  void _handleCookingPress(BuildContext context, RecipeDetail recipe) {
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CookingModeScreen(
          steps: recipe.steps,
          ingredients: recipe.ingredients,
          recipeName: recipe.title,
        ),
      ),
    );
  }

  Widget _buildLineageTag(RecipeDetail recipe) {
    final isVariant = recipe.parentInfo != null || recipe.rootInfo != null;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: isVariant ? Colors.orange[50] : AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        isVariant ? 'recipe.variantRecipe'.tr() : 'recipe.originalRecipe'.tr(),
        style: TextStyle(
          color: isVariant ? Colors.orange[800] : AppColors.primary,
          fontSize: 12.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStepItem(dynamic step, int stepNumber) {
    return Padding(
      padding: EdgeInsets.only(bottom: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12.r,
                backgroundColor: AppColors.primary,
                child: Text(
                  "$stepNumber",
                  style: TextStyle(color: Colors.white, fontSize: 12.sp),
                ),
              ),
              SizedBox(width: 12.w),
              Text('steps.step'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 12.h),
          if (step.imageUrl != null && step.imageUrl!.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: AppCachedImage(
                imageUrl: step.imageUrl!,
                width: double.infinity,
                height: 200.h,
                borderRadius: 12.r,
              ),
            ),
          Text(
            step.description,
            style: TextStyle(fontSize: 15.sp, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildImageHeader(RecipeDetail recipe) {
    if (recipe.imageUrls.isEmpty) {
      return AppCachedImage(
        imageUrl: 'https://via.placeholder.com/400x250',
        width: double.infinity,
        height: 300.h,
        borderRadius: 0,
      );
    }

    if (recipe.imageUrls.length == 1) {
      return AppCachedImage(
        imageUrl: recipe.imageUrls.first,
        width: double.infinity,
        height: 300.h,
        borderRadius: 0,
      );
    }

    // Multiple images - show carousel
    return _ImageCarousel(
      imageUrls: recipe.imageUrls,
      height: 300.h,
    );
  }
}

class _ImageCarousel extends StatefulWidget {
  final List<String> imageUrls;
  final double height;

  const _ImageCarousel({
    required this.imageUrls,
    required this.height,
  });

  @override
  State<_ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<_ImageCarousel> {
  int _currentIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imageUrls.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemBuilder: (context, index) {
              return AppCachedImage(
                imageUrl: widget.imageUrls[index],
                width: double.infinity,
                height: widget.height,
                borderRadius: 0,
              );
            },
          ),
          // Page indicator dots
          Positioned(
            bottom: 12.h,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.imageUrls.length,
                (index) => Container(
                  margin: EdgeInsets.symmetric(horizontal: 4.w),
                  width: _currentIndex == index ? 10.w : 8.w,
                  height: _currentIndex == index ? 10.w : 8.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentIndex == index
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
