import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pairing_planet2_frontend/data/repositories/sync_queue_repository.dart';
import 'package:pairing_planet2_frontend/data/datasources/sync/sync_queue_local_data_source.dart';
import 'package:pairing_planet2_frontend/data/models/sync/sync_queue_item.dart';

import '../../helpers/mock_providers.dart';

void main() {
  late SyncQueueRepository repository;
  late MockSyncQueueLocalDataSource mockLocalDataSource;

  setUp(() {
    mockLocalDataSource = MockSyncQueueLocalDataSource();
    repository = SyncQueueRepository(mockLocalDataSource);
  });

  setUpAll(() {
    registerFallbackValue(_FakeSyncQueueItem());
  });

  group('SyncQueueRepository', () {
    group('queueLogPost', () {
      test('should create and add item to queue', () async {
        // Arrange
        when(() => mockLocalDataSource.addToQueue(any()))
            .thenAnswer((_) async {});

        // Act
        final result = await repository.queueLogPost(
          outcome: 'SUCCESS',
          localPhotoPaths: ['/path/to/photo.jpg'],
          recipePublicId: 'recipe-123',
          title: 'My Log',
          content: 'Great dish!',
          hashtags: ['cooking', 'food'],
        );

        // Assert
        expect(result.type, SyncOperationType.createLogPost);
        expect(result.status, SyncStatus.pending);
        expect(result.localId, isNotNull);
        expect(result.id, isNotNull);
        verify(() => mockLocalDataSource.addToQueue(any())).called(1);
      });

      test('should create item with null optional fields', () async {
        // Arrange
        when(() => mockLocalDataSource.addToQueue(any()))
            .thenAnswer((_) async {});

        // Act
        final result = await repository.queueLogPost(
          outcome: 'PARTIAL',
          localPhotoPaths: [],
        );

        // Assert
        expect(result.type, SyncOperationType.createLogPost);
        expect(result.status, SyncStatus.pending);
        expect(result.localId, isNotNull);
      });

      test('should generate unique IDs for each item', () async {
        // Arrange
        when(() => mockLocalDataSource.addToQueue(any()))
            .thenAnswer((_) async {});

        // Act
        final result1 = await repository.queueLogPost(
          outcome: 'SUCCESS',
          localPhotoPaths: [],
        );
        final result2 = await repository.queueLogPost(
          outcome: 'SUCCESS',
          localPhotoPaths: [],
        );

        // Assert
        expect(result1.id, isNot(result2.id));
        expect(result1.localId, isNot(result2.localId));
      });
    });

    group('queueImageUpload', () {
      test('should create and add image upload item to queue', () async {
        // Arrange
        when(() => mockLocalDataSource.addToQueue(any()))
            .thenAnswer((_) async {});

        // Act
        final result = await repository.queueImageUpload(
          localPath: '/path/to/image.png',
          parentItemId: 'parent-123',
        );

        // Assert
        expect(result.type, SyncOperationType.uploadImage);
        expect(result.status, SyncStatus.pending);
        expect(result.payload, contains('localPath'));
        expect(result.payload, contains('parentItemId'));
        verify(() => mockLocalDataSource.addToQueue(any())).called(1);
      });
    });

    group('getPendingItems', () {
      test('should return pending items from data source', () async {
        // Arrange
        final pendingItems = [
          _createTestItem(id: '1', status: SyncStatus.pending),
          _createTestItem(id: '2', status: SyncStatus.pending),
        ];
        when(() => mockLocalDataSource.getPendingItems())
            .thenAnswer((_) async => pendingItems);

        // Act
        final result = await repository.getPendingItems();

        // Assert
        expect(result, hasLength(2));
        expect(result[0].id, '1');
        expect(result[1].id, '2');
        verify(() => mockLocalDataSource.getPendingItems()).called(1);
      });

      test('should return empty list when no pending items', () async {
        // Arrange
        when(() => mockLocalDataSource.getPendingItems())
            .thenAnswer((_) async => []);

        // Act
        final result = await repository.getPendingItems();

        // Assert
        expect(result, isEmpty);
      });
    });

    group('getItem', () {
      test('should return item when found', () async {
        // Arrange
        final item = _createTestItem(id: 'test-123');
        when(() => mockLocalDataSource.getItem('test-123'))
            .thenAnswer((_) async => item);

        // Act
        final result = await repository.getItem('test-123');

        // Assert
        expect(result, isNotNull);
        expect(result!.id, 'test-123');
        verify(() => mockLocalDataSource.getItem('test-123')).called(1);
      });

      test('should return null when item not found', () async {
        // Arrange
        when(() => mockLocalDataSource.getItem('nonexistent'))
            .thenAnswer((_) async => null);

        // Act
        final result = await repository.getItem('nonexistent');

        // Assert
        expect(result, isNull);
      });
    });

    group('markSyncing', () {
      test('should update item status to syncing', () async {
        // Arrange
        final item = _createTestItem(id: 'item-1', status: SyncStatus.pending);
        when(() => mockLocalDataSource.getItem('item-1'))
            .thenAnswer((_) async => item);
        when(() => mockLocalDataSource.updateItem(any()))
            .thenAnswer((_) async {});

        // Act
        await repository.markSyncing('item-1');

        // Assert
        final captured = verify(() => mockLocalDataSource.updateItem(captureAny()))
            .captured
            .single as SyncQueueItem;
        expect(captured.status, SyncStatus.syncing);
        expect(captured.lastAttemptAt, isNotNull);
      });

      test('should do nothing when item not found', () async {
        // Arrange
        when(() => mockLocalDataSource.getItem('nonexistent'))
            .thenAnswer((_) async => null);

        // Act
        await repository.markSyncing('nonexistent');

        // Assert
        verifyNever(() => mockLocalDataSource.updateItem(any()));
      });
    });

    group('markSynced', () {
      test('should update item status to synced', () async {
        // Arrange
        final item = _createTestItem(id: 'item-1', status: SyncStatus.syncing);
        when(() => mockLocalDataSource.getItem('item-1'))
            .thenAnswer((_) async => item);
        when(() => mockLocalDataSource.updateItem(any()))
            .thenAnswer((_) async {});

        // Act
        await repository.markSynced('item-1');

        // Assert
        final captured = verify(() => mockLocalDataSource.updateItem(captureAny()))
            .captured
            .single as SyncQueueItem;
        expect(captured.status, SyncStatus.synced);
      });

      test('should do nothing when item not found', () async {
        // Arrange
        when(() => mockLocalDataSource.getItem('nonexistent'))
            .thenAnswer((_) async => null);

        // Act
        await repository.markSynced('nonexistent');

        // Assert
        verifyNever(() => mockLocalDataSource.updateItem(any()));
      });
    });

    group('markFailed', () {
      test('should update item status to failed with error message', () async {
        // Arrange
        final item = _createTestItem(id: 'item-1', status: SyncStatus.syncing);
        when(() => mockLocalDataSource.getItem('item-1'))
            .thenAnswer((_) async => item);
        when(() => mockLocalDataSource.updateItem(any()))
            .thenAnswer((_) async {});

        // Act
        await repository.markFailed('item-1', 'Network error');

        // Assert
        final captured = verify(() => mockLocalDataSource.updateItem(captureAny()))
            .captured
            .single as SyncQueueItem;
        expect(captured.status, SyncStatus.failed);
        expect(captured.errorMessage, 'Network error');
        expect(captured.retryCount, 1);
      });

      test('should mark as abandoned after max retries', () async {
        // Arrange
        final item = _createTestItem(
          id: 'item-1',
          status: SyncStatus.syncing,
          retryCount: 2,
        );
        when(() => mockLocalDataSource.getItem('item-1'))
            .thenAnswer((_) async => item);
        when(() => mockLocalDataSource.updateItem(any()))
            .thenAnswer((_) async {});

        // Act
        await repository.markFailed('item-1', 'Final failure');

        // Assert
        final captured = verify(() => mockLocalDataSource.updateItem(captureAny()))
            .captured
            .single as SyncQueueItem;
        expect(captured.status, SyncStatus.abandoned);
        expect(captured.retryCount, 3);
      });
    });

    group('removeItem', () {
      test('should call removeItem on data source', () async {
        // Arrange
        when(() => mockLocalDataSource.removeItem('item-123'))
            .thenAnswer((_) async {});

        // Act
        await repository.removeItem('item-123');

        // Assert
        verify(() => mockLocalDataSource.removeItem('item-123')).called(1);
      });
    });

    group('getStats', () {
      test('should return stats from data source', () async {
        // Arrange
        const stats = SyncQueueStats(
          pending: 5,
          syncing: 2,
          synced: 10,
          failed: 1,
          abandoned: 0,
        );
        when(() => mockLocalDataSource.getStats())
            .thenAnswer((_) async => stats);

        // Act
        final result = await repository.getStats();

        // Assert
        expect(result.pending, 5);
        expect(result.syncing, 2);
        expect(result.synced, 10);
        expect(result.failed, 1);
        expect(result.abandoned, 0);
        expect(result.total, 18);
        expect(result.needsSync, 6);
        expect(result.hasUnsyncedItems, isTrue);
      });

      test('should return stats with no unsynced items', () async {
        // Arrange
        const stats = SyncQueueStats(
          pending: 0,
          syncing: 0,
          synced: 5,
          failed: 0,
          abandoned: 2,
        );
        when(() => mockLocalDataSource.getStats())
            .thenAnswer((_) async => stats);

        // Act
        final result = await repository.getStats();

        // Assert
        expect(result.hasUnsyncedItems, isFalse);
      });
    });

    group('hasItemsToSync', () {
      test('should return true when items need syncing', () async {
        // Arrange
        when(() => mockLocalDataSource.hasPendingItems())
            .thenAnswer((_) async => true);

        // Act
        final result = await repository.hasItemsToSync();

        // Assert
        expect(result, isTrue);
      });

      test('should return false when no items need syncing', () async {
        // Arrange
        when(() => mockLocalDataSource.hasPendingItems())
            .thenAnswer((_) async => false);

        // Act
        final result = await repository.hasItemsToSync();

        // Assert
        expect(result, isFalse);
      });
    });

    group('getPendingCount', () {
      test('should return count from data source', () async {
        // Arrange
        when(() => mockLocalDataSource.getPendingCount())
            .thenAnswer((_) async => 7);

        // Act
        final result = await repository.getPendingCount();

        // Assert
        expect(result, 7);
      });

      test('should return zero when no pending items', () async {
        // Arrange
        when(() => mockLocalDataSource.getPendingCount())
            .thenAnswer((_) async => 0);

        // Act
        final result = await repository.getPendingCount();

        // Assert
        expect(result, 0);
      });
    });

    group('cleanupSyncedItems', () {
      test('should return count of cleaned items', () async {
        // Arrange
        when(() => mockLocalDataSource.clearSyncedItems())
            .thenAnswer((_) async => 5);

        // Act
        final result = await repository.cleanupSyncedItems();

        // Assert
        expect(result, 5);
        verify(() => mockLocalDataSource.clearSyncedItems()).called(1);
      });
    });

    group('cleanupAbandonedItems', () {
      test('should return count of cleaned items', () async {
        // Arrange
        when(() => mockLocalDataSource.clearAbandonedItems())
            .thenAnswer((_) async => 3);

        // Act
        final result = await repository.cleanupAbandonedItems();

        // Assert
        expect(result, 3);
        verify(() => mockLocalDataSource.clearAbandonedItems()).called(1);
      });
    });

    group('getAllItems', () {
      test('should return all items from data source', () async {
        // Arrange
        final items = [
          _createTestItem(id: '1', status: SyncStatus.pending),
          _createTestItem(id: '2', status: SyncStatus.synced),
          _createTestItem(id: '3', status: SyncStatus.failed),
        ];
        when(() => mockLocalDataSource.getAllItems())
            .thenAnswer((_) async => items);

        // Act
        final result = await repository.getAllItems();

        // Assert
        expect(result, hasLength(3));
      });
    });

    group('findByLocalId', () {
      test('should return item when found by localId', () async {
        // Arrange
        final items = [
          _createTestItem(id: '1', localId: 'local-abc'),
          _createTestItem(id: '2', localId: 'local-xyz'),
        ];
        when(() => mockLocalDataSource.getAllItems())
            .thenAnswer((_) async => items);

        // Act
        final result = await repository.findByLocalId('local-abc');

        // Assert
        expect(result, isNotNull);
        expect(result!.id, '1');
        expect(result.localId, 'local-abc');
      });

      test('should return null when localId not found', () async {
        // Arrange
        final items = [
          _createTestItem(id: '1', localId: 'local-abc'),
        ];
        when(() => mockLocalDataSource.getAllItems())
            .thenAnswer((_) async => items);

        // Act
        final result = await repository.findByLocalId('nonexistent');

        // Assert
        expect(result, isNull);
      });

      test('should return null for empty list', () async {
        // Arrange
        when(() => mockLocalDataSource.getAllItems())
            .thenAnswer((_) async => []);

        // Act
        final result = await repository.findByLocalId('any-id');

        // Assert
        expect(result, isNull);
      });
    });

    group('retryItem', () {
      test('should reset status to pending for retryable item', () async {
        // Arrange
        final item = _createTestItem(
          id: 'item-1',
          status: SyncStatus.failed,
          retryCount: 1,
        );
        when(() => mockLocalDataSource.getItem('item-1'))
            .thenAnswer((_) async => item);
        when(() => mockLocalDataSource.updateItem(any()))
            .thenAnswer((_) async {});

        // Act
        await repository.retryItem('item-1');

        // Assert
        final captured = verify(() => mockLocalDataSource.updateItem(captureAny()))
            .captured
            .single as SyncQueueItem;
        expect(captured.status, SyncStatus.pending);
      });

      test('should not retry abandoned item', () async {
        // Arrange
        final item = _createTestItem(
          id: 'item-1',
          status: SyncStatus.failed,
          retryCount: 3,
        );
        when(() => mockLocalDataSource.getItem('item-1'))
            .thenAnswer((_) async => item);

        // Act
        await repository.retryItem('item-1');

        // Assert
        verifyNever(() => mockLocalDataSource.updateItem(any()));
      });

      test('should not retry already synced item', () async {
        // Arrange
        final item = _createTestItem(
          id: 'item-1',
          status: SyncStatus.synced,
        );
        when(() => mockLocalDataSource.getItem('item-1'))
            .thenAnswer((_) async => item);

        // Act
        await repository.retryItem('item-1');

        // Assert
        verifyNever(() => mockLocalDataSource.updateItem(any()));
      });
    });

    group('getPendingLogPosts', () {
      test('should return only pending/syncing log posts', () async {
        // Arrange
        final items = [
          _createTestItem(
            id: '1',
            type: SyncOperationType.createLogPost,
            status: SyncStatus.pending,
          ),
          _createTestItem(
            id: '2',
            type: SyncOperationType.createLogPost,
            status: SyncStatus.syncing,
          ),
          _createTestItem(
            id: '3',
            type: SyncOperationType.createLogPost,
            status: SyncStatus.synced,
          ),
          _createTestItem(
            id: '4',
            type: SyncOperationType.uploadImage,
            status: SyncStatus.pending,
          ),
        ];
        when(() => mockLocalDataSource.getAllItems())
            .thenAnswer((_) async => items);

        // Act
        final result = await repository.getPendingLogPosts();

        // Assert
        expect(result, hasLength(2));
        expect(result.every((item) =>
          item.type == SyncOperationType.createLogPost), isTrue);
        expect(result.every((item) =>
          item.status == SyncStatus.pending ||
          item.status == SyncStatus.syncing), isTrue);
      });

      test('should return empty list when no pending log posts', () async {
        // Arrange
        final items = [
          _createTestItem(
            id: '1',
            type: SyncOperationType.uploadImage,
            status: SyncStatus.pending,
          ),
          _createTestItem(
            id: '2',
            type: SyncOperationType.createLogPost,
            status: SyncStatus.synced,
          ),
        ];
        when(() => mockLocalDataSource.getAllItems())
            .thenAnswer((_) async => items);

        // Act
        final result = await repository.getPendingLogPosts();

        // Assert
        expect(result, isEmpty);
      });
    });

    group('resetSyncingItems', () {
      test('should reset all syncing items to pending', () async {
        // Arrange
        final syncingItems = [
          _createTestItem(id: '1', status: SyncStatus.syncing),
          _createTestItem(id: '2', status: SyncStatus.syncing),
        ];
        when(() => mockLocalDataSource.getItemsByStatus(SyncStatus.syncing))
            .thenAnswer((_) async => syncingItems);
        when(() => mockLocalDataSource.updateItem(any()))
            .thenAnswer((_) async {});

        // Act
        await repository.resetSyncingItems();

        // Assert - capture all calls and verify
        final captured = verify(() => mockLocalDataSource.updateItem(captureAny()))
            .captured;
        expect(captured, hasLength(2));
        for (final item in captured) {
          expect((item as SyncQueueItem).status, SyncStatus.pending);
        }
      });

      test('should do nothing when no syncing items', () async {
        // Arrange
        when(() => mockLocalDataSource.getItemsByStatus(SyncStatus.syncing))
            .thenAnswer((_) async => []);

        // Act
        await repository.resetSyncingItems();

        // Assert
        verifyNever(() => mockLocalDataSource.updateItem(any()));
      });
    });
  });
}

/// Helper to create test SyncQueueItem
SyncQueueItem _createTestItem({
  required String id,
  SyncOperationType type = SyncOperationType.createLogPost,
  SyncStatus status = SyncStatus.pending,
  int retryCount = 0,
  String? localId,
}) {
  return SyncQueueItem(
    id: id,
    type: type,
    payload: '{}',
    status: status,
    retryCount: retryCount,
    createdAt: DateTime.now(),
    localId: localId,
  );
}

/// Fake class for registerFallbackValue
class _FakeSyncQueueItem extends Fake implements SyncQueueItem {}
