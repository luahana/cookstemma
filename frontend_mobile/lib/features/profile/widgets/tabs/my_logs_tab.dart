import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/core/models/log_outcome.dart';
import 'package:pairing_planet2_frontend/core/widgets/log_post_card.dart';
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
                    label: '${LogOutcome.success.emoji} ${'profile.filter.wins'.tr()}',
                    isSelected: notifier.currentFilter == LogOutcomeFilter.wins,
                    onTap: () => notifier.setFilter(LogOutcomeFilter.wins),
                  ),
                  SizedBox(width: 8.w),
                  _buildLogFilterChip(
                    label: '${LogOutcome.partial.emoji} ${'profile.filter.learning'.tr()}',
                    isSelected:
                        notifier.currentFilter == LogOutcomeFilter.learning,
                    onTap: () => notifier.setFilter(LogOutcomeFilter.learning),
                  ),
                  SizedBox(width: 8.w),
                  _buildLogFilterChip(
                    label: '${LogOutcome.failed.emoji} ${'profile.filter.lessons'.tr()}',
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
                    final log = state.items[index];
                    return LogPostCard(
                      log: log.toEntity(),
                      showUsername: false,
                      onTap: () => context.push(
                        RouteConstants.logPostDetailPath(log.publicId),
                      ),
                    );
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

}
