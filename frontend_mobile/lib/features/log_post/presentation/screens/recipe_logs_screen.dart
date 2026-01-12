import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nested_scroll_view_plus/nested_scroll_view_plus.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/core/widgets/app_cached_image.dart';
import 'package:pairing_planet2_frontend/core/widgets/skeletons/log_post_card_skeleton.dart';
import 'package:pairing_planet2_frontend/domain/entities/log_post/log_post_summary.dart';
import 'package:pairing_planet2_frontend/features/log_post/providers/log_post_list_provider.dart';
import 'package:pairing_planet2_frontend/core/widgets/outcome/outcome_badge.dart';
import 'package:pairing_planet2_frontend/features/log_post/presentation/widgets/log_empty_state.dart';

/// Screen for viewing all logs related to a specific recipe.
/// Accessed via "See More" button in RecentLogsGallery.
class RecipeLogsScreen extends ConsumerStatefulWidget {
  final String recipeId;

  const RecipeLogsScreen({super.key, required this.recipeId});

  @override
  ConsumerState<RecipeLogsScreen> createState() => _RecipeLogsScreenState();
}

class _RecipeLogsScreenState extends ConsumerState<RecipeLogsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  LogOutcome _getOutcome(String? outcome) {
    return LogOutcome.fromString(outcome) ?? LogOutcome.partial;
  }

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(recipeLogsProvider(widget.recipeId));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: NestedScrollViewPlus(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            pinned: true,
            floating: false,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: innerBoxIsScrolled ? 1 : 0,
            title: Text(
              'recipe.recentLogs.title'.tr(),
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
            ),
          ),
          CupertinoSliverRefreshControl(
            onRefresh: () async {
              await ref.read(recipeLogsProvider(widget.recipeId).notifier).refresh();
            },
          ),
        ],
        body: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollUpdateNotification) {
              final metrics = notification.metrics;
              if (metrics.pixels >= metrics.maxScrollExtent * 0.8) {
                ref.read(recipeLogsProvider(widget.recipeId).notifier).fetchNextPage();
              }
            }
            return false;
          },
          child: logsAsync.when(
            data: (state) => _buildContentBody(state),
            loading: () => const LogPostGridSkeleton(),
            error: (error, stack) => _buildErrorState(error),
          ),
        ),
      ),
    );
  }

  Widget _buildContentBody(LogPostListState state) {
    if (state.items.isEmpty) {
      return const LogEmptyState(type: EmptyStateType.noLogs);
    }

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.all(12.r),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12.h,
              crossAxisSpacing: 12.w,
              childAspectRatio: 0.75,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index < state.items.length) {
                  return _buildLogCard(context, state.items[index]);
                }
                return null;
              },
              childCount: state.items.length,
            ),
          ),
        ),
        if (state.hasNext)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(24.r),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
        if (!state.hasNext)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(24.r),
              child: Center(
                child: Text(
                  'logPost.allLoaded'.tr(),
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 13.sp,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLogCard(BuildContext context, LogPostSummary logPost) {
    final outcome = _getOutcome(logPost.outcome);

    return Semantics(
      button: true,
      label: '${outcome.label}: ${logPost.title}',
      hint: 'logPost.card.tapToView'.tr(),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          context.push(RouteConstants.logPostDetailPath(logPost.id));
        },
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
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
                      child: _buildThumbnail(context, logPost),
                    ),
                    Positioned(
                      left: 8.w,
                      top: 8.h,
                      child: OutcomeBadge(
                        outcome: outcome,
                        variant: OutcomeBadgeVariant.compact,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        logPost.title,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2.h),
                      if (logPost.creatorName != null)
                        Text(
                          "@${logPost.creatorName}",
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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

  Widget _buildThumbnail(BuildContext context, LogPostSummary logPost) {
    if (logPost.thumbnailUrl == null) {
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

    if (logPost.thumbnailUrl!.startsWith('file://')) {
      final filePath = logPost.thumbnailUrl!.replaceFirst('file://', '');
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

    return AppCachedImage(
      imageUrl: logPost.thumbnailUrl!,
      width: double.infinity,
      height: double.infinity,
      borderRadius: 0,
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48.sp, color: Colors.red),
          SizedBox(height: 16.h),
          Text(
            'logPost.couldNotLoad'.tr(),
            style: TextStyle(fontSize: 16.sp, color: Colors.grey[700]),
          ),
          SizedBox(height: 8.h),
          Text(
            error.toString(),
            style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          ElevatedButton(
            onPressed: () {
              ref.invalidate(recipeLogsProvider(widget.recipeId));
            },
            child: Text('common.tryAgain'.tr()),
          ),
        ],
      ),
    );
  }
}
