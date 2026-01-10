import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:pairing_planet2_frontend/data/datasources/sync/sync_queue_local_data_source.dart';
import 'package:pairing_planet2_frontend/data/models/sync/sync_queue_item.dart';

/// Repository for managing the sync queue
class SyncQueueRepository {
  final SyncQueueLocalDataSource _localDataSource;
  final Uuid _uuid = const Uuid();

  SyncQueueRepository(this._localDataSource);

  /// Queue a new log post for sync
  Future<SyncQueueItem> queueLogPost({
    required String outcome,
    required List<String> localPhotoPaths,
    String? recipePublicId,
    String? title,
    String? content,
    List<String>? hashtags,
  }) async {
    final localId = _uuid.v4();
    final payload = CreateLogPostPayload(
      title: title,
      content: content ?? '',
      outcome: outcome,
      recipePublicId: recipePublicId,
      localPhotoPaths: localPhotoPaths,
      hashtags: hashtags,
    );

    final item = SyncQueueItem(
      id: _uuid.v4(),
      type: SyncOperationType.createLogPost,
      payload: payload.toJsonString(),
      status: SyncStatus.pending,
      createdAt: DateTime.now(),
      localId: localId,
    );

    await _localDataSource.addToQueue(item);
    return item;
  }

  /// Queue an image upload
  Future<SyncQueueItem> queueImageUpload({
    required String localPath,
    required String parentItemId,
  }) async {
    final payload = jsonEncode({
      'localPath': localPath,
      'parentItemId': parentItemId,
    });

    final item = SyncQueueItem(
      id: _uuid.v4(),
      type: SyncOperationType.uploadImage,
      payload: payload,
      status: SyncStatus.pending,
      createdAt: DateTime.now(),
    );

    await _localDataSource.addToQueue(item);
    return item;
  }

  /// Get all items pending sync
  Future<List<SyncQueueItem>> getPendingItems() async {
    return await _localDataSource.getPendingItems();
  }

  /// Get a specific item by ID
  Future<SyncQueueItem?> getItem(String id) async {
    return await _localDataSource.getItem(id);
  }

  /// Mark an item as syncing
  Future<void> markSyncing(String id) async {
    final item = await _localDataSource.getItem(id);
    if (item != null) {
      await _localDataSource.updateItem(item.markSyncing());
    }
  }

  /// Mark an item as successfully synced
  Future<void> markSynced(String id) async {
    final item = await _localDataSource.getItem(id);
    if (item != null) {
      await _localDataSource.updateItem(item.markSynced());
    }
  }

  /// Mark an item as failed
  Future<void> markFailed(String id, String error) async {
    final item = await _localDataSource.getItem(id);
    if (item != null) {
      await _localDataSource.updateItem(item.markFailed(error));
    }
  }

  /// Remove an item from the queue
  Future<void> removeItem(String id) async {
    await _localDataSource.removeItem(id);
  }

  /// Get queue statistics
  Future<SyncQueueStats> getStats() async {
    return await _localDataSource.getStats();
  }

  /// Check if there are items to sync
  Future<bool> hasItemsToSync() async {
    return await _localDataSource.hasPendingItems();
  }

  /// Get count of pending items
  Future<int> getPendingCount() async {
    return await _localDataSource.getPendingCount();
  }

  /// Clean up synced items
  Future<int> cleanupSyncedItems() async {
    return await _localDataSource.clearSyncedItems();
  }

  /// Clean up abandoned items
  Future<int> cleanupAbandonedItems() async {
    return await _localDataSource.clearAbandonedItems();
  }

  /// Get all items (for debugging)
  Future<List<SyncQueueItem>> getAllItems() async {
    return await _localDataSource.getAllItems();
  }

  /// Check if an item with local ID exists
  Future<SyncQueueItem?> findByLocalId(String localId) async {
    final items = await _localDataSource.getAllItems();
    for (final item in items) {
      if (item.localId == localId) {
        return item;
      }
    }
    return null;
  }

  /// Retry a failed item
  Future<void> retryItem(String id) async {
    final item = await _localDataSource.getItem(id);
    if (item != null && item.shouldRetry) {
      await _localDataSource.updateItem(
        item.copyWith(status: SyncStatus.pending),
      );
    }
  }

  /// Get pending log posts (for optimistic UI display)
  /// Returns items that are pending or syncing
  Future<List<SyncQueueItem>> getPendingLogPosts() async {
    final items = await _localDataSource.getAllItems();
    return items
        .where((item) => item.type == SyncOperationType.createLogPost)
        .where((item) =>
            item.status == SyncStatus.pending ||
            item.status == SyncStatus.syncing)
        .toList();
  }

  /// Reset all syncing items to pending (for app restart recovery)
  Future<void> resetSyncingItems() async {
    final items = await _localDataSource.getItemsByStatus(SyncStatus.syncing);
    for (final item in items) {
      await _localDataSource.updateItem(
        item.copyWith(status: SyncStatus.pending),
      );
    }
  }
}
