import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/data/models/notification/notification_dto.dart';
import 'package:pairing_planet2_frontend/features/notification/providers/notification_provider.dart';

class NotificationInboxScreen extends ConsumerStatefulWidget {
  const NotificationInboxScreen({super.key});

  @override
  ConsumerState<NotificationInboxScreen> createState() =>
      _NotificationInboxScreenState();
}

class _NotificationInboxScreenState
    extends ConsumerState<NotificationInboxScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationListProvider.notifier).loadNotifications(refresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(notificationListProvider.notifier).loadNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('notification.title'.tr()),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(notificationListProvider.notifier).markAllAsRead();
            },
            child: Text('notification.markAllRead'.tr()),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref
              .read(notificationListProvider.notifier)
              .loadNotifications(refresh: true);
        },
        child: state.notifications.isEmpty && !state.isLoading
            ? _buildEmptyState()
            : ListView.builder(
                controller: _scrollController,
                itemCount:
                    state.notifications.length + (state.isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= state.notifications.length) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.r),
                        child: const CircularProgressIndicator(),
                      ),
                    );
                  }
                  return _NotificationTile(
                    notification: state.notifications[index],
                    onTap: () =>
                        _handleNotificationTap(state.notifications[index]),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 64.sp, color: Colors.grey),
          SizedBox(height: 16.h),
          Text(
            'notification.empty'.tr(),
            style: TextStyle(fontSize: 16.sp, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(NotificationDto notification) {
    // Mark as read
    ref
        .read(notificationListProvider.notifier)
        .markAsRead(notification.publicId);

    // Navigate based on notification type
    if (notification.recipePublicId != null) {
      context.push('${RouteConstants.recipeDetail}/${notification.recipePublicId}');
    }
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationDto notification;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor:
            notification.isRead ? Colors.grey[300] : Colors.orange[100],
        child: Icon(
          notification.type == 'RECIPE_COOKED'
              ? Icons.restaurant
              : Icons.fork_right,
          color: notification.isRead ? Colors.grey : Colors.orange,
        ),
      ),
      title: Text(
        notification.title,
        style: TextStyle(
          fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(notification.body,
              maxLines: 2, overflow: TextOverflow.ellipsis),
          SizedBox(height: 4.h),
          Text(
            _formatTime(notification.createdAt),
            style: TextStyle(fontSize: 12.sp, color: Colors.grey),
          ),
        ],
      ),
      trailing: !notification.isRead
          ? Container(
              width: 8.w,
              height: 8.h,
              decoration: const BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
            )
          : null,
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 60) {
      return 'common.minutesAgo'.tr(namedArgs: {'count': diff.inMinutes.toString()});
    } else if (diff.inHours < 24) {
      return 'common.hoursAgo'.tr(namedArgs: {'count': diff.inHours.toString()});
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d';
    } else {
      return '${dateTime.month}/${dateTime.day}';
    }
  }
}
