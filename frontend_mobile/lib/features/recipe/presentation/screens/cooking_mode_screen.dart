import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/core/widgets/app_cached_image.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_detail.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_step.dart';
import 'package:pairing_planet2_frontend/features/log_post/presentation/widgets/quick_log_sheet.dart';

/// Full-screen cooking mode with step-by-step navigation
/// Optimized for use during cooking with large touch targets
class CookingModeScreen extends ConsumerStatefulWidget {
  final RecipeDetail recipe;

  const CookingModeScreen({super.key, required this.recipe});

  @override
  ConsumerState<CookingModeScreen> createState() => _CookingModeScreenState();
}

class _CookingModeScreenState extends ConsumerState<CookingModeScreen> {
  late PageController _pageController;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    // Keep screen on during cooking
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _pageController.dispose();
    // Restore normal system UI mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  int get _totalSteps => widget.recipe.steps.length;
  bool get _isFirstStep => _currentStep == 0;
  bool get _isLastStep => _currentStep == _totalSteps - 1;

  void _goToStep(int step) {
    if (step < 0 || step >= _totalSteps) return;
    HapticFeedback.mediumImpact();
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _nextStep() {
    if (_isLastStep) {
      _showCompletionDialog();
    } else {
      _goToStep(_currentStep + 1);
    }
  }

  void _previousStep() {
    if (!_isFirstStep) {
      _goToStep(_currentStep - 1);
    }
  }

  void _showCompletionDialog() {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('recipe.cooking.complete'.tr()),
        content: Text('recipe.cooking.logPrompt'.tr()),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop();
            },
            child: Text('common.notNow'.tr()),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop();
              QuickLogSheet.show(context);
            },
            child: Text('recipe.cooking.logNow'.tr()),
          ),
        ],
      ),
    );
  }

  void _exitCookingMode() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('recipe.cooking.exitTitle'.tr()),
        content: Text('recipe.cooking.exitMessage'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop();
            },
            child: Text('recipe.cooking.exit'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with progress and exit
            _buildTopBar(),
            // Step content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _totalSteps,
                onPageChanged: (page) {
                  setState(() => _currentStep = page);
                },
                itemBuilder: (context, index) {
                  final step = widget.recipe.steps[index];
                  return _buildStepContent(step, index);
                },
              ),
            ),
            // Bottom navigation buttons (64pt+ height)
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.black,
      child: Row(
        children: [
          // Exit button
          IconButton(
            onPressed: _exitCookingMode,
            icon: const Icon(Icons.close, color: Colors.white),
            iconSize: 28,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              minimumSize: const Size(48, 48),
            ),
          ),
          const SizedBox(width: 16),
          // Progress indicator
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'recipe.cooking.step'.tr(namedArgs: {
                    'current': '${_currentStep + 1}',
                    'total': '$_totalSteps',
                  }),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: (_currentStep + 1) / _totalSteps,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Timer placeholder (future enhancement)
          IconButton(
            onPressed: () {
              // TODO: Timer functionality
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('recipe.cooking.timerComingSoon'.tr())),
              );
            },
            icon: const Icon(Icons.timer_outlined, color: Colors.white),
            iconSize: 28,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              minimumSize: const Size(48, 48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(RecipeStep step, int index) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step number badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'recipe.cooking.stepNumber'.tr(namedArgs: {'number': '${index + 1}'}),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Step image (if available)
          if (step.imageUrl != null && step.imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AppCachedImage(
                imageUrl: step.imageUrl!,
                width: double.infinity,
                height: 250,
                borderRadius: 16,
              ),
            ),
          if (step.imageUrl != null && step.imageUrl!.isNotEmpty)
            const SizedBox(height: 24),
          // Step description
          if (step.description != null && step.description!.isNotEmpty)
            Text(
              step.description!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          // Previous button
          Expanded(
            child: SizedBox(
              height: 64, // 64pt minimum for cooking mode
              child: OutlinedButton.icon(
                onPressed: _isFirstStep ? null : _previousStep,
                icon: const Icon(Icons.arrow_back),
                label: Text('common.back'.tr()),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(
                    color: _isFirstStep
                        ? Colors.white.withValues(alpha: 0.3)
                        : Colors.white,
                    width: 2,
                  ),
                  disabledForegroundColor: Colors.white.withValues(alpha: 0.3),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Next button
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 64, // 64pt minimum for cooking mode
              child: FilledButton.icon(
                onPressed: _nextStep,
                icon: Icon(_isLastStep ? Icons.check : Icons.arrow_forward),
                label: Text(
                  _isLastStep
                      ? 'recipe.cooking.done'.tr()
                      : 'common.next'.tr(),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
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
