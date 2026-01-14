import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/ingredient.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_step.dart';
import 'package:keep_screen_on/keep_screen_on.dart';
import '../../providers/cooking_mode_provider.dart';
import '../widgets/cooking_ingredients_sheet.dart';
import '../widgets/cooking_step_view.dart';

/// Full-screen cooking mode with step-by-step navigation
/// Includes timer per step and ingredients checklist
class CookingModeScreen extends ConsumerStatefulWidget {
  final List<RecipeStep> steps;
  final List<Ingredient> ingredients;
  final String recipeName;

  const CookingModeScreen({
    super.key,
    required this.steps,
    required this.ingredients,
    required this.recipeName,
  });

  @override
  ConsumerState<CookingModeScreen> createState() => _CookingModeScreenState();
}

class _CookingModeScreenState extends ConsumerState<CookingModeScreen> {
  late PageController _pageController;
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Keep screen awake during cooking
    KeepScreenOn.turnOn();

    // Initialize provider state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cookingModeProvider.notifier).initialize(
            steps: widget.steps,
            ingredients: widget.ingredients,
          );

      // Set up timer completion callback
      ref.read(cookingModeProvider.notifier).onTimerComplete = _onTimerComplete;
    });
  }

  @override
  void dispose() {
    // Disable screen awake when leaving cooking mode
    KeepScreenOn.turnOff();
    _pageController.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  void _onTimerComplete(int stepIndex) {
    // Vibrate and show snackbar when timer completes
    HapticFeedback.heavyImpact();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'cooking.timerCompleteForStep'.tr(
            namedArgs: {'step': (stepIndex + 1).toString()},
          ),
        ),
        backgroundColor: AppColors.growth,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _onPageChanged(int index) {
    ref.read(cookingModeProvider.notifier).goToStep(index);
  }

  void _goToNextStep() {
    final state = ref.read(cookingModeProvider);
    if (state.hasNextStep) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _showCompletionDialog();
    }
  }

  void _goToPreviousStep() {
    final state = ref.read(cookingModeProvider);
    if (state.hasPreviousStep) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showCompletionDialog() {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('cooking.completeTitle'.tr()),
        content: Text('cooking.completeMessage'.tr()),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(cookingModeProvider.notifier).cleanup();
              context.pop();
            },
            child: Text('cooking.finish'.tr()),
          ),
        ],
      ),
    );
  }

  void _exitCookingMode() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('cooking.exitTitle'.tr()),
        content: Text('cooking.exitMessage'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(cookingModeProvider.notifier).cleanup();
              context.pop();
            },
            child: Text('cooking.exit'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cookingState = ref.watch(cookingModeProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _exitCookingMode();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(cookingState),
        body: Stack(
          children: [
            // Main content with PageView
            Column(
              children: [
                // Progress indicator
                _buildProgressIndicator(cookingState),

                // Step PageView
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    itemCount: widget.steps.length,
                    itemBuilder: (context, index) => CookingStepView(
                      step: widget.steps[index],
                      stepIndex: index,
                    ),
                  ),
                ),

                // Navigation buttons
                _buildNavigationButtons(cookingState),

                // Space for bottom sheet handle
                SizedBox(height: 80.h),
              ],
            ),

            // Ingredients bottom sheet
            DraggableScrollableSheet(
              controller: _sheetController,
              initialChildSize: 0.12,
              minChildSize: 0.12,
              maxChildSize: 0.6,
              snap: true,
              snapSizes: const [0.12, 0.4, 0.6],
              builder: (context, scrollController) {
                return CookingIngredientsSheet(
                  ingredients: widget.ingredients,
                  scrollController: scrollController,
                  sheetController: _sheetController,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(CookingModeState state) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.close, color: Colors.grey[800]),
        onPressed: _exitCookingMode,
      ),
      title: Text(
        widget.recipeName,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: Colors.grey[800],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: 16.w),
          child: Center(
            child: Text(
              state.progressText,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator(CookingModeState state) {
    return Container(
      height: 4.h,
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2.r),
        child: LinearProgressIndicator(
          value: state.progressValue,
          backgroundColor: Colors.grey[200],
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(CookingModeState state) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      child: Row(
        children: [
          // Previous button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: state.hasPreviousStep ? _goToPreviousStep : null,
              icon: const Icon(Icons.arrow_back),
              label: Text('cooking.previous'.tr()),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),

          SizedBox(width: 16.w),

          // Next button
          Expanded(
            child: FilledButton.icon(
              onPressed: _goToNextStep,
              icon: Text(
                state.hasNextStep
                    ? 'cooking.next'.tr()
                    : 'cooking.finish'.tr(),
              ),
              label: Icon(
                state.hasNextStep ? Icons.arrow_forward : Icons.check,
              ),
              style: FilledButton.styleFrom(
                backgroundColor: state.hasNextStep
                    ? AppColors.primary
                    : AppColors.growth,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
