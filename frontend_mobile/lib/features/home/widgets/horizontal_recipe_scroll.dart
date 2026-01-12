import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/core/widgets/log_post_card.dart';
import 'package:pairing_planet2_frontend/data/models/home/recent_activity_dto.dart';

/// Horizontal scrolling activity cards for "Hot Right Now" section
class HorizontalActivityScroll extends StatelessWidget {
  final List<RecentActivityDto> activities;

  const HorizontalActivityScroll({
    super.key,
    required this.activities,
  });

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 180.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: activities.length,
        itemBuilder: (context, index) {
          final activity = activities[index];
          return Padding(
            padding: EdgeInsets.only(right: index < activities.length - 1 ? 12.w : 0),
            child: SizedBox(
              width: 140.w,
              child: LogPostCard(
                log: activity.toLogPostSummary(),
                showUsername: true,
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push(RouteConstants.logPostDetailPath(activity.logPublicId));
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
