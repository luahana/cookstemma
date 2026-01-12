import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pairing_planet2_frontend/core/models/log_outcome.dart';
import 'package:pairing_planet2_frontend/core/widgets/app_cached_image.dart';
import 'package:pairing_planet2_frontend/core/widgets/search/highlighted_text.dart';
import 'package:pairing_planet2_frontend/data/models/sync/sync_queue_item.dart';
import 'package:pairing_planet2_frontend/domain/entities/log_post/log_post_summary.dart';
import 'package:pairing_planet2_frontend/features/log_post/presentation/widgets/sync_status_indicator.dart';

/// Shared log post card widget for grid views
/// Used in: MyLogsTab, UserLogsTab, LogPostListScreen
class LogPostCard extends StatelessWidget {
  final LogPostSummary log;
  final VoidCallback? onTap;
  final String? searchQuery; // For highlighting text in search results
  final bool showUsername; // Set to false for own profile logs

  const LogPostCard({
    super.key,
    required this.log,
    this.onTap,
    this.searchQuery,
    this.showUsername = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      // RepaintBoundary caches the card's pixels to avoid expensive repaints
      // during scrolling (shadows + clips are costly to repaint)
      child: RepaintBoundary(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
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
            // Photo with outcome badge overlay
            Expanded(
              child: Stack(
                children: [
                  // Photo - handle both network URLs and local file paths
                  ClipRRect(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(12.r)),
                    child: _buildThumbnail(context),
                  ),
                  // Outcome emoji badge (bottom-right)
                  Positioned(
                    right: 8.w,
                    bottom: 8.h,
                    child: Container(
                      padding: EdgeInsets.all(6.r),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        LogOutcome.getEmoji(log.outcome),
                        style: TextStyle(fontSize: 18.sp),
                      ),
                    ),
                  ),
                  // Sync status indicator for pending items (top-right)
                  if (log.isPending)
                    Positioned(
                      right: 8.w,
                      top: 8.h,
                      child: const CardSyncIndicator(
                        status: SyncStatus.syncing,
                      ),
                    ),
                ],
              ),
            ),
            // Text info - dish name, username, and hashtags
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                  children: [
                    // Dish name (foodName) or fallback to title
                    HighlightedText(
                      text: (log.foodName != null && log.foodName!.isNotEmpty)
                          ? log.foodName!
                          : log.title,
                      query: searchQuery,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Username (or sync status if pending)
                    if (log.isPending)
                      Text(
                        'logPost.sync.syncing'.tr(),
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.orange[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    else if (showUsername &&
                        log.creatorName != null &&
                        log.creatorName!.isNotEmpty)
                      Text(
                        log.creatorName!,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    // Hashtags on separate line
                    if (!log.isPending &&
                        log.hashtags != null &&
                        log.hashtags!.isNotEmpty)
                      Text(
                        log.hashtags!.take(3).map((h) => '#$h').join(' '),
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.grey[500],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                ],
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  /// Build thumbnail widget - handles both network URLs and local file paths
  Widget _buildThumbnail(BuildContext context) {
    if (log.thumbnailUrl == null) {
      return Container(
        width: double.infinity,
        color: Colors.grey[200],
        child: Icon(
          Icons.restaurant,
          size: 40.sp,
          color: Colors.grey[400],
        ),
      );
    }

    // Handle local file URLs (for pending items)
    if (log.thumbnailUrl!.startsWith('file://')) {
      final filePath = log.thumbnailUrl!.replaceFirst('file://', '');
      // Use cacheWidth/cacheHeight to reduce memory footprint
      // Grid cards are approximately 150-200 pixels wide
      final cacheSize = (200 * MediaQuery.devicePixelRatioOf(context)).toInt();
      return Image.file(
        File(filePath),
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        cacheWidth: cacheSize,
        cacheHeight: cacheSize,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: double.infinity,
            color: Colors.grey[200],
            child: Icon(
              Icons.broken_image,
              size: 40.sp,
              color: Colors.grey[400],
            ),
          );
        },
      );
    }

    // Network URL
    return AppCachedImage(
      imageUrl: log.thumbnailUrl!,
      width: double.infinity,
      height: double.infinity,
      borderRadius: 0,
    );
  }
}
