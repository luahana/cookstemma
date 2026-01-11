import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/features/recipe/presentation/widgets/enhanced_recipe_card.dart';
import 'package:pairing_planet2_frontend/features/recipe/providers/recipe_providers.dart';

/// Screen for viewing all variations of a recipe.
/// Accessed via "View All" button in RecipeFamilySection.
class RecipeVariationsScreen extends ConsumerWidget {
  final String rootRecipeId;

  const RecipeVariationsScreen({super.key, required this.rootRecipeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipeAsync = ref.watch(recipeDetailProvider(rootRecipeId));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'recipe.family.variations'.tr(),
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: recipeAsync.when(
        data: (recipe) {
          final variants = recipe.variants;

          if (variants.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.fork_right, size: 64.sp, color: Colors.grey[300]),
                  SizedBox(height: 16.h),
                  Text(
                    'recipe.noVariations'.tr(),
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16.r),
            itemCount: variants.length + 1, // +1 for footer
            itemBuilder: (context, index) {
              if (index == variants.length) {
                // Footer - "all loaded" message
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.h),
                  child: Center(
                    child: Text(
                      'recipe.allLoaded'.tr(),
                      style: TextStyle(color: Colors.grey, fontSize: 13.sp),
                    ),
                  ),
                );
              }

              final variant = variants[index];
              return EnhancedRecipeCard(
                recipe: variant,
                onTap: () => context.push(
                  RouteConstants.recipeDetailPath(variant.publicId),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('common.errorWithMessage'.tr(namedArgs: {'message': error.toString()})),
              SizedBox(height: 16.h),
              ElevatedButton(
                onPressed: () => ref.refresh(recipeDetailProvider(rootRecipeId)),
                child: Text('common.tryAgain'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
