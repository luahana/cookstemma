import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/core/widgets/outcome/outcome_badge.dart';
import 'package:pairing_planet2_frontend/data/datasources/sync/log_sync_engine.dart';
import 'package:pairing_planet2_frontend/features/log_post/providers/quick_log_draft_provider.dart';
import 'package:pairing_planet2_frontend/features/profile/providers/profile_provider.dart';
import 'package:pairing_planet2_frontend/features/recipe/providers/recipe_providers.dart';

/// Submitting state with loading indicator
class SubmittingState extends StatelessWidget {
  const SubmittingState({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 48.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          SizedBox(height: 24.h),
          Text(
            'logPost.quickLog.saving'.tr(),
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Success state with preview card and navigation options
class SuccessState extends ConsumerStatefulWidget {
  const SuccessState({super.key});

  @override
  ConsumerState<SuccessState> createState() => _SuccessStateState();
}

class _SuccessStateState extends ConsumerState<SuccessState> {
  bool _isNavigating = false;

  Future<void> _handleViewLog() async {
    if (_isNavigating) return;
    setState(() => _isNavigating = true);

    HapticFeedback.mediumImpact();
    final draft = ref.read(quickLogDraftProvider);

    // Wait for sync to complete
    await ref.read(logSyncEngineProvider).triggerSync();

    if (!mounted) return;

    ref.read(quickLogDraftProvider.notifier).reset();
    Navigator.of(context).pop(true);
    ref.invalidate(myProfileProvider);
    if (draft.recipePublicId != null) {
      ref.invalidate(recipeDetailWithTrackingProvider(draft.recipePublicId!));
    }

    // Navigate to My Logs tab where the synced log will appear
    context.go('${RouteConstants.profile}?tab=1');
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(quickLogDraftProvider);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Success icon
          Container(
            width: 64.w,
            height: 64.w,
            decoration: BoxDecoration(
              color: Colors.green[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle,
              size: 40.sp,
              color: Colors.green[600],
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'logPost.quickLog.logged'.tr(),
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 24.h),

          // Preview card
          _LogPreviewCard(draft: draft),

          SizedBox(height: 16.h),
          Text(
            'logPost.quickLog.syncingBackground'.tr(),
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24.h),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  final draft = ref.read(quickLogDraftProvider);
                  ref.read(quickLogDraftProvider.notifier).reset();
                  Navigator.of(context).pop(true);
                  if (draft.recipePublicId != null) {
                    ref.invalidate(recipeDetailWithTrackingProvider(draft.recipePublicId!));
                  }
                },
                child: Text('common.done'.tr()),
              ),
              SizedBox(width: 16.w),
              FilledButton.icon(
                onPressed: _isNavigating ? null : _handleViewLog,
                icon: _isNavigating
                    ? SizedBox(
                        width: 16.w,
                        height: 16.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.visibility),
                label: Text('logPost.quickLog.viewLog'.tr()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Error state with retry option
class ErrorState extends ConsumerWidget {
  final String? errorMessage;
  final VoidCallback onRetry;

  const ErrorState({
    super.key,
    this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 32.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 48.sp,
            color: Colors.red[400],
          ),
          SizedBox(height: 16.h),
          Text(
            'logPost.quickLog.error'.tr(),
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            errorMessage ?? 'Unknown error',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  ref.read(quickLogDraftProvider.notifier).goBack();
                },
                child: Text('common.back'.tr()),
              ),
              SizedBox(width: 16.w),
              FilledButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  onRetry();
                },
                child: Text('common.tryAgain'.tr()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Preview card showing what was logged
class _LogPreviewCard extends StatelessWidget {
  final QuickLogDraft draft;

  const _LogPreviewCard({required this.draft});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Photo thumbnail
          if (draft.photoPaths.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: Builder(
                builder: (context) {
                  // Use cacheWidth/cacheHeight to reduce memory footprint
                  // Display is 80x80, multiply by devicePixelRatio
                  final cacheSize = (80 * MediaQuery.devicePixelRatioOf(context)).toInt();
                  return Image.file(
                    File(draft.photoPaths.first),
                    width: 80.w,
                    height: 80.w,
                    fit: BoxFit.cover,
                    cacheWidth: cacheSize,
                    cacheHeight: cacheSize,
                  );
                },
              ),
            )
          else
            Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(Icons.photo, color: Colors.grey[400]),
            ),
          SizedBox(width: 16.w),
          // Log info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (draft.outcome != null)
                  OutcomeBadge(
                    outcome: draft.outcome!,
                    variant: OutcomeBadgeVariant.compact,
                  ),
                SizedBox(height: 8.h),
                if (draft.recipeTitle != null)
                  Text(
                    draft.recipeTitle!,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (draft.notes != null && draft.notes!.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 4.h),
                    child: Text(
                      draft.notes!,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
