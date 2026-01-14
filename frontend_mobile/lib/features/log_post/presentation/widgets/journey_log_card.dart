import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pairing_planet2_frontend/core/utils/relative_time_formatter.dart';
import 'package:pairing_planet2_frontend/core/widgets/app_cached_image.dart';
import 'package:pairing_planet2_frontend/core/widgets/clickable_username.dart';
import 'package:pairing_planet2_frontend/core/widgets/outcome/outcome_badge.dart';
import 'package:pairing_planet2_frontend/features/log_post/presentation/widgets/recipe_lineage_breadcrumb.dart';

/// Extended log post data for the journey card
class JourneyLogData {
  final String id;
  final String? title;
  final String? content;
  final String? outcome;
  final String? thumbnailUrl;
  final String? creatorName;
  final String? creatorPublicId;
  final DateTime? createdAt;
  final String? recipeTitle;
  final String? recipePublicId;
  final String? rootTitle;
  final String? rootPublicId;
  final List<String>? imageUrls;
  final bool isPendingSync;

  const JourneyLogData({
    required this.id,
    this.title,
    this.content,
    this.outcome,
    this.thumbnailUrl,
    this.creatorName,
    this.creatorPublicId,
    this.createdAt,
    this.recipeTitle,
    this.recipePublicId,
    this.rootTitle,
    this.rootPublicId,
    this.imageUrls,
    this.isPendingSync = false,
  });
}

/// Main journey log card with outcome header
/// Design: Outcome prominently at top, photo evidence, recipe lineage
class JourneyLogCard extends StatelessWidget {
  final JourneyLogData logData;
  final VoidCallback? onTap;
  final VoidCallback? onRecipeTap;
  final bool showFullContent;

  const JourneyLogCard({
    super.key,
    required this.logData,
    this.onTap,
    this.onRecipeTap,
    this.showFullContent = false,
  });

  @override
  Widget build(BuildContext context) {
    final outcome = LogOutcome.fromString(logData.outcome) ?? LogOutcome.partial;

    return Semantics(
      button: true,
      label: _buildSemanticLabel(outcome),
      hint: 'logPost.card.tapToView'.tr(),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap?.call();
        },
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: Offset(0, 4.h),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Outcome Header
              _buildOutcomeHeader(outcome),
              // Photo Evidence
              if (logData.thumbnailUrl != null) _buildPhotoSection(),
              // Content Section
              Padding(
                padding: EdgeInsets.all(16.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Recipe Lineage
                    if (logData.recipeTitle != null && logData.recipePublicId != null)
                      Padding(
                        padding: EdgeInsets.only(bottom: 12.h),
                        child: RecipeLineageBreadcrumb(
                          recipeTitle: logData.recipeTitle!,
                          recipePublicId: logData.recipePublicId!,
                          rootTitle: logData.rootTitle,
                          rootPublicId: logData.rootPublicId,
                          isCompact: true,
                          onRecipeTap: onRecipeTap,
                        ),
                      ),
                    // Log Content
                    if (logData.content != null && logData.content!.isNotEmpty)
                      Text(
                        logData.content!,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[800],
                          height: 1.5,
                        ),
                        maxLines: showFullContent ? null : 3,
                        overflow: showFullContent ? null : TextOverflow.ellipsis,
                      ),
                    SizedBox(height: 12.h),
                    // Footer
                    _buildFooter(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildSemanticLabel(LogOutcome outcome) {
    final parts = <String>[];
    parts.add('${outcome.label} log');
    if (logData.recipeTitle != null) {
      parts.add('for ${logData.recipeTitle}');
    }
    if (logData.content != null) {
      parts.add(logData.content!);
    }
    return parts.join(', ');
  }

  Widget _buildOutcomeHeader(LogOutcome outcome) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: outcome.backgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.r),
          topRight: Radius.circular(16.r),
        ),
      ),
      child: Row(
        children: [
          // Outcome badge (header style)
          OutcomeBadge(
            outcome: outcome,
            variant: OutcomeBadgeVariant.header,
          ),
          const Spacer(),
          // Timestamp
          if (logData.createdAt != null)
            Text(
              RelativeTimeFormatter.format(logData.createdAt!),
              style: TextStyle(
                fontSize: 12.sp,
                color: outcome.primaryColor.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          // Sync indicator
          if (logData.isPendingSync) ...[
            SizedBox(width: 8.w),
            _buildSyncIndicator(),
          ],
        ],
      ),
    );
  }

  Widget _buildSyncIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.orange[100],
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12.w,
            height: 12.w,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange[600]!),
            ),
          ),
          SizedBox(width: 4.w),
          Text(
            'logPost.syncing'.tr(),
            style: TextStyle(
              fontSize: 10.sp,
              color: Colors.orange[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection() {
    final imageUrls = logData.imageUrls ?? [logData.thumbnailUrl!];
    final imageCount = imageUrls.length;

    return Stack(
      children: [
        // Main image
        AppCachedImage(
          imageUrl: logData.thumbnailUrl!,
          width: double.infinity,
          height: 200.h,
          borderRadius: 0,
        ),
        // Image count indicator
        if (imageCount > 1)
          Positioned(
            bottom: 12.h,
            right: 12.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.photo_library,
                    size: 14.sp,
                    color: Colors.white,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    '1/$imageCount',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        // Creator
        if (logData.creatorName != null)
          ClickableUsername(
            username: logData.creatorName!,
            creatorPublicId: logData.creatorPublicId,
            fontSize: 12.sp,
            showPersonIcon: true,
          ),
        const Spacer(),
        // View more indicator
        Icon(
          Icons.arrow_forward,
          size: 16.sp,
          color: Colors.grey[400],
        ),
      ],
    );
  }
}

/// Compact version of the journey log card for grid view
class CompactJourneyLogCard extends StatelessWidget {
  final JourneyLogData logData;
  final VoidCallback? onTap;

  const CompactJourneyLogCard({
    super.key,
    required this.logData,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final outcome = LogOutcome.fromString(logData.outcome) ?? LogOutcome.partial;

    return Semantics(
      button: true,
      label: '${outcome.label}: ${logData.title ?? logData.recipeTitle ?? "Log"}',
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap?.call();
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: Offset(0, 2.h),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image with outcome badge overlay
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12.r),
                      topRight: Radius.circular(12.r),
                    ),
                    child: AppCachedImage(
                      imageUrl: logData.thumbnailUrl ?? 'https://via.placeholder.com/150',
                      width: double.infinity,
                      height: 100.h,
                      borderRadius: 0,
                    ),
                  ),
                  // Outcome badge
                  Positioned(
                    top: 8.h,
                    left: 8.w,
                    child: OutcomeBadge(
                      outcome: outcome,
                      variant: OutcomeBadgeVariant.compact,
                    ),
                  ),
                  // Sync indicator
                  if (logData.isPendingSync)
                    Positioned(
                      top: 8.h,
                      right: 8.w,
                      child: Container(
                        padding: EdgeInsets.all(4.r),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: SizedBox(
                          width: 12.w,
                          height: 12.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange[600]!),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(10.r),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Recipe title
                      if (logData.recipeTitle != null)
                        Text(
                          logData.recipeTitle!,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const Spacer(),
                      // Time
                      if (logData.createdAt != null)
                        Text(
                          RelativeTimeFormatter.formatCompact(logData.createdAt!),
                          style: TextStyle(
                            fontSize: 11.sp,
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
      ),
    );
  }
}
