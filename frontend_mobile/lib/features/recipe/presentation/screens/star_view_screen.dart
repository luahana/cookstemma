import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/features/recipe/presentation/widgets/recipe_star_view.dart';
import 'package:pairing_planet2_frontend/features/recipe/providers/recipe_star_provider.dart';

/// Full-screen star visualization for a recipe family
class StarViewScreen extends ConsumerWidget {
  final String recipeId;

  const StarViewScreen({
    super.key,
    required this.recipeId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final starDataAsync = ref.watch(recipeStarProvider(recipeId));

    return Scaffold(
      body: starDataAsync.when(
        data: (starData) {
          if (starData.variants.isEmpty) {
            return _buildEmptyState(context);
          }

          return RecipeStarView(
            rootRecipe: starData.rootRecipe,
            variants: starData.variants,
            onBackPressed: () => context.pop(),
            onNodeSelected: (recipe) {
              ref.read(selectedStarNodeProvider.notifier).state = recipe;
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => _buildErrorState(context, error, ref),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(16.r),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Text(
                      'star.title'.tr(),
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Empty state
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 64.sp,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'star.noVariants'.tr(),
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'star.createFirst'.tr(),
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error, WidgetRef ref) {
    return Container(
      color: Colors.grey[100],
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(16.r),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Text(
                      'star.title'.tr(),
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Error state
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48.sp,
                      color: Colors.red,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'common.errorWithMessage'.tr(namedArgs: {'message': error.toString()}),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    SizedBox(height: 16.h),
                    TextButton(
                      onPressed: () => ref.invalidate(recipeStarProvider(recipeId)),
                      child: Text('common.tryAgain'.tr()),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
