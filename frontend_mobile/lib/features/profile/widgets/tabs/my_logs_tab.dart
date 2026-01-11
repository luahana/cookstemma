import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/core/widgets/app_cached_image.dart';
import 'package:pairing_planet2_frontend/core/widgets/outcome/outcome_badge.dart';
import 'package:pairing_planet2_frontend/data/models/log_post/log_post_summary_dto.dart';
import 'package:pairing_planet2_frontend/features/profile/providers/profile_provider.dart';
import 'package:pairing_planet2_frontend/features/profile/widgets/profile_shared.dart';

/// My Logs Tab - displays user's own cooking logs
class MyLogsTab extends ConsumerStatefulWidget {
  const MyLogsTab({super.key});

  @override
  ConsumerState<MyLogsTab> createState() => _MyLogsTabState();
}

class _MyLogsTabState extends ConsumerState<MyLogsTab> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myLogsProvider);
    final notifier = ref.read(myLogsProvider.notifier);

    // Initial loading (no cached data)
    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error with no data
    if (state.error != null && state.items.isEmpty) {
      return buildProfileErrorState(() {
        ref.read(myLogsProvider.notifier).refresh();
      });
    }

    // Data available or empty (with filter chips)
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >=
            notification.metrics.maxScrollExtent * 0.8) {
          ref.read(myLogsProvider.notifier).fetchNextPage();
        }
        return false;
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: buildCacheIndicator(
              isFromCache: state.isFromCache,
              cachedAt: state.cachedAt,
              isLoading: state.isLoading,
            ),
          ),
          // Filter chips with emojis
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              child: Row(
                children: [
                  _buildLogFilterChip(
                    label: 'profile.filter.all'.tr(),
                    isSelected: notifier.currentFilter == LogOutcomeFilter.all,
                    onTap: () => notifier.setFilter(LogOutcomeFilter.all),
                  ),
                  SizedBox(width: 8.w),
                  _buildLogFilterChip(
                    label: '😊 ${'profile.filter.wins'.tr()}',
                    isSelected: notifier.currentFilter == LogOutcomeFilter.wins,
                    onTap: () => notifier.setFilter(LogOutcomeFilter.wins),
                  ),
                  SizedBox(width: 8.w),
                  _buildLogFilterChip(
                    label: '😐 ${'profile.filter.learning'.tr()}',
                    isSelected:
                        notifier.currentFilter == LogOutcomeFilter.learning,
                    onTap: () => notifier.setFilter(LogOutcomeFilter.learning),
                  ),
                  SizedBox(width: 8.w),
                  _buildLogFilterChip(
                    label: '😢 ${'profile.filter.lessons'.tr()}',
                    isSelected:
                        notifier.currentFilter == LogOutcomeFilter.lessons,
                    onTap: () => notifier.setFilter(LogOutcomeFilter.lessons),
                  ),
                ],
              ),
            ),
          ),
          // Empty state or grid
          if (state.items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: buildProfileEmptyState(
                icon: Icons.history_edu,
                message: 'profile.noLogsYet'.tr(),
                subMessage: 'profile.tryRecipe'.tr(),
              ),
            )
          else ...[
            SliverPadding(
              padding: EdgeInsets.all(12.r),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12.h,
                  crossAxisSpacing: 12.w,
                  childAspectRatio: 0.85,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= state.items.length) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return _buildLogCard(context, state.items[index]);
                  },
                  childCount: state.items.length + (state.hasNext ? 1 : 0),
                ),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 16.h)),
          ],
        ],
      ),
    );
  }

  Widget _buildLogFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildLogCard(BuildContext context, LogPostSummaryDto log) {
    return GestureDetector(
      onTap: () =>
          context.push(RouteConstants.logPostDetailPath(log.publicId)),
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
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(12.r)),
                    child: log.thumbnailUrl != null
                        ? AppCachedImage(
                            imageUrl: log.thumbnailUrl!,
                            width: double.infinity,
                            height: double.infinity,
                            borderRadius: 0,
                          )
                        : Container(
                            width: double.infinity,
                            color: Colors.grey[200],
                            child: Icon(Icons.restaurant,
                                size: 40.sp, color: Colors.grey[400]),
                          ),
                  ),
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
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(10.r),
              child: Text(
                log.title ?? '',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
