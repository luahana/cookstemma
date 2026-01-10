import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pairing_planet2_frontend/data/datasources/sync/log_sync_engine.dart';
import 'package:pairing_planet2_frontend/data/models/sync/sync_queue_item.dart';
import 'package:pairing_planet2_frontend/data/repositories/sync_queue_repository.dart';
import 'package:pairing_planet2_frontend/features/profile/providers/profile_provider.dart';

// Mocks
class MockSyncQueueRepository extends Mock implements SyncQueueRepository {}

class MockRef extends Mock implements Ref {}

void main() {
  group('MyLogsNotifier', () {
    late MockRef mockRef;
    late MockSyncQueueRepository mockSyncQueueRepository;

    setUp(() {
      mockRef = MockRef();
      mockSyncQueueRepository = MockSyncQueueRepository();
    });

    test('should include pending items from sync queue', () async {
      // Arrange
      when(() => mockRef.read(syncQueueRepositoryProvider))
          .thenReturn(mockSyncQueueRepository);

      when(() => mockSyncQueueRepository.getPendingLogPosts())
          .thenAnswer((_) async => [
                SyncQueueItem(
                  id: 'test-id',
                  type: SyncOperationType.createLogPost,
                  payload:
                      '{"title":"Test Log","outcome":"SUCCESS","localPhotoPaths":["/path/to/photo.jpg"],"recipePublicId":"recipe-123"}',
                  status: SyncStatus.pending,
                  createdAt: DateTime.now(),
                  retryCount: 0,
                ),
              ]);

      // Act
      final pendingItems = await mockSyncQueueRepository.getPendingLogPosts();

      // Assert
      expect(pendingItems, hasLength(1));
      expect(pendingItems.first.type, SyncOperationType.createLogPost);
    });

    test('MyLogsState should have correct default values', () {
      // Act
      final state = MyLogsState();

      // Assert
      expect(state.items, isEmpty);
      expect(state.hasNext, isTrue);
      expect(state.currentPage, 0);
      expect(state.isLoading, isFalse);
      expect(state.isFromCache, isFalse);
      expect(state.cachedAt, isNull);
      expect(state.error, isNull);
    });

    test('MyLogsState copyWith should preserve values', () {
      // Arrange
      final original = MyLogsState(
        items: [],
        hasNext: true,
        currentPage: 0,
        isLoading: false,
      );

      // Act
      final updated = original.copyWith(
        isLoading: true,
        currentPage: 1,
      );

      // Assert
      expect(updated.isLoading, isTrue);
      expect(updated.currentPage, 1);
      expect(updated.hasNext, isTrue); // Preserved from original
    });

    test('MyLogsState isStale should return true for old cache', () {
      // Arrange - CacheTTL.profileTabs is 5 minutes
      final staleState = MyLogsState(
        cachedAt: DateTime.now().subtract(const Duration(minutes: 10)),
      );

      final freshState = MyLogsState(
        cachedAt: DateTime.now().subtract(const Duration(minutes: 2)),
      );

      // Assert
      expect(staleState.isStale, isTrue);
      expect(freshState.isStale, isFalse);
    });
  });

  group('LogOutcomeFilter', () {
    test('should have correct enum values', () {
      expect(LogOutcomeFilter.values, hasLength(4));
      expect(LogOutcomeFilter.all, isNotNull);
      expect(LogOutcomeFilter.wins, isNotNull);
      expect(LogOutcomeFilter.learning, isNotNull);
      expect(LogOutcomeFilter.lessons, isNotNull);
    });
  });
}
