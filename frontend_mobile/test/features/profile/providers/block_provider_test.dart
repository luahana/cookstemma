import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pairing_planet2_frontend/features/profile/providers/block_provider.dart';
import 'package:pairing_planet2_frontend/data/models/block/blocked_user_dto.dart';
import 'package:pairing_planet2_frontend/data/models/report/report_reason.dart';

import '../../../helpers/mock_providers.dart';

void main() {
  late MockBlockRemoteDataSource mockDataSource;

  setUpAll(() {
    // Register fallback values for mocktail any() matchers
    registerFallbackValue(ReportReason.spam);
  });

  setUp(() {
    mockDataSource = MockBlockRemoteDataSource();
  });

  group('BlockActionState', () {
    test('should have correct default values', () {
      // Act
      final state = BlockActionState();

      // Assert
      expect(state.isLoading, isFalse);
      expect(state.isBlocked, isFalse);
      expect(state.amBlocked, isFalse);
      expect(state.error, isNull);
    });

    test('copyWith should update specified fields', () {
      // Arrange
      final state = BlockActionState();

      // Act
      final updated = state.copyWith(
        isLoading: true,
        isBlocked: true,
        amBlocked: true,
        error: 'Some error',
      );

      // Assert
      expect(updated.isLoading, isTrue);
      expect(updated.isBlocked, isTrue);
      expect(updated.amBlocked, isTrue);
      expect(updated.error, 'Some error');
    });

    test('copyWith should retain unspecified fields', () {
      // Arrange
      final state = BlockActionState(isBlocked: true, amBlocked: true);

      // Act
      final updated = state.copyWith(isLoading: true);

      // Assert
      expect(updated.isLoading, isTrue);
      expect(updated.isBlocked, isTrue);
      expect(updated.amBlocked, isTrue);
      expect(updated.error, isNull);
    });
  });

  group('BlockActionNotifier', () {
    test('should initialize with correct state', () {
      // Arrange & Act
      final notifier = BlockActionNotifier(
        dataSource: mockDataSource,
        userId: 'user-123',
        initialBlockedState: true,
        initialAmBlockedState: false,
      );

      // Assert
      expect(notifier.state.isBlocked, isTrue);
      expect(notifier.state.amBlocked, isFalse);
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, isNull);
    });

    test('toggleBlock should optimistically update to blocked', () async {
      // Arrange
      when(() => mockDataSource.blockUser(any())).thenAnswer((_) async {});
      final notifier = BlockActionNotifier(
        dataSource: mockDataSource,
        userId: 'user-123',
        initialBlockedState: false,
        initialAmBlockedState: false,
      );

      // Act
      final future = notifier.toggleBlock();

      // Assert - optimistic update should happen immediately
      expect(notifier.state.isBlocked, isTrue);
      expect(notifier.state.isLoading, isTrue);

      await future;

      expect(notifier.state.isBlocked, isTrue);
      expect(notifier.state.isLoading, isFalse);
      verify(() => mockDataSource.blockUser('user-123')).called(1);
    });

    test('toggleBlock should optimistically update to unblocked', () async {
      // Arrange
      when(() => mockDataSource.unblockUser(any())).thenAnswer((_) async {});
      final notifier = BlockActionNotifier(
        dataSource: mockDataSource,
        userId: 'user-456',
        initialBlockedState: true,
        initialAmBlockedState: false,
      );

      // Act
      final future = notifier.toggleBlock();

      // Assert - optimistic update
      expect(notifier.state.isBlocked, isFalse);
      expect(notifier.state.isLoading, isTrue);

      await future;

      expect(notifier.state.isBlocked, isFalse);
      expect(notifier.state.isLoading, isFalse);
      verify(() => mockDataSource.unblockUser('user-456')).called(1);
    });

    test('toggleBlock should rollback on block error', () async {
      // Arrange
      when(() => mockDataSource.blockUser(any()))
          .thenThrow(Exception('Network error'));
      final notifier = BlockActionNotifier(
        dataSource: mockDataSource,
        userId: 'user-123',
        initialBlockedState: false,
        initialAmBlockedState: false,
      );

      // Act
      await notifier.toggleBlock();

      // Assert - should rollback to original state
      expect(notifier.state.isBlocked, isFalse);
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, contains('Network error'));
    });

    test('toggleBlock should rollback on unblock error', () async {
      // Arrange
      when(() => mockDataSource.unblockUser(any()))
          .thenThrow(Exception('Server error'));
      final notifier = BlockActionNotifier(
        dataSource: mockDataSource,
        userId: 'user-123',
        initialBlockedState: true,
        initialAmBlockedState: false,
      );

      // Act
      await notifier.toggleBlock();

      // Assert - should rollback to blocked state
      expect(notifier.state.isBlocked, isTrue);
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, contains('Server error'));
    });

    test('toggleBlock should ignore double-tap while loading', () async {
      // Arrange
      var blockCallCount = 0;
      when(() => mockDataSource.blockUser(any())).thenAnswer((_) async {
        blockCallCount++;
        await Future.delayed(const Duration(milliseconds: 100));
      });
      final notifier = BlockActionNotifier(
        dataSource: mockDataSource,
        userId: 'user-123',
        initialBlockedState: false,
        initialAmBlockedState: false,
      );

      // Act - attempt double toggle
      final future1 = notifier.toggleBlock();
      final result2 = notifier.toggleBlock(); // Should return false

      await Future.wait([future1, Future.value(result2)]);

      // Assert - should only call once
      expect(blockCallCount, 1);
    });

    test('toggleBlock should clear previous error on retry', () async {
      // Arrange
      when(() => mockDataSource.blockUser(any()))
          .thenThrow(Exception('First error'));
      final notifier = BlockActionNotifier(
        dataSource: mockDataSource,
        userId: 'user-123',
        initialBlockedState: false,
        initialAmBlockedState: false,
      );

      // Act - first toggle fails
      await notifier.toggleBlock();
      expect(notifier.state.error, isNotNull);

      // Setup success for second attempt
      when(() => mockDataSource.blockUser(any())).thenAnswer((_) async {});

      // Act - second toggle succeeds
      await notifier.toggleBlock();

      // Assert - error should be cleared
      expect(notifier.state.error, isNull);
      expect(notifier.state.isBlocked, isTrue);
    });
  });

  group('ReportActionState', () {
    test('should have correct default values', () {
      // Act
      final state = ReportActionState();

      // Assert
      expect(state.isLoading, isFalse);
      expect(state.isReported, isFalse);
      expect(state.error, isNull);
    });

    test('copyWith should update specified fields', () {
      // Arrange
      final state = ReportActionState();

      // Act
      final updated = state.copyWith(
        isLoading: true,
        isReported: true,
        error: 'Error',
      );

      // Assert
      expect(updated.isLoading, isTrue);
      expect(updated.isReported, isTrue);
      expect(updated.error, 'Error');
    });
  });

  group('ReportActionNotifier', () {
    test('should initialize with correct state', () {
      // Arrange & Act
      final notifier = ReportActionNotifier(
        dataSource: mockDataSource,
        userId: 'user-123',
      );

      // Assert
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.isReported, isFalse);
      expect(notifier.state.error, isNull);
    });

    test('report should set isReported on success', () async {
      // Arrange
      when(() => mockDataSource.reportUser(any(), any(), description: any(named: 'description')))
          .thenAnswer((_) async {});
      final notifier = ReportActionNotifier(
        dataSource: mockDataSource,
        userId: 'user-123',
      );

      // Act
      final result = await notifier.report(ReportReason.spam);

      // Assert
      expect(result, isTrue);
      expect(notifier.state.isReported, isTrue);
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, isNull);
    });

    test('report should set error on failure', () async {
      // Arrange
      when(() => mockDataSource.reportUser(any(), any(), description: any(named: 'description')))
          .thenThrow(Exception('Report failed'));
      final notifier = ReportActionNotifier(
        dataSource: mockDataSource,
        userId: 'user-123',
      );

      // Act
      final result = await notifier.report(ReportReason.harassment);

      // Assert
      expect(result, isFalse);
      expect(notifier.state.isReported, isFalse);
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, contains('Report failed'));
    });

    test('report should ignore duplicate reports', () async {
      // Arrange
      when(() => mockDataSource.reportUser(any(), any(), description: any(named: 'description')))
          .thenAnswer((_) async {});
      final notifier = ReportActionNotifier(
        dataSource: mockDataSource,
        userId: 'user-123',
      );

      // Act - first report
      await notifier.report(ReportReason.spam);
      expect(notifier.state.isReported, isTrue);

      // Act - second report should be ignored
      final result = await notifier.report(ReportReason.spam);

      // Assert
      expect(result, isFalse);
      verify(() => mockDataSource.reportUser(any(), any(), description: any(named: 'description')))
          .called(1); // Only called once
    });
  });

  group('BlockedUsersListState', () {
    test('should have correct default values', () {
      // Act
      final state = BlockedUsersListState();

      // Assert
      expect(state.items, isEmpty);
      expect(state.hasNext, isTrue);
      expect(state.currentPage, 0);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('copyWith should update specified fields', () {
      // Arrange
      final blockedUsers = [
        _createTestBlockedUser('1'),
        _createTestBlockedUser('2'),
      ];
      final state = BlockedUsersListState();

      // Act
      final updated = state.copyWith(
        items: blockedUsers,
        hasNext: false,
        currentPage: 2,
        isLoading: true,
        error: 'Error',
      );

      // Assert
      expect(updated.items, hasLength(2));
      expect(updated.hasNext, isFalse);
      expect(updated.currentPage, 2);
      expect(updated.isLoading, isTrue);
      expect(updated.error, 'Error');
    });
  });

  group('BlockedUsersListNotifier', () {
    test('should fetch first page on init', () async {
      // Arrange
      final response = BlockedUsersListResponse(
        content: [_createTestBlockedUser('1')],
        hasNext: true,
        page: 0,
        size: 20,
        totalElements: 10,
      );
      when(() => mockDataSource.getBlockedUsers(page: 0))
          .thenAnswer((_) async => response);

      // Act
      final notifier = BlockedUsersListNotifier(dataSource: mockDataSource);

      // Wait for init to complete
      await Future.delayed(const Duration(milliseconds: 50));

      // Assert
      expect(notifier.state.items, hasLength(1));
      expect(notifier.state.currentPage, 0);
      expect(notifier.state.hasNext, isTrue);
      expect(notifier.state.isLoading, isFalse);
      verify(() => mockDataSource.getBlockedUsers(page: 0)).called(1);
    });

    test('fetchNextPage should append items for page > 0', () async {
      // Arrange
      final page0Response = BlockedUsersListResponse(
        content: [_createTestBlockedUser('1')],
        hasNext: true,
        page: 0,
        size: 20,
        totalElements: 2,
      );
      final page1Response = BlockedUsersListResponse(
        content: [_createTestBlockedUser('2')],
        hasNext: false,
        page: 1,
        size: 20,
        totalElements: 2,
      );
      when(() => mockDataSource.getBlockedUsers(page: 0))
          .thenAnswer((_) async => page0Response);
      when(() => mockDataSource.getBlockedUsers(page: 1))
          .thenAnswer((_) async => page1Response);

      // Act
      final notifier = BlockedUsersListNotifier(dataSource: mockDataSource);
      await Future.delayed(const Duration(milliseconds: 50)); // Wait for init

      await notifier.fetchNextPage();

      // Assert
      expect(notifier.state.items, hasLength(2));
      expect(notifier.state.items[0].publicId, '1');
      expect(notifier.state.items[1].publicId, '2');
      expect(notifier.state.currentPage, 1);
      expect(notifier.state.hasNext, isFalse);
    });

    test('fetchNextPage should do nothing when no more pages', () async {
      // Arrange
      final response = BlockedUsersListResponse(
        content: [_createTestBlockedUser('1')],
        hasNext: false,
        page: 0,
        size: 20,
        totalElements: 1,
      );
      when(() => mockDataSource.getBlockedUsers(page: 0))
          .thenAnswer((_) async => response);

      // Act
      final notifier = BlockedUsersListNotifier(dataSource: mockDataSource);
      await Future.delayed(const Duration(milliseconds: 50));

      await notifier.fetchNextPage();

      // Assert - should only be called once (initial fetch)
      verify(() => mockDataSource.getBlockedUsers(page: 0)).called(1);
    });

    test('refresh should replace items with page 0', () async {
      // Arrange
      final page0Response = BlockedUsersListResponse(
        content: [_createTestBlockedUser('1')],
        hasNext: true,
        page: 0,
        size: 20,
        totalElements: 2,
      );
      final refreshResponse = BlockedUsersListResponse(
        content: [_createTestBlockedUser('3'), _createTestBlockedUser('4')],
        hasNext: true,
        page: 0,
        size: 20,
        totalElements: 2,
      );
      var callCount = 0;
      when(() => mockDataSource.getBlockedUsers(page: 0))
          .thenAnswer((_) async {
        callCount++;
        if (callCount == 1) return page0Response;
        return refreshResponse;
      });

      // Act
      final notifier = BlockedUsersListNotifier(dataSource: mockDataSource);
      await Future.delayed(const Duration(milliseconds: 50));
      await notifier.refresh();

      // Assert - items should be replaced, not appended
      expect(notifier.state.items, hasLength(2));
      expect(notifier.state.items[0].publicId, '3');
      expect(notifier.state.items[1].publicId, '4');
      expect(notifier.state.currentPage, 0);
    });

    test('removeBlockedUser should remove user from list', () async {
      // Arrange
      final response = BlockedUsersListResponse(
        content: [
          _createTestBlockedUser('1'),
          _createTestBlockedUser('2'),
          _createTestBlockedUser('3'),
        ],
        hasNext: false,
        page: 0,
        size: 20,
        totalElements: 3,
      );
      when(() => mockDataSource.getBlockedUsers(page: 0))
          .thenAnswer((_) async => response);

      // Act
      final notifier = BlockedUsersListNotifier(dataSource: mockDataSource);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(notifier.state.items, hasLength(3));

      notifier.removeBlockedUser('2');

      // Assert
      expect(notifier.state.items, hasLength(2));
      expect(notifier.state.items.any((u) => u.publicId == '2'), isFalse);
      expect(notifier.state.items[0].publicId, '1');
      expect(notifier.state.items[1].publicId, '3');
    });

    test('should set error state on failure', () async {
      // Arrange
      when(() => mockDataSource.getBlockedUsers(page: 0))
          .thenThrow(Exception('Network error'));

      // Act
      final notifier = BlockedUsersListNotifier(dataSource: mockDataSource);
      await Future.delayed(const Duration(milliseconds: 50));

      // Assert
      expect(notifier.state.error, contains('Network error'));
      expect(notifier.state.isLoading, isFalse);
    });
  });
}

/// Helper to create test BlockedUserDto
BlockedUserDto _createTestBlockedUser(String id) {
  return BlockedUserDto(
    publicId: id,
    username: 'user_$id',
    profileImageUrl: null,
    blockedAt: DateTime.now().toIso8601String(),
  );
}
