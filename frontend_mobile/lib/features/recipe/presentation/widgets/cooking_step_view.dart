import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_step.dart';
import '../../providers/cooking_mode_provider.dart';
import 'cooking_timer_widget.dart';

/// Displays a single cooking step with large readable text
class CookingStepView extends ConsumerWidget {
  final RecipeStep step;
  final int stepIndex;

  const CookingStepView({
    super.key,
    required this.step,
    required this.stepIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cookingState = ref.watch(cookingModeProvider);
    final timerState = cookingState.getTimerForStep(stepIndex);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Step image (if available)
          if (step.imageUrl != null && step.imageUrl!.isNotEmpty)
            _buildStepImage(),

          SizedBox(height: 24.h),

          // Step description with large text
          Text(
            step.description ?? '',
            style: TextStyle(
              fontSize: 20.sp,
              height: 1.6,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 32.h),

          // Timer widget
          CookingTimerWidget(
            timerState: timerState,
            onStart: () => ref
                .read(cookingModeProvider.notifier)
                .startTimer(stepIndex),
            onPause: () => ref
                .read(cookingModeProvider.notifier)
                .pauseTimer(stepIndex),
            onReset: () => ref
                .read(cookingModeProvider.notifier)
                .resetTimer(stepIndex),
            onSetTimer: () => _showTimerPicker(context, ref, timerState),
          ),

          // Bottom padding for navigation buttons area
          SizedBox(height: 100.h),
        ],
      ),
    );
  }

  Widget _buildStepImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.r),
      child: CachedNetworkImage(
        imageUrl: step.imageUrl!,
        height: 200.h,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          height: 200.h,
          color: Colors.grey[200],
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2.w,
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          height: 200.h,
          color: Colors.grey[200],
          child: Icon(
            Icons.broken_image_outlined,
            size: 48.sp,
            color: Colors.grey[400],
          ),
        ),
      ),
    );
  }

  void _showTimerPicker(
    BuildContext context,
    WidgetRef ref,
    StepTimerState? currentTimer,
  ) {
    showDialog(
      context: context,
      builder: (context) => TimerDurationPicker(
        initialDuration: currentTimer?.totalDuration,
        onDurationSet: (duration) {
          ref.read(cookingModeProvider.notifier).setTimer(stepIndex, duration);
        },
      ),
    );
  }
}
