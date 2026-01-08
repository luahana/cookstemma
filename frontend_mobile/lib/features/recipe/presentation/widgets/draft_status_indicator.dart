import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pairing_planet2_frontend/features/recipe/providers/recipe_providers.dart';

/// A widget that displays the current draft save status in the AppBar.
/// Shows "Saving..." with spinner, "Saved" with checkmark, or error state.
class DraftStatusIndicator extends ConsumerStatefulWidget {
  const DraftStatusIndicator({super.key});

  @override
  ConsumerState<DraftStatusIndicator> createState() =>
      _DraftStatusIndicatorState();
}

class _DraftStatusIndicatorState extends ConsumerState<DraftStatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draftState = ref.watch(recipeDraftProvider);

    // Handle animation based on status
    if (draftState.saveStatus == DraftSaveStatus.idle) {
      _fadeController.reverse();
    } else {
      _fadeController.forward();

      // Auto-fade after 2 seconds for "saved" status
      if (draftState.saveStatus == DraftSaveStatus.saved) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _fadeController.reverse();
          }
        });
      }
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: _buildStatusContent(draftState.saveStatus),
    );
  }

  Widget _buildStatusContent(DraftSaveStatus status) {
    switch (status) {
      case DraftSaveStatus.saving:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12.w,
              height: 12.w,
              child: CircularProgressIndicator(
                strokeWidth: 2.w,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[600]!),
              ),
            ),
            SizedBox(width: 6.w),
            Text(
              'draft.saving'.tr(),
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[600],
              ),
            ),
          ],
        );
      case DraftSaveStatus.saved:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              size: 14.w,
              color: Colors.green[600],
            ),
            SizedBox(width: 4.w),
            Text(
              'draft.saved'.tr(),
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.green[600],
              ),
            ),
          ],
        );
      case DraftSaveStatus.error:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 14.w,
              color: Colors.orange[600],
            ),
            SizedBox(width: 4.w),
            Text(
              'draft.saveFailed'.tr(),
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.orange[600],
              ),
            ),
          ],
        );
      case DraftSaveStatus.idle:
        return const SizedBox.shrink();
    }
  }
}
