import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_summary.dart';
import 'package:pairing_planet2_frontend/features/recipe/providers/browse_filter_provider.dart';
import 'package:pairing_planet2_frontend/features/recipe/providers/recipe_list_provider.dart';

void main() {
  group('RecipeListState', () {
    test('should create state with required fields', () {
      // Arrange & Act
      final state = RecipeListState(
        items: [],
        hasNext: true,
      );

      // Assert
      expect(state.items, isEmpty);
      expect(state.hasNext, isTrue);
      expect(state.isFromCache, isFalse);
      expect(state.cachedAt, isNull);
      expect(state.searchQuery, isNull);
      expect(state.filterState, isNull);
    });

    test('should create state with all fields', () {
      // Arrange
      final recipes = [
        RecipeSummary(
          publicId: 'recipe-1',
          foodName: 'Kimchi Fried Rice',
          title: 'Test Recipe',
          description: 'A test recipe',
          culinaryLocale: 'ko-KR',
          thumbnailUrl: 'https://example.com/thumb.jpg',
          creatorName: 'chef1',
          variantCount: 5,
          logCount: 10,
        ),
      ];
      final filterState = const BrowseFilterState(
        viewMode: BrowseViewMode.grid,
        typeFilter: RecipeTypeFilter.originals,
      );
      final cachedTime = DateTime.now();

      // Act
      final state = RecipeListState(
        items: recipes,
        hasNext: false,
        isFromCache: true,
        cachedAt: cachedTime,
        searchQuery: 'kimchi',
        filterState: filterState,
      );

      // Assert
      expect(state.items, hasLength(1));
      expect(state.hasNext, isFalse);
      expect(state.isFromCache, isTrue);
      expect(state.cachedAt, cachedTime);
      expect(state.searchQuery, 'kimchi');
      expect(state.filterState, filterState);
    });

    test('copyWith should update only specified fields', () {
      // Arrange
      final recipes = [
        RecipeSummary(
          publicId: 'recipe-1',
          foodName: 'Test Food',
          title: 'Test Recipe',
          description: 'Description',
          culinaryLocale: 'en-US',
          thumbnailUrl: null,
          creatorName: 'user1',
          variantCount: 0,
          logCount: 0,
        ),
      ];
      final originalState = RecipeListState(
        items: recipes,
        hasNext: true,
        isFromCache: true,
        searchQuery: 'original',
      );

      // Act
      final updatedState = originalState.copyWith(
        hasNext: false,
        searchQuery: 'updated',
      );

      // Assert
      expect(updatedState.items, originalState.items);
      expect(updatedState.hasNext, isFalse);
      expect(updatedState.isFromCache, isTrue);
      expect(updatedState.searchQuery, 'updated');
    });

    test('copyWith with clearSearchQuery should set searchQuery to null', () {
      // Arrange
      final state = RecipeListState(
        items: [],
        hasNext: true,
        searchQuery: 'something',
      );

      // Act
      final clearedState = state.copyWith(clearSearchQuery: true);

      // Assert
      expect(clearedState.searchQuery, isNull);
    });

    test('should store multiple items', () {
      // Arrange
      final recipes = List.generate(
        20,
        (i) => RecipeSummary(
          publicId: 'recipe-$i',
          foodName: 'Food $i',
          title: 'Recipe $i',
          description: 'Description $i',
          culinaryLocale: 'en-US',
          thumbnailUrl: null,
          creatorName: 'user$i',
          variantCount: i,
          logCount: i * 2,
        ),
      );

      // Act
      final state = RecipeListState(
        items: recipes,
        hasNext: true,
      );

      // Assert
      expect(state.items, hasLength(20));
      expect(state.items[0].publicId, 'recipe-0');
      expect(state.items[19].publicId, 'recipe-19');
    });
  });

  group('BrowseFilterState', () {
    test('should have correct default values', () {
      // Arrange & Act
      const state = BrowseFilterState();

      // Assert
      expect(state.viewMode, BrowseViewMode.list);
      expect(state.cuisineFilter, isNull);
      expect(state.typeFilter, RecipeTypeFilter.all);
      expect(state.sortOption, RecipeSortOption.recent);
    });

    test('hasActiveFilters should return false for default state', () {
      // Arrange
      const state = BrowseFilterState();

      // Assert
      expect(state.hasActiveFilters, isFalse);
    });

    test('hasActiveFilters should return true when cuisine filter is set', () {
      // Arrange
      const state = BrowseFilterState(cuisineFilter: 'ko-KR');

      // Assert
      expect(state.hasActiveFilters, isTrue);
    });

    test('hasActiveFilters should return true when type filter is not all', () {
      // Arrange
      const state = BrowseFilterState(typeFilter: RecipeTypeFilter.originals);

      // Assert
      expect(state.hasActiveFilters, isTrue);
    });

    test('hasActiveFilters should return true when sort option is not recent', () {
      // Arrange
      const state = BrowseFilterState(sortOption: RecipeSortOption.trending);

      // Assert
      expect(state.hasActiveFilters, isTrue);
    });

    test('activeFilterCount should return correct count', () {
      // Arrange
      const noFilters = BrowseFilterState();
      const oneFilter = BrowseFilterState(cuisineFilter: 'ko-KR');
      const twoFilters = BrowseFilterState(
        cuisineFilter: 'ko-KR',
        typeFilter: RecipeTypeFilter.variants,
      );
      const threeFilters = BrowseFilterState(
        cuisineFilter: 'en-US',
        typeFilter: RecipeTypeFilter.originals,
        sortOption: RecipeSortOption.mostForked,
      );

      // Assert
      expect(noFilters.activeFilterCount, 0);
      expect(oneFilter.activeFilterCount, 1);
      expect(twoFilters.activeFilterCount, 2);
      expect(threeFilters.activeFilterCount, 3);
    });

    test('copyWith should update only specified fields', () {
      // Arrange
      const original = BrowseFilterState(
        viewMode: BrowseViewMode.list,
        cuisineFilter: 'ko-KR',
        typeFilter: RecipeTypeFilter.originals,
        sortOption: RecipeSortOption.recent,
      );

      // Act
      final updated = original.copyWith(
        viewMode: BrowseViewMode.grid,
        sortOption: RecipeSortOption.trending,
      );

      // Assert
      expect(updated.viewMode, BrowseViewMode.grid);
      expect(updated.cuisineFilter, 'ko-KR'); // unchanged
      expect(updated.typeFilter, RecipeTypeFilter.originals); // unchanged
      expect(updated.sortOption, RecipeSortOption.trending);
    });

    test('copyWith with clearCuisineFilter should set cuisineFilter to null', () {
      // Arrange
      const state = BrowseFilterState(cuisineFilter: 'ko-KR');

      // Act
      final clearedState = state.copyWith(clearCuisineFilter: true);

      // Assert
      expect(clearedState.cuisineFilter, isNull);
    });

    test('equality should work correctly', () {
      // Arrange
      const state1 = BrowseFilterState(
        viewMode: BrowseViewMode.grid,
        cuisineFilter: 'ko-KR',
      );
      const state2 = BrowseFilterState(
        viewMode: BrowseViewMode.grid,
        cuisineFilter: 'ko-KR',
      );
      const state3 = BrowseFilterState(
        viewMode: BrowseViewMode.list,
        cuisineFilter: 'ko-KR',
      );

      // Assert
      expect(state1, equals(state2));
      expect(state1, isNot(equals(state3)));
    });
  });

  group('BrowseFilterNotifier', () {
    late ProviderContainer container;
    late BrowseFilterNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(browseFilterProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('should have default state on build', () {
      // Assert
      final state = container.read(browseFilterProvider);
      expect(state.viewMode, BrowseViewMode.list);
      expect(state.cuisineFilter, isNull);
      expect(state.typeFilter, RecipeTypeFilter.all);
      expect(state.sortOption, RecipeSortOption.recent);
    });

    test('setViewMode should update view mode', () {
      // Act
      notifier.setViewMode(BrowseViewMode.grid);

      // Assert
      final state = container.read(browseFilterProvider);
      expect(state.viewMode, BrowseViewMode.grid);
    });

    test('setCuisineFilter should update cuisine filter', () {
      // Act
      notifier.setCuisineFilter('ja-JP');

      // Assert
      final state = container.read(browseFilterProvider);
      expect(state.cuisineFilter, 'ja-JP');
    });

    test('setCuisineFilter with null should clear cuisine filter', () {
      // Arrange
      notifier.setCuisineFilter('ko-KR');
      expect(container.read(browseFilterProvider).cuisineFilter, 'ko-KR');

      // Act
      notifier.setCuisineFilter(null);

      // Assert
      final state = container.read(browseFilterProvider);
      expect(state.cuisineFilter, isNull);
    });

    test('setTypeFilter should update type filter', () {
      // Act
      notifier.setTypeFilter(RecipeTypeFilter.variants);

      // Assert
      final state = container.read(browseFilterProvider);
      expect(state.typeFilter, RecipeTypeFilter.variants);
    });

    test('setSortOption should update sort option', () {
      // Act
      notifier.setSortOption(RecipeSortOption.mostForked);

      // Assert
      final state = container.read(browseFilterProvider);
      expect(state.sortOption, RecipeSortOption.mostForked);
    });

    test('clearAllFilters should reset filters but keep view mode', () {
      // Arrange
      notifier.setViewMode(BrowseViewMode.grid);
      notifier.setCuisineFilter('ko-KR');
      notifier.setTypeFilter(RecipeTypeFilter.originals);
      notifier.setSortOption(RecipeSortOption.trending);

      // Act
      notifier.clearAllFilters();

      // Assert
      final state = container.read(browseFilterProvider);
      expect(state.viewMode, BrowseViewMode.grid); // preserved
      expect(state.cuisineFilter, isNull);
      expect(state.typeFilter, RecipeTypeFilter.all);
      expect(state.sortOption, RecipeSortOption.recent);
    });

    test('resetToDefaults should reset everything including view mode', () {
      // Arrange
      notifier.setViewMode(BrowseViewMode.grid);
      notifier.setCuisineFilter('ko-KR');
      notifier.setTypeFilter(RecipeTypeFilter.originals);
      notifier.setSortOption(RecipeSortOption.trending);

      // Act
      notifier.resetToDefaults();

      // Assert
      final state = container.read(browseFilterProvider);
      expect(state.viewMode, BrowseViewMode.list);
      expect(state.cuisineFilter, isNull);
      expect(state.typeFilter, RecipeTypeFilter.all);
      expect(state.sortOption, RecipeSortOption.recent);
    });
  });

  group('RecipeSummary', () {
    test('should create summary with all fields', () {
      // Arrange & Act
      final summary = RecipeSummary(
        publicId: 'recipe-123',
        foodName: 'Kimchi Fried Rice',
        title: 'Mom\'s Special Recipe',
        description: 'A delicious family recipe',
        culinaryLocale: 'ko-KR',
        thumbnailUrl: 'https://example.com/thumb.jpg',
        creatorName: 'chef_kim',
        variantCount: 15,
        logCount: 42,
      );

      // Assert
      expect(summary.publicId, 'recipe-123');
      expect(summary.foodName, 'Kimchi Fried Rice');
      expect(summary.title, 'Mom\'s Special Recipe');
      expect(summary.description, 'A delicious family recipe');
      expect(summary.culinaryLocale, 'ko-KR');
      expect(summary.thumbnailUrl, 'https://example.com/thumb.jpg');
      expect(summary.creatorName, 'chef_kim');
      expect(summary.variantCount, 15);
      expect(summary.logCount, 42);
    });

    test('should handle null thumbnailUrl', () {
      // Arrange & Act
      final summary = RecipeSummary(
        publicId: 'recipe-456',
        foodName: 'Test Food',
        title: 'No Photo Recipe',
        description: 'Description',
        culinaryLocale: 'en-US',
        thumbnailUrl: null,
        creatorName: 'user',
        variantCount: 0,
        logCount: 0,
      );

      // Assert
      expect(summary.thumbnailUrl, isNull);
    });

    test('should support variant recipes with parentPublicId', () {
      // Arrange & Act
      final variant = RecipeSummary(
        publicId: 'recipe-variant',
        foodName: 'Spicy Kimchi Rice',
        title: 'My Spicy Version',
        description: 'A spicier variant',
        culinaryLocale: 'ko-KR',
        thumbnailUrl: null,
        creatorName: 'chef2',
        variantCount: 0,
        logCount: 0,
        parentPublicId: 'recipe-original',
        rootPublicId: 'recipe-original',
        rootTitle: 'Original Kimchi Fried Rice',
      );

      // Assert
      expect(variant.isVariant, isTrue);
      expect(variant.parentPublicId, 'recipe-original');
      expect(variant.rootPublicId, 'recipe-original');
      expect(variant.rootTitle, 'Original Kimchi Fried Rice');
    });

    test('original recipe should have isVariant false', () {
      // Arrange & Act
      final original = RecipeSummary(
        publicId: 'recipe-original',
        foodName: 'Kimchi Fried Rice',
        title: 'Original Recipe',
        description: 'The original version',
        culinaryLocale: 'ko-KR',
        thumbnailUrl: null,
        creatorName: 'chef1',
        variantCount: 5,
        logCount: 10,
      );

      // Assert
      expect(original.isVariant, isFalse);
      expect(original.parentPublicId, isNull);
      expect(original.rootPublicId, isNull);
    });

    test('should store variant and log counts', () {
      // Arrange & Act
      final popularRecipe = RecipeSummary(
        publicId: 'recipe-popular',
        foodName: 'Popular Food',
        title: 'Trending Recipe',
        description: 'Very popular',
        culinaryLocale: 'en-US',
        thumbnailUrl: null,
        creatorName: 'famous_chef',
        variantCount: 100,
        logCount: 500,
      );

      // Assert
      expect(popularRecipe.variantCount, 100);
      expect(popularRecipe.logCount, 500);
    });
  });
}
