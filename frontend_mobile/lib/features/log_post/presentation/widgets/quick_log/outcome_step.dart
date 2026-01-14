import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pairing_planet2_frontend/core/widgets/outcome/outcome_badge.dart';
import 'package:pairing_planet2_frontend/features/log_post/providers/quick_log_draft_provider.dart';

/// Outcome selection step - large touch targets for cooking mode
class OutcomeStep extends ConsumerWidget {
  final QuickLogDraft draft;

  const OutcomeStep({super.key, required this.draft});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height * 0.35,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header at top
          Padding(
            padding: EdgeInsets.only(top: 24.h),
            child: Column(
              children: [
                if (draft.recipeTitle != null) ...[
                  Text(
                    draft.recipeTitle!,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8.h),
                ],
                Text(
                  'logPost.quickLog.howDidItGo'.tr(),
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          // Buttons at bottom - large touch targets for cooking mode
          Padding(
            padding: EdgeInsets.only(bottom: 24.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: LogOutcome.values.map((outcome) {
                final isSelected = draft.outcome == outcome;
                return _OutcomeButton(
                  outcome: outcome,
                  isSelected: isSelected,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    ref.read(quickLogDraftProvider.notifier).selectOutcome(outcome);
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Large outcome button for easy thumb access
class _OutcomeButton extends StatelessWidget {
  final LogOutcome outcome;
  final bool isSelected;
  final VoidCallback onTap;

  const _OutcomeButton({
    required this.outcome,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 100.w,
        height: 100.w,
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
        decoration: BoxDecoration(
          color: isSelected ? outcome.primaryColor : outcome.backgroundColor,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected
                ? outcome.primaryColor
                : outcome.primaryColor.withValues(alpha: 0.3),
            width: isSelected ? 3 : 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: outcome.primaryColor.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: Offset(0, 4.h),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: Offset(0, 2.h),
                  ),
                ],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                outcome.emoji,
                style: TextStyle(fontSize: 36.sp),
              ),
              SizedBox(height: 4.h),
              Text(
                outcome.label,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : outcome.primaryColor,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
