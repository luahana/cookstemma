import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pairing_planet2_frontend/core/providers/image_providers.dart';
import 'package:pairing_planet2_frontend/core/providers/isar_provider.dart';
import 'package:pairing_planet2_frontend/data/datasources/sync/sync_queue_local_data_source.dart';
import 'package:pairing_planet2_frontend/data/models/sync/sync_queue_item.dart';
import 'package:pairing_planet2_frontend/data/repositories/sync_queue_repository.dart';
import 'package:pairing_planet2_frontend/domain/entities/log_post/create_log_post_request.dart';
import 'package:pairing_planet2_frontend/features/log_post/providers/log_post_providers.dart';
import 'package:pairing_planet2_frontend/features/log_post/providers/log_post_list_provider.dart';
import 'package:pairing_planet2_frontend/features/profile/providers/profile_provider.dart';
import 'package:pairing_planet2_frontend/features/recipe/providers/recipe_providers.dart';

/// Background sync engine for processing the sync queue
/// Handles offline-first log creation with automatic retry
class LogSyncEngine {
  final Ref _ref;
  final SyncQueueRepository _syncQueueRepository;
  final Connectivity _connectivity;

  Timer? _syncTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isSyncing = false;

  static const Duration _syncInterval = Duration(seconds: 30);

  LogSyncEngine(this._ref, this._syncQueueRepository, this._connectivity);

  /// Start the sync engine
  void start() {
    // Reset any items stuck in syncing state from previous session
    _syncQueueRepository.resetSyncingItems();

    // Start periodic sync
    _syncTimer = Timer.periodic(_syncInterval, (_) => _processSyncQueue());

    // Listen for connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (results) {
        if (!results.contains(ConnectivityResult.none)) {
          // Network reconnected - trigger immediate sync
          _processSyncQueue();
        }
      },
    );

    // Initial sync attempt
    _processSyncQueue();
  }

  /// Stop the sync engine
  void stop() {
    _syncTimer?.cancel();
    _syncTimer = null;
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }

  /// Trigger an immediate sync
  Future<void> triggerSync() async {
    await _processSyncQueue();
  }

  /// Process the sync queue
  Future<void> _processSyncQueue() async {
    if (_isSyncing) return;

    // Check connectivity first
    final connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      return; // No network, skip sync
    }

    _isSyncing = true;

    try {
      final pendingItems = await _syncQueueRepository.getPendingItems();

      for (final item in pendingItems) {
        await _processItem(item);
      }

      // Cleanup synced items periodically
      await _syncQueueRepository.cleanupSyncedItems();
    } finally {
      _isSyncing = false;
    }
  }

  /// Process a single sync queue item
  Future<void> _processItem(SyncQueueItem item) async {
    try {
      await _syncQueueRepository.markSyncing(item.id);

      switch (item.type) {
        case SyncOperationType.createLogPost:
          await _processCreateLogPost(item);
          break;
        case SyncOperationType.uploadImage:
          await _processImageUpload(item);
          break;
        case SyncOperationType.updateLogPost:
          // TODO: Implement update
          break;
        case SyncOperationType.deleteLogPost:
          // TODO: Implement delete
          break;
      }
    } catch (e) {
      await _syncQueueRepository.markFailed(item.id, e.toString());
    }
  }

  /// Process a create log post operation
  Future<void> _processCreateLogPost(SyncQueueItem item) async {
    final payload = CreateLogPostPayload.fromJsonString(item.payload);

    // Step 1: Upload images if not already uploaded
    List<String> imagePublicIds = payload.uploadedPhotoIds?.toList() ?? [];

    // Upload any remaining local photos that haven't been uploaded yet
    if (imagePublicIds.length < payload.localPhotoPaths.length) {
      final uploadUseCase = _ref.read(uploadImageWithTrackingUseCaseProvider);

      for (int i = imagePublicIds.length; i < payload.localPhotoPaths.length; i++) {
        final localPath = payload.localPhotoPaths[i];
        final file = File(localPath);

        if (await file.exists()) {
          final uploadResult = await uploadUseCase.execute(
            file: file,
            type: 'LOG_POST',
          );

          final result = uploadResult.fold(
            (failure) => throw Exception('Image upload failed: ${failure.message}'),
            (response) => response.imagePublicId,
          );
          imagePublicIds.add(result);
        }
      }

      // Update payload with uploaded image IDs for retry
      final updatedPayload = CreateLogPostPayload(
        title: payload.title,
        content: payload.content,
        outcome: payload.outcome,
        recipePublicId: payload.recipePublicId,
        localPhotoPaths: payload.localPhotoPaths,
        uploadedPhotoIds: imagePublicIds,
        hashtags: payload.hashtags,
      );

      final updatedItem = item.copyWith(payload: updatedPayload.toJsonString());
      await _syncQueueRepository.markSyncing(item.id);
      // Update the item with the new payload via repository
      await _syncQueueRepository.updateItem(updatedItem);
    }

    // Step 2: Create log post
    if (imagePublicIds.isNotEmpty || payload.recipePublicId != null) {
      final createLogUseCase = _ref.read(createLogPostUseCaseProvider);

      final request = CreateLogPostRequest(
        title: payload.title,
        content: payload.content.isNotEmpty ? payload.content : 'Quick log',
        outcome: payload.outcome,
        recipePublicId: payload.recipePublicId ?? '',
        imagePublicIds: imagePublicIds,
        hashtags: payload.hashtags,
      );

      final result = await createLogUseCase.execute(request);

      result.fold(
        (failure) => throw Exception('Log creation failed: ${failure.message}'),
        (logPost) async {
          // Success! Mark as synced
          await _syncQueueRepository.markSynced(item.id);

          // Notify UI to refresh
          _ref.invalidate(logPostPaginatedListProvider);
          _ref.invalidate(myLogsProvider);
          _ref.invalidate(myProfileProvider);
          // Invalidate recipe detail to refresh "See How Others Made It" section
          if (payload.recipePublicId != null && payload.recipePublicId!.isNotEmpty) {
            _ref.invalidate(recipeDetailWithTrackingProvider(payload.recipePublicId!));
          }
        },
      );
    } else {
      throw Exception('Cannot create log without image or recipe');
    }
  }

  /// Process an image upload operation
  Future<void> _processImageUpload(SyncQueueItem item) async {
    // Image upload is typically handled as part of createLogPost
    // This is for standalone image uploads if needed
    await _syncQueueRepository.markSynced(item.id);
  }

  /// Get current sync status
  Future<SyncEngineStatus> getStatus() async {
    final stats = await _syncQueueRepository.getStats();
    return SyncEngineStatus(
      isRunning: _syncTimer != null,
      isSyncing: _isSyncing,
      pendingCount: stats.pending,
      failedCount: stats.failed,
      abandonedCount: stats.abandoned,
    );
  }
}

/// Status of the sync engine
class SyncEngineStatus {
  final bool isRunning;
  final bool isSyncing;
  final int pendingCount;
  final int failedCount;
  final int abandonedCount;

  const SyncEngineStatus({
    required this.isRunning,
    required this.isSyncing,
    required this.pendingCount,
    required this.failedCount,
    required this.abandonedCount,
  });

  bool get hasUnsyncedItems => pendingCount > 0 || failedCount > 0;

  @override
  String toString() {
    return 'SyncEngineStatus(running: $isRunning, syncing: $isSyncing, pending: $pendingCount, failed: $failedCount)';
  }
}

// ============ Providers ============

/// Provider for sync queue local data source
final syncQueueLocalDataSourceProvider = Provider((ref) {
  final isar = ref.read(isarProvider);
  return SyncQueueLocalDataSource(isar);
});

/// Provider for sync queue repository
final syncQueueRepositoryProvider = Provider((ref) {
  return SyncQueueRepository(ref.read(syncQueueLocalDataSourceProvider));
});

/// Provider for connectivity
final connectivityProvider = Provider((ref) {
  return Connectivity();
});

/// Provider for log sync engine
final logSyncEngineProvider = Provider((ref) {
  final engine = LogSyncEngine(
    ref,
    ref.read(syncQueueRepositoryProvider),
    ref.read(connectivityProvider),
  );

  // Start the engine when created
  engine.start();

  // Stop when disposed
  ref.onDispose(() {
    engine.stop();
  });

  return engine;
});

/// Provider for sync queue stats (for UI)
final syncQueueStatsProvider = FutureProvider<SyncQueueStats>((ref) async {
  final repository = ref.read(syncQueueRepositoryProvider);
  return await repository.getStats();
});

/// Provider for pending sync count (for badges)
final pendingSyncCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.read(syncQueueRepositoryProvider);
  return await repository.getPendingCount();
});
