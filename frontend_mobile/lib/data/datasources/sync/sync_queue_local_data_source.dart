import 'dart:convert';
import 'package:isar/isar.dart';
import 'package:pairing_planet2_frontend/data/models/local/local_log_draft.dart';
import 'package:pairing_planet2_frontend/data/models/local/sync_queue_entry.dart';
import 'package:pairing_planet2_frontend/data/models/sync/sync_queue_item.dart';

class SyncQueueLocalDataSource {
  final Isar _isar;

  SyncQueueLocalDataSource(this._isar);

  SyncQueueStatus _mapStatus(SyncStatus status) {
    switch (status) {
      case SyncStatus.pending:
        return SyncQueueStatus.pending;
      case SyncStatus.syncing:
        return SyncQueueStatus.syncing;
      case SyncStatus.synced:
        return SyncQueueStatus.synced;
      case SyncStatus.failed:
        return SyncQueueStatus.failed;
      case SyncStatus.abandoned:
        return SyncQueueStatus.abandoned;
    }
  }

  SyncQueueItem _entryToItem(SyncQueueEntry entry) {
    return SyncQueueItem.fromJsonString(jsonEncode({
      'id': entry.entryId,
      'type': entry.operationType,
      'payload': entry.payload,
      'status': entry.status.name,
      'retryCount': entry.retryCount,
      'createdAt': entry.createdAt.toIso8601String(),
      'lastAttemptAt': entry.lastAttemptAt?.toIso8601String(),
      'errorMessage': entry.errorMessage,
      'localId': entry.localId,
    }));
  }

  Future<void> addToQueue(SyncQueueItem item) async {
    await _isar.writeTxn(() async {
      final entry = SyncQueueEntry()
        ..entryId = item.id
        ..operationType = item.type.name
        ..payload = item.payload
        ..status = _mapStatus(item.status)
        ..retryCount = item.retryCount
        ..createdAt = item.createdAt
        ..lastAttemptAt = item.lastAttemptAt
        ..errorMessage = item.errorMessage
        ..localId = item.localId;

      await _isar.syncQueueEntrys.put(entry);
    });
  }

  Future<void> updateItem(SyncQueueItem item) async {
    await _isar.writeTxn(() async {
      final existing = await _isar.syncQueueEntrys
          .filter()
          .entryIdEqualTo(item.id)
          .findFirst();

      final entry = SyncQueueEntry()
        ..entryId = item.id
        ..operationType = item.type.name
        ..payload = item.payload
        ..status = _mapStatus(item.status)
        ..retryCount = item.retryCount
        ..createdAt = item.createdAt
        ..lastAttemptAt = item.lastAttemptAt
        ..errorMessage = item.errorMessage
        ..localId = item.localId;

      if (existing != null) {
        entry.id = existing.id;
      }
      await _isar.syncQueueEntrys.put(entry);
    });
  }

  Future<SyncQueueItem?> getItem(String id) async {
    final entry = await _isar.syncQueueEntrys
        .filter()
        .entryIdEqualTo(id)
        .findFirst();

    if (entry != null) {
      return _entryToItem(entry);
    }
    return null;
  }

  Future<List<SyncQueueItem>> getPendingItems() async {
    final entries = await _isar.syncQueueEntrys
        .filter()
        .group((q) => q
            .statusEqualTo(SyncQueueStatus.pending)
            .or()
            .statusEqualTo(SyncQueueStatus.failed))
        .sortByCreatedAt()
        .findAll();

    return entries
        .map((e) => _entryToItem(e))
        .where((item) => item.isReadyToSync)
        .toList();
  }

  Future<List<SyncQueueItem>> getItemsByStatus(SyncStatus status) async {
    final entries = await _isar.syncQueueEntrys
        .filter()
        .statusEqualTo(_mapStatus(status))
        .findAll();

    return entries.map((e) => _entryToItem(e)).toList();
  }

  Future<List<SyncQueueItem>> getAllItems() async {
    final entries = await _isar.syncQueueEntrys
        .where()
        .sortByCreatedAt()
        .findAll();

    return entries.map((e) => _entryToItem(e)).toList();
  }

  Future<void> removeItem(String id) async {
    await _isar.writeTxn(() async {
      await _isar.syncQueueEntrys
          .filter()
          .entryIdEqualTo(id)
          .deleteAll();
    });
  }

  Future<int> clearSyncedItems() async {
    return await _isar.writeTxn(() async {
      return await _isar.syncQueueEntrys
          .filter()
          .statusEqualTo(SyncQueueStatus.synced)
          .deleteAll();
    });
  }

  Future<int> clearAbandonedItems() async {
    return await _isar.writeTxn(() async {
      return await _isar.syncQueueEntrys
          .filter()
          .statusEqualTo(SyncQueueStatus.abandoned)
          .deleteAll();
    });
  }

  Future<SyncQueueStats> getStats() async {
    int pending = 0;
    int syncing = 0;
    int synced = 0;
    int failed = 0;
    int abandoned = 0;

    final entries = await _isar.syncQueueEntrys.where().findAll();

    for (final entry in entries) {
      switch (entry.status) {
        case SyncQueueStatus.pending:
          pending++;
          break;
        case SyncQueueStatus.syncing:
          syncing++;
          break;
        case SyncQueueStatus.synced:
          synced++;
          break;
        case SyncQueueStatus.failed:
          failed++;
          break;
        case SyncQueueStatus.abandoned:
          abandoned++;
          break;
      }
    }

    return SyncQueueStats(
      pending: pending,
      syncing: syncing,
      synced: synced,
      failed: failed,
      abandoned: abandoned,
    );
  }

  Future<bool> hasPendingItems() async {
    final count = await _isar.syncQueueEntrys
        .filter()
        .group((q) => q
            .statusEqualTo(SyncQueueStatus.pending)
            .or()
            .statusEqualTo(SyncQueueStatus.failed))
        .count();

    return count > 0;
  }

  Future<int> getPendingCount() async {
    final items = await getPendingItems();
    return items.length;
  }

  // ============ Local Draft Storage ============

  Future<void> saveLocalDraft(String localId, Map<String, dynamic> draft) async {
    await _isar.writeTxn(() async {
      final existing = await _isar.localLogDrafts
          .filter()
          .localIdEqualTo(localId)
          .findFirst();

      final entry = LocalLogDraft()
        ..localId = localId
        ..jsonData = jsonEncode(draft);

      if (existing != null) {
        entry.id = existing.id;
      }
      await _isar.localLogDrafts.put(entry);
    });
  }

  Future<Map<String, dynamic>?> getLocalDraft(String localId) async {
    final entry = await _isar.localLogDrafts
        .filter()
        .localIdEqualTo(localId)
        .findFirst();

    if (entry != null) {
      try {
        return jsonDecode(entry.jsonData) as Map<String, dynamic>;
      } catch (e) {
        return {'localId': localId, 'raw': entry.jsonData};
      }
    }
    return null;
  }

  Future<void> removeLocalDraft(String localId) async {
    await _isar.writeTxn(() async {
      await _isar.localLogDrafts
          .filter()
          .localIdEqualTo(localId)
          .deleteAll();
    });
  }
}

class SyncQueueStats {
  final int pending;
  final int syncing;
  final int synced;
  final int failed;
  final int abandoned;

  const SyncQueueStats({
    required this.pending,
    required this.syncing,
    required this.synced,
    required this.failed,
    required this.abandoned,
  });

  int get total => pending + syncing + synced + failed + abandoned;
  int get needsSync => pending + failed;
  bool get hasUnsyncedItems => needsSync > 0;

  @override
  String toString() {
    return 'SyncQueueStats(pending: $pending, syncing: $syncing, synced: $synced, failed: $failed, abandoned: $abandoned)';
  }
}
