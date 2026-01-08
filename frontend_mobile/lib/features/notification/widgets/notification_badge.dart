import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pairing_planet2_frontend/features/notification/providers/notification_provider.dart';

class NotificationBadge extends ConsumerWidget {
  final Widget child;

  const NotificationBadge({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return Badge(
      isLabelVisible: unreadCount > 0,
      label: Text(
        unreadCount > 99 ? '99+' : unreadCount.toString(),
        style: TextStyle(fontSize: 10.sp),
      ),
      child: child,
    );
  }
}
