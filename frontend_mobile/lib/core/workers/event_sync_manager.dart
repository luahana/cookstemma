import 'dart:async';
import 'package:pairing_planet2_frontend/core/providers/analytics_providers.dart';
import 'package:pairing_planet2_frontend/core/utils/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Simple event sync manager that triggers sync on app lifecycle events
/// This is a workaround until WorkManager compatibility is fixed
class EventSyncManager {
  static Timer? _periodicTimer;
  static WidgetRef? _ref;

  /// Initialize with a WidgetRef to access providers
  static void initialize(WidgetRef ref) {
    _ref = ref;
    talker.info('EventSyncManager initialized');
  }

  /// Start periodic sync (every 5 minutes while app is active)
  static void startPeriodicSync() {
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      syncNow();
    });
    talker.info('Periodic event sync started (5 min interval)');
  }

  /// Stop periodic sync
  static void stopPeriodicSync() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
    talker.info('Periodic event sync stopped');
  }

  /// Manually trigger sync now
  static Future<void> syncNow() async {
    if (_ref == null) {
      talker.warning('EventSyncManager not initialized, skipping sync');
      return;
    }

    try {
      final analyticsRepo = _ref!.read(analyticsRepositoryProvider);
      await analyticsRepo.syncPendingEvents();
      talker.info('Manual event sync completed');
    } catch (e) {
      talker.error('Event sync failed', e);
    }
  }

  /// Call this when app resumes from background
  static Future<void> onAppResume() async {
    talker.info('App resumed, triggering event sync');
    await syncNow();
  }

  /// Call this when app goes to background
  static Future<void> onAppPause() async {
    talker.info('App paused, syncing events before background');
    await syncNow();
  }

  /// Cleanup
  static void dispose() {
    stopPeriodicSync();
    _ref = null;
  }
}
