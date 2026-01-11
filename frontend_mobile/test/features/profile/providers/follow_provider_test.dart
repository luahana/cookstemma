import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pairing_planet2_frontend/features/profile/providers/follow_provider.dart';
import 'package:pairing_planet2_frontend/data/models/follow/follower_dto.dart';

import '../../../helpers/mock_providers.dart';

void main() {
  late MockFollowRemoteDataSource mockDataSource;

  setUp(() {
    mockDataSource = MockFollowRemoteDataSource();
  });

  group('FollowActionState', () {
    test('should have correct default values', () {
      // Act
      final state = FollowActionState();

      // Assert
      expect(state.isLoading, isFalse);
      expect(state.isFollowing, isFalse);
      expect(state.error, isNull);
    });

    test('copyWith should update specified fields', () {
      // Arrange
      final state = FollowActionState();

      // Act
      final updated = state.copyWith(
        isLoading: true,
        isFollowing: true,
        error: 'Some error',
      );

      // Assert
      expect(updated.isLoading, isTrue);
      expect(updated.isFollowing, isTrue);
      expect(updated.error, 'Some error');
    });

    test('copyWith should retain unspecified fields', () {
      // Arrange
      final state = FollowActionState(isFollowing: true);

      // Act
      final updated = state.copyWith(isLoading: true);

      // Assert
      expect(updated.isLoading, isTrue);
      expect(updated.isFollowing, isTrue);
      expect(updated.error, isNull);
    });
  });

  group('FollowActionNotifier', () {
    test('should initialize with correct state', () {
      // Arrange & Act
      final notifier = FollowActionNotifier(
        dataSource: mockDataSource,
        userId: 'user-123',
        initialFollowState: true,
      );

      // Assert
      expect(notifier.state.isFollowing, isTrue);
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, isNull);
    });

    test('toggleFollow should optimistically update to following', () async {
      // Arrange
      when(() => mockDataSource.follow(any())).thenAnswer((_) async {});
      final notifier = FollowActionNotifier(
        dataSource: mockDataSource,
        userId: 'user-123',
        initialFollowState: false,
      );

      // Act
      final future = notifier.toggleFollow();

      // Assert - optimistic update should happen immediately
      expect(notifier.state.isFollowing, isTrue);
      expect(notifier.state.isLoading, isTrue);

      await future;

      expect(notifier.state.isFollowing, isTrue);
      expect(notifier.state.isLoading, isFalse);
      verify(() => mockDataSource.follow('user-123')).called(1);
    });

    test('toggleFollow should optimistically update to unfollowing', () async {
      // Arrange
      when(() => mockDataSource.unfollow(any())).thenAnswer((_) async {});
      final notifier = FollowActionNotifier(
        dataSource: mockDataSource,
        userId: 'user-456',
        initialFollowState: true,
      );

      // Act
      final future = notifier.toggleFollow();

      // Assert - optimistic update
      expect(notifier.state.isFollowing, isFalse);
      expect(notifier.state.isLoading, isTrue);

      await future;

      expect(notifier.state.isFollowing, isFalse);
      expect(notifier.state.isLoading, isFalse);
      verify(() => mockDataSource.unfollow('user-456')).called(1);
    });

    test('toggleFollow should rollback on follow error', () async {
      // Arrange
      when(() => mockDataSource.follow(any()))
          .thenThrow(Exception('Network error'));
      final notifier = FollowActionNotifier(
        dataSource: mockDataSource,
        userId: 'user-123',
        initialFollowState: false,
      );

      // Act
      await notifier.toggleFollow();

      // Assert - should rollback to original state
      expect(notifier.state.isFollowing, isFalse);
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, contains('Network error'));
    });

    test('toggleFollow should rollback on unfollow error', () async {
      // Arrange
      when(() => mockDataSource.unfollow(any()))
          .thenThrow(Exception('Server error'));
      final notifier = FollowActionNotifier(
        dataSource: mockDataSource,
        userId: 'user-123',
        initialFollowState: true,
      );

      // Act
      await notifier.toggleFollow();

      // Assert - should rollback to following state
      expect(notifier.state.isFollowing, isTrue);
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, contains('Server error'));
    });

    test('toggleFollow should ignore double-tap while loading', () async {
      // Arrange
      var followCallCount = 0;
      when(() => mockDataSource.follow(any())).thenAnswer((_) async {
        followCallCount++;
        await Future.delayed(const Duration(milliseconds: 100));
      });
      final notifier = FollowActionNotifier(
        dataSource: mockDataSource,
        userId: 'user-123',
        initialFollowState: false,
      );

      // Act - attempt double toggle
      final future1 = notifier.toggleFollow();
      final future2 = notifier.toggleFollow(); // Should be ignored

      await Future.wait([future1, future2]);

      // Assert - should only call once
      expect(followCallCount, 1);
    });

    test('toggleFollow should clear previous error', () async {
      // Arrange
      when(() => mockDataSource.follow(any()))
          .thenThrow(Exception('First error'));
      final notifier = FollowActionNotifier(
        dataSource: mockDataSource,
        userId: 'user-123',
        initialFollowState: false,
      );

      // Act - first toggle fails
      await notifier.toggleFollow();
      expect(notifier.state.error, isNotNull);

      // Setup success for second attempt
      when(() => mockDataSource.follow(any())).thenAnswer((_) async {});

      // Act - second toggle succeeds
      await notifier.toggleFollow();

      // Assert - error should be cleared
      expect(notifier.state.error, isNull);
      expect(notifier.state.isFollowing, isTrue);
    });
  });

  group('FollowersListState', () {
    test('should have correct default values', () {
      // Act
      final state = FollowersListState();

      // Assert
      expect(state.items, isEmpty);
      expect(state.hasNext, isTrue);
      expect(state.currentPage, 0);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('copyWith should update specified fields', () {
      // Arrange
      final followers = [
        _createTestFollower('1'),
        _createTestFollower('2'),
      ];
      final state = FollowersListState();

      // Act
      final updated = state.copyWith(
        items: followers,
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

  group('FollowersListNotifier', () {
    test('should fetch first page on init', () async {
      // Arrange
      final response = FollowListResponse(
        content: [_createTestFollower('1')],
        hasNext: true,
        page: 0,
        size: 20,
      );
      when(() => mockDataSource.getFollowers(any(), page: any(named: 'page')))
          .thenAnswer((_) async => response);

      // Act
      final notifier = FollowersListNotifier(
        dataSource: mockDataSource,
        userId: 'user-123',
      );

      // Wait for init to complete
      await Future.delayed(const Duration(milliseconds: 50));

      // Assert
      expect(notifier.state.items, hasLength(1));
      expect(notifier.state.currentPage, 0);
      expect(notifier.state.hasNext, isTrue);
      expect(notifier.state.isLoading, isFalse);
      verify(() => mockDataSource.getFollowers('user-123', page: 0)).called(1);
    });

    test('fetchNextPage should append items for page > 0', () async {
      // Arrange
      final page0Response = FollowListResponse(
        content: [_createTestFollower('1')],
        hasNext: true,
        page: 0,
        size: 20,
      );
      final page1Response = FollowListResponse(
        content: [_createTestFollower('2')],
        hasNext: false,
        page: 1,
        size: 20,
      );
      var pageCounter = 0;
      when(() => mockDataSource.getFollowers(any(), page: any(named: 'page')))
          .thenAnswer((_) async {
        return pageCounter++ == 0 ? page0Response : page1Response;
      });

      // Act
      final notifier = FollowersListNotifier(
        dataSource: mockDataSource,
        userId: 'user-123',
      );
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
      final response = FollowListResponse(
        content: [_createTestFollower('1')],
        hasNext: false,
        page: 0,
        size: 20,
      );
      when(() => mockDataSource.getFollowers(any(), page: any(named: 'page')))
          .thenAnswer((_) async => response);

      // Act
      final notifier = FollowersListNotifier(
        dataSource: mockDataSource,
        userId: 'user-123',
      );
      await Future.delayed(const Duration(milliseconds: 50));

      await notifier.fetchNextPage();

      // Assert - should only be called once (initial fetch)
      verify(() => mockDataSource.getFollowers(any(), page: any(named: 'page')))
          .called(1);
    });

    test('refresh should replace items with page 0', () async {
      // Arrange
      final page0Response = FollowListResponse(
        content: [_createTestFollower('1')],
        hasNext: true,
        page: 0,
        size: 20,
      );
      final page1Response = FollowListResponse(
        content: [_createTestFollower('2')],
        hasNext: false,
        page: 1,
        size: 20,
      );
      final refreshResponse = FollowListResponse(
        content: [_createTestFollower('3'), _createTestFollower('4')],
        hasNext: true,
        page: 0,
        size: 20,
      );
      var callCount = 0;
      when(() => mockDataSource.getFollowers(any(), page: any(named: 'page')))
          .thenAnswer((_) async {
        callCount++;
        if (callCount == 1) return page0Response;
        if (callCount == 2) return page1Response;
        return refreshResponse;
      });

      // Act
      final notifier = FollowersListNotifier(
        dataSource: mockDataSource,
        userId: 'user-123',
      );
      await Future.delayed(const Duration(milliseconds: 50));
      await notifier.fetchNextPage();
      await notifier.refresh();

      // Assert - items should be replaced, not appended
      expect(notifier.state.items, hasLength(2));
      expect(notifier.state.items[0].publicId, '3');
      expect(notifier.state.items[1].publicId, '4');
      expect(notifier.state.currentPage, 0);
    });

    test('should set error state on failure', () async {
      // Arrange
      when(() => mockDataSource.getFollowers(any(), page: any(named: 'page')))
          .thenThrow(Exception('Network error'));

      // Act
      final notifier = FollowersListNotifier(
        dataSource: mockDataSource,
        userId: 'user-123',
      );
      await Future.delayed(const Duration(milliseconds: 50));

      // Assert
      expect(notifier.state.error, contains('Network error'));
      expect(notifier.state.isLoading, isFalse);
    });
  });

  group('FollowingListNotifier', () {
    test('should fetch following on init', () async {
      // Arrange
      final response = FollowListResponse(
        content: [_createTestFollower('1')],
        hasNext: true,
        page: 0,
        size: 20,
      );
      when(() => mockDataSource.getFollowing(any(), page: any(named: 'page')))
          .thenAnswer((_) async => response);

      // Act
      final notifier = FollowingListNotifier(
        dataSource: mockDataSource,
        userId: 'user-123',
      );
      await Future.delayed(const Duration(milliseconds: 50));

      // Assert
      expect(notifier.state.items, hasLength(1));
      verify(() => mockDataSource.getFollowing('user-123', page: 0)).called(1);
    });

    test('fetchNextPage should append items for following', () async {
      // Arrange
      final page0Response = FollowListResponse(
        content: [_createTestFollower('1')],
        hasNext: true,
        page: 0,
        size: 20,
      );
      final page1Response = FollowListResponse(
        content: [_createTestFollower('2')],
        hasNext: false,
        page: 1,
        size: 20,
      );
      var pageCounter = 0;
      when(() => mockDataSource.getFollowing(any(), page: any(named: 'page')))
          .thenAnswer((_) async {
        return pageCounter++ == 0 ? page0Response : page1Response;
      });

      // Act
      final notifier = FollowingListNotifier(
        dataSource: mockDataSource,
        userId: 'user-123',
      );
      await Future.delayed(const Duration(milliseconds: 50));
      await notifier.fetchNextPage();

      // Assert
      expect(notifier.state.items, hasLength(2));
      expect(notifier.state.currentPage, 1);
    });

    test('refresh should reset to page 0 for following', () async {
      // Arrange
      final page0Response = FollowListResponse(
        content: [_createTestFollower('1')],
        hasNext: true,
        page: 0,
        size: 20,
      );
      final refreshResponse = FollowListResponse(
        content: [_createTestFollower('new')],
        hasNext: false,
        page: 0,
        size: 20,
      );
      var callCount = 0;
      when(() => mockDataSource.getFollowing(any(), page: any(named: 'page')))
          .thenAnswer((_) async {
        return ++callCount == 1 ? page0Response : refreshResponse;
      });

      // Act
      final notifier = FollowingListNotifier(
        dataSource: mockDataSource,
        userId: 'user-123',
      );
      await Future.delayed(const Duration(milliseconds: 50));
      await notifier.refresh();

      // Assert
      expect(notifier.state.items, hasLength(1));
      expect(notifier.state.items[0].publicId, 'new');
      expect(notifier.state.currentPage, 0);
    });
  });
}

/// Helper to create test FollowerDto
FollowerDto _createTestFollower(String id) {
  return FollowerDto(
    publicId: id,
    username: 'user_$id',
    profileImageUrl: null,
    isFollowingBack: false,
    followedAt: DateTime.now().toIso8601String(),
  );
}
