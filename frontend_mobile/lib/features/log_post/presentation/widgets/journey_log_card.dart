import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pairing_planet2_frontend/core/widgets/app_cached_image.dart';
import 'package:pairing_planet2_frontend/features/log_post/presentation/widgets/outcome_badge.dart';
import 'package:pairing_planet2_frontend/features/log_post/presentation/widgets/recipe_lineage_breadcrumb.dart';

/// Extended log post data for the journey card
class JourneyLogData {
  final String id;
  final String? title;
  final String? content;
  final String? outcome;
  final String? thumbnailUrl;
  final String? creatorName;
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
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
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
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Recipe Lineage
                    if (logData.recipeTitle != null && logData.recipePublicId != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
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
                          fontSize: 14,
                          color: Colors.grey[800],
                          height: 1.5,
                        ),
                        maxLines: showFullContent ? null : 3,
                        overflow: showFullContent ? null : TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 12),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: outcome.backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
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
              _formatRelativeTime(logData.createdAt!),
              style: TextStyle(
                fontSize: 12,
                color: outcome.primaryColor.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          // Sync indicator
          if (logData.isPendingSync) ...[
            const SizedBox(width: 8),
            _buildSyncIndicator(),
          ],
        ],
      ),
    );
  }

  Widget _buildSyncIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange[600]!),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'logPost.syncing'.tr(),
            style: TextStyle(
              fontSize: 10,
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
          height: 200,
          borderRadius: 0,
        ),
        // Image count indicator
        if (imageCount > 1)
          Positioned(
            bottom: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.photo_library,
                    size: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '1/$imageCount',
                    style: const TextStyle(
                      fontSize: 12,
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
        if (logData.creatorName != null) ...[
          Icon(
            Icons.person_outline,
            size: 14,
            color: Colors.grey[400],
          ),
          const SizedBox(width: 4),
          Text(
            logData.creatorName!,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
        const Spacer(),
        // View more indicator
        Icon(
          Icons.arrow_forward,
          size: 16,
          color: Colors.grey[400],
        ),
      ],
    );
  }

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'logPost.time.justNow'.tr();
    } else if (difference.inMinutes < 60) {
      return 'logPost.time.minutesAgo'.tr(namedArgs: {'count': difference.inMinutes.toString()});
    } else if (difference.inHours < 24) {
      return 'logPost.time.hoursAgo'.tr(namedArgs: {'count': difference.inHours.toString()});
    } else if (difference.inDays < 7) {
      return 'logPost.time.daysAgo'.tr(namedArgs: {'count': difference.inDays.toString()});
    } else {
      return DateFormat.MMMd().format(dateTime);
    }
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
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
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
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    child: AppCachedImage(
                      imageUrl: logData.thumbnailUrl ?? 'https://via.placeholder.com/150',
                      width: double.infinity,
                      height: 100,
                      borderRadius: 0,
                    ),
                  ),
                  // Outcome badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: OutcomeBadge(
                      outcome: outcome,
                      variant: OutcomeBadgeVariant.compact,
                    ),
                  ),
                  // Sync indicator
                  if (logData.isPendingSync)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SizedBox(
                          width: 12,
                          height: 12,
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
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Recipe title
                      if (logData.recipeTitle != null)
                        Text(
                          logData.recipeTitle!,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const Spacer(),
                      // Time
                      if (logData.createdAt != null)
                        Text(
                          _formatRelativeTime(logData.createdAt!),
                          style: TextStyle(
                            fontSize: 11,
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

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inHours < 24) {
      return 'logPost.time.hoursAgo'.tr(namedArgs: {'count': difference.inHours.toString()});
    } else if (difference.inDays < 7) {
      return 'logPost.time.daysAgo'.tr(namedArgs: {'count': difference.inDays.toString()});
    } else {
      return DateFormat.MMMd().format(dateTime);
    }
  }
}
