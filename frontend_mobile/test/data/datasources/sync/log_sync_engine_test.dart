import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pairing_planet2_frontend/data/datasources/sync/log_sync_engine.dart';
import 'package:pairing_planet2_frontend/data/datasources/sync/sync_queue_local_data_source.dart'
    show SyncQueueStats;
import 'package:pairing_planet2_frontend/data/models/sync/sync_queue_item.dart';
import 'package:pairing_planet2_frontend/data/repositories/sync_queue_repository.dart';

// Mocks
class MockSyncQueueRepository extends Mock implements SyncQueueRepository {}

class MockConnectivity extends Mock implements Connectivity {}

class MockRef extends Mock implements Ref {}

void main() {
  group('LogSyncEngine', () {
    late MockSyncQueueRepository mockSyncQueueRepository;
    late MockConnectivity mockConnectivity;
    late MockRef mockRef;

    setUp(() {
      mockSyncQueueRepository = MockSyncQueueRepository();
      mockConnectivity = MockConnectivity();
      mockRef = MockRef();
    });

    test('should create engine with correct dependencies', () {
      // Act
      final engine = LogSyncEngine(
        mockRef,
        mockSyncQueueRepository,
        mockConnectivity,
      );

      // Assert
      expect(engine, isNotNull);
    });

    test('SyncEngineStatus should report correct state', () {
      // Act
      const status = SyncEngineStatus(
        isRunning: true,
        isSyncing: false,
        pendingCount: 5,
        failedCount: 2,
        abandonedCount: 1,
      );

      // Assert
      expect(status.isRunning, isTrue);
      expect(status.isSyncing, isFalse);
      expect(status.pendingCount, 5);
      expect(status.failedCount, 2);
      expect(status.abandonedCount, 1);
      expect(status.hasUnsyncedItems, isTrue);
    });

    test('SyncEngineStatus hasUnsyncedItems should be false when all synced', () {
      // Act
      const status = SyncEngineStatus(
        isRunning: true,
        isSyncing: false,
        pendingCount: 0,
        failedCount: 0,
        abandonedCount: 0,
      );

      // Assert
      expect(status.hasUnsyncedItems, isFalse);
    });

    test('SyncEngineStatus toString should include all fields', () {
      // Act
      const status = SyncEngineStatus(
        isRunning: true,
        isSyncing: true,
        pendingCount: 3,
        failedCount: 1,
        abandonedCount: 0,
      );

      final statusString = status.toString();

      // Assert
      expect(statusString, contains('running: true'));
      expect(statusString, contains('syncing: true'));
      expect(statusString, contains('pending: 3'));
      expect(statusString, contains('failed: 1'));
    });
  });

  group('SyncQueueItem', () {
    test('should create item with correct fields', () {
      // Act
      final item = SyncQueueItem(
        id: 'test-id',
        type: SyncOperationType.createLogPost,
        payload: '{"title":"Test"}',
        status: SyncStatus.pending,
        createdAt: DateTime(2024, 1, 1),
        retryCount: 0,
      );

      // Assert
      expect(item.id, 'test-id');
      expect(item.type, SyncOperationType.createLogPost);
      expect(item.payload, '{"title":"Test"}');
      expect(item.status, SyncStatus.pending);
      expect(item.retryCount, 0);
    });

    test('SyncStatus should have correct values', () {
      expect(SyncStatus.values, hasLength(5));
      expect(SyncStatus.pending, isNotNull);
      expect(SyncStatus.syncing, isNotNull);
      expect(SyncStatus.synced, isNotNull);
      expect(SyncStatus.failed, isNotNull);
      expect(SyncStatus.abandoned, isNotNull);
    });

    test('SyncOperationType should have correct values', () {
      expect(SyncOperationType.values, hasLength(4));
      expect(SyncOperationType.createLogPost, isNotNull);
      expect(SyncOperationType.uploadImage, isNotNull);
      expect(SyncOperationType.updateLogPost, isNotNull);
      expect(SyncOperationType.deleteLogPost, isNotNull);
    });
  });

  group('CreateLogPostPayload', () {
    test('should parse from JSON string', () {
      // Arrange
      const jsonString = '{"title":"My Log","content":"Test content","outcome":"SUCCESS","recipePublicId":"recipe-123","localPhotoPaths":["/path/photo.jpg"],"hashtags":["cooking","test"]}';

      // Act
      final payload = CreateLogPostPayload.fromJsonString(jsonString);

      // Assert
      expect(payload.title, 'My Log');
      expect(payload.content, 'Test content');
      expect(payload.outcome, 'SUCCESS');
      expect(payload.recipePublicId, 'recipe-123');
      expect(payload.localPhotoPaths, ['/path/photo.jpg']);
      expect(payload.hashtags, ['cooking', 'test']);
    });

    test('should convert to JSON string', () {
      // Arrange
      final payload = CreateLogPostPayload(
        title: 'Test',
        content: 'Content',
        outcome: 'PARTIAL',
        recipePublicId: 'recipe-456',
        localPhotoPaths: ['/path/img.jpg'],
        hashtags: ['tag1'],
      );

      // Act
      final jsonString = payload.toJsonString();

      // Assert
      expect(jsonString, contains('"title":"Test"'));
      expect(jsonString, contains('"outcome":"PARTIAL"'));
      expect(jsonString, contains('"recipePublicId":"recipe-456"'));
    });

    test('should handle minimal valid payload', () {
      // Arrange - content, outcome, and localPhotoPaths are required
      final payload = CreateLogPostPayload(
        content: '',
        outcome: 'SUCCESS',
        localPhotoPaths: [],
      );

      // Assert
      expect(payload.title, isNull);
      expect(payload.content, '');
      expect(payload.outcome, 'SUCCESS');
      expect(payload.localPhotoPaths, isEmpty);
      expect(payload.recipePublicId, isNull);
      expect(payload.hashtags, isNull);
    });
  });

  group('LogSyncEngine concurrency', () {
    late MockSyncQueueRepository mockSyncQueueRepository;
    late MockConnectivity mockConnectivity;
    late MockRef mockRef;
    late LogSyncEngine engine;

    setUp(() {
      mockSyncQueueRepository = MockSyncQueueRepository();
      mockConnectivity = MockConnectivity();
      mockRef = MockRef();
      engine = LogSyncEngine(
        mockRef,
        mockSyncQueueRepository,
        mockConnectivity,
      );
    });

    test('blocks concurrent sync attempts - only first executes', () async {
      final processingCompleter = Completer<void>();
      var getPendingItemsCallCount = 0;

      // Setup mocks
      when(() => mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.wifi]);
      when(() => mockSyncQueueRepository.getPendingItems())
          .thenAnswer((_) async {
        getPendingItemsCallCount++;
        await processingCompleter.future;
        return <SyncQueueItem>[];
      });
      when(() => mockSyncQueueRepository.cleanupSyncedItems())
          .thenAnswer((_) async => 0);

      // Start first sync
      final firstSync = engine.triggerSync();

      // Allow first sync to start processing
      await Future.delayed(Duration.zero);

      // Try second sync immediately (should be blocked)
      final secondSync = engine.triggerSync();

      // Try third sync (should also be blocked)
      final thirdSync = engine.triggerSync();

      // Complete first sync
      processingCompleter.complete();
      await firstSync;
      await secondSync;
      await thirdSync;

      // Should only have called getPendingItems once
      expect(getPendingItemsCallCount, 1);
    });

    test('allows sync after previous sync completes', () async {
      var getPendingItemsCallCount = 0;

      // Setup mocks
      when(() => mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.wifi]);
      when(() => mockSyncQueueRepository.getPendingItems())
          .thenAnswer((_) async {
        getPendingItemsCallCount++;
        return <SyncQueueItem>[];
      });
      when(() => mockSyncQueueRepository.cleanupSyncedItems())
          .thenAnswer((_) async => 0);

      // First sync
      await engine.triggerSync();

      // Second sync (should work after first completes)
      await engine.triggerSync();

      // Third sync
      await engine.triggerSync();

      // Should have called getPendingItems three times
      expect(getPendingItemsCallCount, 3);
    });

    test('skips sync when no network connectivity', () async {
      var getPendingItemsCallCount = 0;

      // Setup mocks - no connectivity
      when(() => mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.none]);
      when(() => mockSyncQueueRepository.getPendingItems())
          .thenAnswer((_) async {
        getPendingItemsCallCount++;
        return <SyncQueueItem>[];
      });

      // Try sync
      await engine.triggerSync();

      // Should not have called getPendingItems
      expect(getPendingItemsCallCount, 0);
    });

    test('sync resets flag even when connectivity check returns no network', () async {
      var callCount = 0;

      // First call - no connectivity
      when(() => mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.none]);

      await engine.triggerSync();

      // Second call - with connectivity
      when(() => mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.wifi]);
      when(() => mockSyncQueueRepository.getPendingItems())
          .thenAnswer((_) async {
        callCount++;
        return <SyncQueueItem>[];
      });
      when(() => mockSyncQueueRepository.cleanupSyncedItems())
          .thenAnswer((_) async => 0);

      await engine.triggerSync();

      // Second sync should have executed
      expect(callCount, 1);
    });

    test('getStatus returns correct syncing state', () async {
      // Setup mocks for getStats
      when(() => mockSyncQueueRepository.getStats()).thenAnswer(
        (_) async => const SyncQueueStats(
          pending: 2,
          syncing: 1,
          synced: 5,
          failed: 0,
          abandoned: 0,
        ),
      );

      final status = await engine.getStatus();

      expect(status.pendingCount, 2);
      expect(status.failedCount, 0);
      expect(status.hasUnsyncedItems, isTrue);
    });
  });
}
