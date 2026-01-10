import 'package:hive/hive.dart';
import 'package:pairing_planet2_frontend/data/models/sync/sync_queue_item.dart';

/// Local data source for the sync queue using Hive
class SyncQueueLocalDataSource {
  static const String _syncQueueBoxName = 'sync_queue_box';
  static const String _localLogBoxName = 'local_log_drafts_box';

  /// Get the sync queue box
  Future<Box<String>> _getSyncBox() async {
    return await Hive.openBox<String>(_syncQueueBoxName);
  }

  /// Get the local drafts box
  Future<Box<String>> _getLocalDraftsBox() async {
    return await Hive.openBox<String>(_localLogBoxName);
  }

  /// Add an item to the sync queue
  Future<void> addToQueue(SyncQueueItem item) async {
    final box = await _getSyncBox();
    await box.put(item.id, item.toJsonString());
  }

  /// Update an existing queue item
  Future<void> updateItem(SyncQueueItem item) async {
    final box = await _getSyncBox();
    await box.put(item.id, item.toJsonString());
  }

  /// Get a specific queue item by ID
  Future<SyncQueueItem?> getItem(String id) async {
    final box = await _getSyncBox();
    final jsonString = box.get(id);
    if (jsonString != null) {
      return SyncQueueItem.fromJsonString(jsonString);
    }
    return null;
  }

  /// Get all pending items (ready to sync)
  Future<List<SyncQueueItem>> getPendingItems() async {
    final box = await _getSyncBox();
    final items = <SyncQueueItem>[];

    for (final key in box.keys) {
      final jsonString = box.get(key);
      if (jsonString != null) {
        final item = SyncQueueItem.fromJsonString(jsonString);
        if (item.isReadyToSync) {
          items.add(item);
        }
      }
    }

    // Sort by creation time (oldest first - FIFO)
    items.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return items;
  }

  /// Get all items with a specific status
  Future<List<SyncQueueItem>> getItemsByStatus(SyncStatus status) async {
    final box = await _getSyncBox();
    final items = <SyncQueueItem>[];

    for (final key in box.keys) {
      final jsonString = box.get(key);
      if (jsonString != null) {
        final item = SyncQueueItem.fromJsonString(jsonString);
        if (item.status == status) {
          items.add(item);
        }
      }
    }

    return items;
  }

  /// Get all items (for debugging/stats)
  Future<List<SyncQueueItem>> getAllItems() async {
    final box = await _getSyncBox();
    final items = <SyncQueueItem>[];

    for (final key in box.keys) {
      final jsonString = box.get(key);
      if (jsonString != null) {
        items.add(SyncQueueItem.fromJsonString(jsonString));
      }
    }

    items.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return items;
  }

  /// Remove an item from the queue
  Future<void> removeItem(String id) async {
    final box = await _getSyncBox();
    await box.delete(id);
  }

  /// Remove all synced items (cleanup)
  Future<int> clearSyncedItems() async {
    final box = await _getSyncBox();
    final keysToRemove = <String>[];

    for (final key in box.keys) {
      final jsonString = box.get(key);
      if (jsonString != null) {
        final item = SyncQueueItem.fromJsonString(jsonString);
        if (item.status == SyncStatus.synced) {
          keysToRemove.add(key as String);
        }
      }
    }

    for (final key in keysToRemove) {
      await box.delete(key);
    }

    return keysToRemove.length;
  }

  /// Remove all abandoned items
  Future<int> clearAbandonedItems() async {
    final box = await _getSyncBox();
    final keysToRemove = <String>[];

    for (final key in box.keys) {
      final jsonString = box.get(key);
      if (jsonString != null) {
        final item = SyncQueueItem.fromJsonString(jsonString);
        if (item.status == SyncStatus.abandoned) {
          keysToRemove.add(key as String);
        }
      }
    }

    for (final key in keysToRemove) {
      await box.delete(key);
    }

    return keysToRemove.length;
  }

  /// Get queue statistics
  Future<SyncQueueStats> getStats() async {
    final box = await _getSyncBox();
    int pending = 0;
    int syncing = 0;
    int synced = 0;
    int failed = 0;
    int abandoned = 0;

    for (final key in box.keys) {
      final jsonString = box.get(key);
      if (jsonString != null) {
        final item = SyncQueueItem.fromJsonString(jsonString);
        switch (item.status) {
          case SyncStatus.pending:
            pending++;
            break;
          case SyncStatus.syncing:
            syncing++;
            break;
          case SyncStatus.synced:
            synced++;
            break;
          case SyncStatus.failed:
            failed++;
            break;
          case SyncStatus.abandoned:
            abandoned++;
            break;
        }
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

  /// Check if there are pending items
  Future<bool> hasPendingItems() async {
    final box = await _getSyncBox();

    for (final key in box.keys) {
      final jsonString = box.get(key);
      if (jsonString != null) {
        final item = SyncQueueItem.fromJsonString(jsonString);
        if (item.isReadyToSync) {
          return true;
        }
      }
    }

    return false;
  }

  /// Get count of pending items
  Future<int> getPendingCount() async {
    final items = await getPendingItems();
    return items.length;
  }

  // ============ Local Draft Storage ============

  /// Save a local log draft (for optimistic UI)
  Future<void> saveLocalDraft(String localId, Map<String, dynamic> draft) async {
    final box = await _getLocalDraftsBox();
    await box.put(localId, draft.toString());
  }

  /// Get a local log draft
  Future<Map<String, dynamic>?> getLocalDraft(String localId) async {
    final box = await _getLocalDraftsBox();
    final data = box.get(localId);
    if (data != null) {
      // Note: This is a simplified implementation
      // In production, you'd want proper JSON serialization
      return {'localId': localId, 'raw': data};
    }
    return null;
  }

  /// Remove a local draft (after successful sync)
  Future<void> removeLocalDraft(String localId) async {
    final box = await _getLocalDraftsBox();
    await box.delete(localId);
  }
}

/// Statistics about the sync queue
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
