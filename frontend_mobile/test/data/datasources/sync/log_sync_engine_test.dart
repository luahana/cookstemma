import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pairing_planet2_frontend/data/datasources/sync/log_sync_engine.dart';
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
}
