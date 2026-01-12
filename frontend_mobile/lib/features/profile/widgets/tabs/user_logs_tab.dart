import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/core/widgets/app_cached_image.dart';
import 'package:pairing_planet2_frontend/core/models/log_outcome.dart';
import 'package:pairing_planet2_frontend/data/models/log_post/log_post_summary_dto.dart';
import 'package:pairing_planet2_frontend/features/profile/providers/user_profile_provider.dart';
import 'package:pairing_planet2_frontend/features/profile/widgets/profile_shared.dart';

/// Tab for viewing another user's cooking logs
class UserLogsTab extends ConsumerWidget {
  final String userId;

  const UserLogsTab({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(userLogsProvider(userId));

    // Loading state
    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error state
    if (state.error != null && state.items.isEmpty) {
      return buildProfileErrorState(() {
        ref.read(userLogsProvider(userId).notifier).refresh();
      });
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >=
            notification.metrics.maxScrollExtent * 0.8) {
          ref.read(userLogsProvider(userId).notifier).fetchNextPage();
        }
        return false;
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Empty state or grid
          if (state.items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: buildProfileEmptyState(
                icon: Icons.history_edu,
                message: 'profile.noLogsYetOther'.tr(),
                subMessage: '',
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
