import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pairing_planet2_frontend/core/models/log_outcome.dart';
import 'package:pairing_planet2_frontend/domain/entities/log_post/log_post_summary.dart';
import 'package:pairing_planet2_frontend/features/log_post/providers/log_filter_provider.dart';
import 'package:pairing_planet2_frontend/features/log_post/providers/log_post_list_provider.dart';

void main() {
  group('LogPostListState', () {
    test('should create state with required fields', () {
      // Arrange & Act
      final state = LogPostListState(
        items: [],
        hasNext: true,
      );

      // Assert
      expect(state.items, isEmpty);
      expect(state.hasNext, isTrue);
      expect(state.searchQuery, isNull);
      expect(state.filterState, isNull);
      expect(state.recipeId, isNull);
    });

    test('should create state with all fields', () {
      // Arrange
      final logs = [
        LogPostSummary(
          id: 'log-1',
          title: 'Test Log',
          outcome: 'SUCCESS',
          thumbnailUrl: 'https://example.com/thumb.jpg',
          creatorName: 'user1',
          createdAt: DateTime(2024, 1, 15),
        ),
      ];
      const filterState = LogFilterState(
        selectedOutcomes: {LogOutcome.success},
        timeFilter: LogTimeFilter.thisWeek,
      );

      // Act
      final state = LogPostListState(
        items: logs,
        hasNext: false,
        searchQuery: 'kimchi',
        filterState: filterState,
        recipeId: 'recipe-123',
      );

      // Assert
      expect(state.items, hasLength(1));
      expect(state.hasNext, isFalse);
      expect(state.searchQuery, 'kimchi');
      expect(state.filterState, filterState);
      expect(state.recipeId, 'recipe-123');
    });

    test('should store multiple items', () {
      // Arrange
      final logs = List.generate(
        15,
        (i) => LogPostSummary(
          id: 'log-$i',
          title: 'Log $i',
          outcome: ['SUCCESS', 'PARTIAL', 'FAILED'][i % 3],
          thumbnailUrl: null,
          creatorName: 'user$i',
        ),
      );

      // Act
      final state = LogPostListState(
        items: logs,
        hasNext: true,
      );

      // Assert
      expect(state.items, hasLength(15));
      expect(state.items[0].id, 'log-0');
      expect(state.items[14].id, 'log-14');
    });

    test('should differentiate recipe-filtered state from general state', () {
      // Arrange
      final generalState = LogPostListState(
        items: [],
        hasNext: true,
        searchQuery: 'search',
      );

      final recipeFilteredState = LogPostListState(
        items: [],
        hasNext: true,
        recipeId: 'recipe-123',
      );

      // Assert
      expect(generalState.recipeId, isNull);
      expect(generalState.searchQuery, isNotNull);
      expect(recipeFilteredState.recipeId, isNotNull);
      expect(recipeFilteredState.searchQuery, isNull);
    });
  });

  group('LogFilterState', () {
    test('should have correct default values', () {
      // Arrange & Act
      const state = LogFilterState();

      // Assert
      expect(state.selectedOutcomes, isEmpty);
      expect(state.timeFilter, LogTimeFilter.all);
      expect(state.sortOption, LogSortOption.recent);
      expect(state.showOnlyWithPhotos, isFalse);
    });

    test('hasActiveFilters should return false for default state', () {
      // Arrange
      const state = LogFilterState();

      // Assert
      expect(state.hasActiveFilters, isFalse);
    });

    test('hasActiveFilters should return true when outcomes are selected', () {
      // Arrange
      const state = LogFilterState(selectedOutcomes: {LogOutcome.success});

      // Assert
      expect(state.hasActiveFilters, isTrue);
    });

    test('hasActiveFilters should return true when time filter is not all', () {
      // Arrange
      const state = LogFilterState(timeFilter: LogTimeFilter.thisWeek);

      // Assert
      expect(state.hasActiveFilters, isTrue);
    });

    test('hasActiveFilters should return true when showOnlyWithPhotos is true', () {
      // Arrange
      const state = LogFilterState(showOnlyWithPhotos: true);

      // Assert
      expect(state.hasActiveFilters, isTrue);
    });

    test('activeFilterCount should return correct count', () {
      // Arrange
      const noFilters = LogFilterState();
      const oneOutcome = LogFilterState(selectedOutcomes: {LogOutcome.success});
      const twoOutcomes = LogFilterState(
        selectedOutcomes: {LogOutcome.success, LogOutcome.partial},
      );
      const mixedFilters = LogFilterState(
        selectedOutcomes: {LogOutcome.success, LogOutcome.partial},
        timeFilter: LogTimeFilter.thisWeek,
        showOnlyWithPhotos: true,
      );

      // Assert
      expect(noFilters.activeFilterCount, 0);
      expect(oneOutcome.activeFilterCount, 1);
      expect(twoOutcomes.activeFilterCount, 2);
      expect(mixedFilters.activeFilterCount, 4); // 2 outcomes + time + photos
    });

    test('copyWith should update only specified fields', () {
      // Arrange
      const original = LogFilterState(
        selectedOutcomes: {LogOutcome.success},
        timeFilter: LogTimeFilter.today,
        sortOption: LogSortOption.recent,
        showOnlyWithPhotos: true,
      );

      // Act
      final updated = original.copyWith(
        timeFilter: LogTimeFilter.thisMonth,
        showOnlyWithPhotos: false,
      );

      // Assert
      expect(updated.selectedOutcomes, {LogOutcome.success}); // unchanged
      expect(updated.timeFilter, LogTimeFilter.thisMonth);
      expect(updated.sortOption, LogSortOption.recent); // unchanged
      expect(updated.showOnlyWithPhotos, isFalse);
    });

    test('toQueryParams should return correct params for outcomes', () {
      // Arrange
      const state = LogFilterState(
        selectedOutcomes: {LogOutcome.success, LogOutcome.partial},
      );

      // Act
      final params = state.toQueryParams();

      // Assert
      expect(params['outcomes'], containsAll(['SUCCESS', 'PARTIAL']));
    });

    test('toQueryParams should include sort params', () {
      // Arrange
      const recentState = LogFilterState(sortOption: LogSortOption.recent);
      const oldestState = LogFilterState(sortOption: LogSortOption.oldest);

      // Act
      final recentParams = recentState.toQueryParams();
      final oldestParams = oldestState.toQueryParams();

      // Assert
      expect(recentParams['sort'], 'createdAt');
      expect(recentParams['order'], 'desc');
      expect(oldestParams['sort'], 'createdAt');
      expect(oldestParams['order'], 'asc');
    });

    test('toQueryParams should include hasPhotos when showOnlyWithPhotos is true', () {
      // Arrange
      const state = LogFilterState(showOnlyWithPhotos: true);

      // Act
      final params = state.toQueryParams();

      // Assert
      expect(params['hasPhotos'], isTrue);
    });
  });

  group('LogFilterNotifier', () {
    late ProviderContainer container;
    late LogFilterNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(logFilterProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('should have default state on build', () {
      // Assert
      final state = container.read(logFilterProvider);
      expect(state.selectedOutcomes, isEmpty);
      expect(state.timeFilter, LogTimeFilter.all);
      expect(state.sortOption, LogSortOption.recent);
      expect(state.showOnlyWithPhotos, isFalse);
    });

    test('toggleOutcome should add outcome if not selected', () {
      // Act
      notifier.toggleOutcome(LogOutcome.success);

      // Assert
      final state = container.read(logFilterProvider);
      expect(state.selectedOutcomes, contains(LogOutcome.success));
    });

    test('toggleOutcome should remove outcome if already selected', () {
      // Arrange
      notifier.toggleOutcome(LogOutcome.success);
      expect(
        container.read(logFilterProvider).selectedOutcomes,
        contains(LogOutcome.success),
      );

      // Act
      notifier.toggleOutcome(LogOutcome.success);

      // Assert
      final state = container.read(logFilterProvider);
      expect(state.selectedOutcomes, isNot(contains(LogOutcome.success)));
    });

    test('toggleOutcome should support multiple outcomes', () {
      // Act
      notifier.toggleOutcome(LogOutcome.success);
      notifier.toggleOutcome(LogOutcome.partial);

      // Assert
      final state = container.read(logFilterProvider);
      expect(state.selectedOutcomes, containsAll([LogOutcome.success, LogOutcome.partial]));
    });

    test('setOutcome should set single outcome exclusively', () {
      // Arrange
      notifier.toggleOutcome(LogOutcome.success);
      notifier.toggleOutcome(LogOutcome.partial);

      // Act
      notifier.setOutcome(LogOutcome.failed);

      // Assert
      final state = container.read(logFilterProvider);
      expect(state.selectedOutcomes, {LogOutcome.failed});
    });

    test('setOutcome with null should clear all outcomes', () {
      // Arrange
      notifier.toggleOutcome(LogOutcome.success);
      notifier.toggleOutcome(LogOutcome.partial);

      // Act
      notifier.setOutcome(null);

      // Assert
      final state = container.read(logFilterProvider);
      expect(state.selectedOutcomes, isEmpty);
    });

    test('setTimeFilter should update time filter', () {
      // Act
      notifier.setTimeFilter(LogTimeFilter.thisMonth);

      // Assert
      final state = container.read(logFilterProvider);
      expect(state.timeFilter, LogTimeFilter.thisMonth);
    });

    test('setSortOption should update sort option', () {
      // Act
      notifier.setSortOption(LogSortOption.oldest);

      // Assert
      final state = container.read(logFilterProvider);
      expect(state.sortOption, LogSortOption.oldest);
    });

    test('togglePhotosOnly should toggle showOnlyWithPhotos', () {
      // Act
      notifier.togglePhotosOnly();

      // Assert
      expect(container.read(logFilterProvider).showOnlyWithPhotos, isTrue);

      // Act again
      notifier.togglePhotosOnly();

      // Assert
      expect(container.read(logFilterProvider).showOnlyWithPhotos, isFalse);
    });

    test('clearAllFilters should reset all filters', () {
      // Arrange
      notifier.toggleOutcome(LogOutcome.success);
      notifier.setTimeFilter(LogTimeFilter.thisWeek);
      notifier.setSortOption(LogSortOption.oldest);
      notifier.togglePhotosOnly();

      // Act
      notifier.clearAllFilters();

      // Assert
      final state = container.read(logFilterProvider);
      expect(state.selectedOutcomes, isEmpty);
      expect(state.timeFilter, LogTimeFilter.all);
      expect(state.sortOption, LogSortOption.recent);
      expect(state.showOnlyWithPhotos, isFalse);
    });

    test('clearOutcomeFilters should only clear outcomes', () {
      // Arrange
      notifier.toggleOutcome(LogOutcome.success);
      notifier.toggleOutcome(LogOutcome.partial);
      notifier.setTimeFilter(LogTimeFilter.thisWeek);
      notifier.togglePhotosOnly();

      // Act
      notifier.clearOutcomeFilters();

      // Assert
      final state = container.read(logFilterProvider);
      expect(state.selectedOutcomes, isEmpty);
      expect(state.timeFilter, LogTimeFilter.thisWeek); // preserved
      expect(state.showOnlyWithPhotos, isTrue); // preserved
    });

    test('setLearningFilter should set partial and failed outcomes', () {
      // Act
      notifier.setLearningFilter();

      // Assert
      final state = container.read(logFilterProvider);
      expect(
        state.selectedOutcomes,
        containsAll([LogOutcome.partial, LogOutcome.failed]),
      );
      expect(state.selectedOutcomes, isNot(contains(LogOutcome.success)));
    });
  });

  group('LogPostSummary', () {
    test('should create summary with all fields', () {
      // Arrange & Act
      final now = DateTime.now();
      final summary = LogPostSummary(
        id: 'log-123',
        title: 'My Cooking Log',
        outcome: 'SUCCESS',
        thumbnailUrl: 'https://example.com/thumb.jpg',
        creatorName: 'chef_user',
        createdAt: now,
      );

      // Assert
      expect(summary.id, 'log-123');
      expect(summary.title, 'My Cooking Log');
      expect(summary.outcome, 'SUCCESS');
      expect(summary.thumbnailUrl, 'https://example.com/thumb.jpg');
      expect(summary.creatorName, 'chef_user');
      expect(summary.createdAt, now);
    });

    test('should handle null thumbnailUrl', () {
      // Arrange & Act
      final summary = LogPostSummary(
        id: 'log-456',
        title: 'No Photo Log',
        outcome: 'PARTIAL',
        thumbnailUrl: null,
        creatorName: 'user',
      );

      // Assert
      expect(summary.thumbnailUrl, isNull);
    });

    test('should handle null creatorName', () {
      // Arrange & Act
      final summary = LogPostSummary(
        id: 'log-789',
        title: 'Anonymous Log',
        outcome: 'FAILED',
        thumbnailUrl: null,
        creatorName: null,
      );

      // Assert
      expect(summary.creatorName, isNull);
    });

    test('should support all outcome types', () {
      // Arrange & Act & Assert
      expect(
        LogPostSummary(
          id: '1',
          title: 'Success',
          outcome: 'SUCCESS',
          thumbnailUrl: null,
          creatorName: null,
        ).outcome,
        'SUCCESS',
      );

      expect(
        LogPostSummary(
          id: '2',
          title: 'Partial',
          outcome: 'PARTIAL',
          thumbnailUrl: null,
          creatorName: null,
        ).outcome,
        'PARTIAL',
      );

      expect(
        LogPostSummary(
          id: '3',
          title: 'Failed',
          outcome: 'FAILED',
          thumbnailUrl: null,
          creatorName: null,
        ).outcome,
        'FAILED',
      );
    });

    test('should handle optional createdAt', () {
      // Arrange & Act
      final withDate = LogPostSummary(
        id: 'log-1',
        title: 'With Date',
        outcome: 'SUCCESS',
        thumbnailUrl: null,
        creatorName: 'user',
        createdAt: DateTime(2024, 6, 15),
      );

      final withoutDate = LogPostSummary(
        id: 'log-2',
        title: 'Without Date',
        outcome: 'SUCCESS',
        thumbnailUrl: null,
        creatorName: 'user',
      );

      // Assert
      expect(withDate.createdAt, isNotNull);
      expect(withDate.createdAt, DateTime(2024, 6, 15));
      expect(withoutDate.createdAt, isNull);
    });
  });

  group('LogOutcome', () {
    test('should have correct values', () {
      expect(LogOutcome.success.value, 'SUCCESS');
      expect(LogOutcome.partial.value, 'PARTIAL');
      expect(LogOutcome.failed.value, 'FAILED');
    });

    test('fromString should return correct outcome', () {
      expect(LogOutcome.fromString('SUCCESS'), LogOutcome.success);
      expect(LogOutcome.fromString('PARTIAL'), LogOutcome.partial);
      expect(LogOutcome.fromString('FAILED'), LogOutcome.failed);
    });

    test('fromString should return null for unknown value', () {
      expect(LogOutcome.fromString('UNKNOWN'), isNull);
      expect(LogOutcome.fromString(null), isNull);
    });

    test('should have colors defined', () {
      expect(LogOutcome.success.primaryColor, isNotNull);
      expect(LogOutcome.success.backgroundColor, isNotNull);
      expect(LogOutcome.partial.primaryColor, isNotNull);
      expect(LogOutcome.partial.backgroundColor, isNotNull);
      expect(LogOutcome.failed.primaryColor, isNotNull);
      expect(LogOutcome.failed.backgroundColor, isNotNull);
    });
  });

  group('Time Filter Enums', () {
    test('LogTimeFilter should have all expected values', () {
      expect(LogTimeFilter.values, containsAll([
        LogTimeFilter.all,
        LogTimeFilter.today,
        LogTimeFilter.thisWeek,
        LogTimeFilter.thisMonth,
      ]));
    });

    test('LogSortOption should have all expected values', () {
      expect(LogSortOption.values, containsAll([
        LogSortOption.recent,
        LogSortOption.oldest,
        LogSortOption.outcomeSuccess,
        LogSortOption.outcomeFailed,
      ]));
    });
  });
}
