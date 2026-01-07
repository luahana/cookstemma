import 'dart:convert';
import 'package:isar/isar.dart';
import 'package:pairing_planet2_frontend/data/models/local/queued_event.dart';
import 'package:pairing_planet2_frontend/domain/entities/analytics/app_event.dart';

class AnalyticsLocalDataSource {
  final Isar _isar;

  AnalyticsLocalDataSource(this._isar);

  Future<void> queueEvent(AppEvent event) async {
    final queuedEvent = QueuedEvent()
      ..eventId = event.eventId
      ..eventType = event.eventType.name
      ..userId = event.userId
      ..timestamp = event.timestamp
      ..recipeId = event.recipeId
      ..logId = event.logId
      ..propertiesJson = jsonEncode(event.properties)
      ..priority = event.priority.name
      ..status = SyncStatus.pending;

    await _isar.writeTxn(() async {
      await _isar.queuedEvents.put(queuedEvent);
    });
  }

  Future<List<QueuedEvent>> getPendingEvents({EventPriority? priority}) async {
    var query = _isar.queuedEvents.filter().statusEqualTo(SyncStatus.pending);

    if (priority != null) {
      query = query.priorityEqualTo(priority.name);
    }

    return await query.findAll();
  }

  Future<void> markAsSynced(String eventId) async {
    await _isar.writeTxn(() async {
      final event = await _isar.queuedEvents
          .filter()
          .eventIdEqualTo(eventId)
          .findFirst();
      if (event != null) {
        event.status = SyncStatus.synced;
        await _isar.queuedEvents.put(event);
      }
    });
  }

  Future<void> markAsFailed(String eventId) async {
    await _isar.writeTxn(() async {
      final event = await _isar.queuedEvents
          .filter()
          .eventIdEqualTo(eventId)
          .findFirst();
      if (event != null) {
        event.status = SyncStatus.failed;
        event.retryCount++;
        event.lastAttempt = DateTime.now();
        await _isar.queuedEvents.put(event);
      }
    });
  }

  Future<void> cleanupSyncedEvents({int olderThanDays = 7}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: olderThanDays));

    await _isar.writeTxn(() async {
      final oldSyncedEvents = await _isar.queuedEvents
          .filter()
          .statusEqualTo(SyncStatus.synced)
          .timestampLessThan(cutoffDate)
          .findAll();

      final ids = oldSyncedEvents.map((e) => e.id).toList();
      await _isar.queuedEvents.deleteAll(ids);
    });
  }
}
