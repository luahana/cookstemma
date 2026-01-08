import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pairing_planet2_frontend/core/network/dio_provider.dart';
import 'package:pairing_planet2_frontend/core/services/fcm_service.dart';
import 'package:pairing_planet2_frontend/core/utils/logger.dart';
import 'package:pairing_planet2_frontend/data/datasources/notification/notification_remote_data_source.dart';
import 'package:pairing_planet2_frontend/data/models/notification/notification_dto.dart';
import 'package:pairing_planet2_frontend/features/auth/providers/auth_provider.dart';

// FCM Service Provider
final fcmServiceProvider = Provider<FcmService>((ref) => FcmService());

// Data Source Provider
final notificationRemoteDataSourceProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return NotificationRemoteDataSource(dio);
});

// Unread Count Provider
final unreadNotificationCountProvider =
    StateNotifierProvider<UnreadCountNotifier, int>((ref) {
  final dataSource = ref.watch(notificationRemoteDataSourceProvider);
  return UnreadCountNotifier(dataSource);
});

class UnreadCountNotifier extends StateNotifier<int> {
  final NotificationRemoteDataSource _dataSource;

  UnreadCountNotifier(this._dataSource) : super(0);

  Future<void> fetch() async {
    try {
      state = await _dataSource.getUnreadCount();
    } catch (e) {
      talker.error('Failed to fetch unread count: $e');
    }
  }

  void increment() => state = state + 1;
  void decrement() {
    if (state > 0) state = state - 1;
  }

  void reset() => state = 0;
}

// Notification List State
class NotificationListState {
  final List<NotificationDto> notifications;
  final bool isLoading;
  final bool hasNext;
  final String? error;

  NotificationListState({
    this.notifications = const [],
    this.isLoading = false,
    this.hasNext = true,
    this.error,
  });

  NotificationListState copyWith({
    List<NotificationDto>? notifications,
    bool? isLoading,
    bool? hasNext,
    String? error,
  }) {
    return NotificationListState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      hasNext: hasNext ?? this.hasNext,
      error: error,
    );
  }
}

// Notification List Provider
final notificationListProvider =
    StateNotifierProvider<NotificationListNotifier, NotificationListState>(
        (ref) {
  final dataSource = ref.watch(notificationRemoteDataSourceProvider);
  final unreadNotifier = ref.read(unreadNotificationCountProvider.notifier);
  return NotificationListNotifier(dataSource, unreadNotifier);
});

class NotificationListNotifier extends StateNotifier<NotificationListState> {
  final NotificationRemoteDataSource _dataSource;
  final UnreadCountNotifier _unreadNotifier;
  int _currentPage = 0;

  NotificationListNotifier(this._dataSource, this._unreadNotifier)
      : super(NotificationListState());

  Future<void> loadNotifications({bool refresh = false}) async {
    if (state.isLoading) return;
    if (!refresh && !state.hasNext) return;

    if (refresh) {
      _currentPage = 0;
      state = state.copyWith(notifications: [], hasNext: true);
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _dataSource.getNotifications(
        page: _currentPage,
        size: 20,
      );

      final newNotifications = refresh
          ? response.notifications
          : [...state.notifications, ...response.notifications];

      state = state.copyWith(
        notifications: newNotifications,
        isLoading: false,
        hasNext: response.hasNext,
      );

      _currentPage++;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      talker.error('Failed to load notifications: $e');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _dataSource.markAsRead(notificationId);

      // Update local state
      final updated = state.notifications.map((n) {
        if (n.publicId == notificationId && !n.isRead) {
          _unreadNotifier.decrement();
          return n.copyWith(isRead: true);
        }
        return n;
      }).toList();

      state = state.copyWith(notifications: updated);
    } catch (e) {
      talker.error('Failed to mark as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _dataSource.markAllAsRead();
      _unreadNotifier.reset();

      final updated =
          state.notifications.map((n) => n.copyWith(isRead: true)).toList();

      state = state.copyWith(notifications: updated);
    } catch (e) {
      talker.error('Failed to mark all as read: $e');
    }
  }
}

// FCM Initialization Provider (call once after login)
final fcmInitializerProvider = FutureProvider.autoDispose<void>((ref) async {
  final authState = ref.watch(authStateProvider);
  talker.info('FCM Initializer: authState=${authState.status}');
  if (authState.status != AuthStatus.authenticated) {
    talker.info('FCM Initializer: Not authenticated, skipping');
    return;
  }

  final fcmService = ref.read(fcmServiceProvider);
  final dataSource = ref.read(notificationRemoteDataSourceProvider);

  talker.info('FCM Initializer: Starting FCM initialization...');
  try {
    final token = await fcmService.initialize();
    talker.info('FCM Initializer: Token received: ${token != null}');
    if (token != null) {
      await dataSource.registerFcmToken(
        fcmToken: token,
        deviceType: fcmService.getDeviceType(),
      );
      talker.info('FCM token registered with backend');
    }

    // Listen for token refresh
    fcmService.onTokenRefresh.listen((newToken) async {
      await dataSource.registerFcmToken(
        fcmToken: newToken,
        deviceType: fcmService.getDeviceType(),
      );
      talker.info('FCM token refreshed and registered');
    });

    // Fetch initial unread count
    await ref.read(unreadNotificationCountProvider.notifier).fetch();
  } catch (e) {
    talker.error('Failed to initialize FCM: $e');
  }
});
