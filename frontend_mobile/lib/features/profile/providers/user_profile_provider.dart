import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pairing_planet2_frontend/data/datasources/user/user_remote_data_source.dart';
import 'package:pairing_planet2_frontend/data/models/log_post/log_post_summary_dto.dart';
import 'package:pairing_planet2_frontend/data/models/recipe/recipe_summary_dto.dart';
import 'package:pairing_planet2_frontend/data/models/user/user_dto.dart';
import 'package:pairing_planet2_frontend/features/profile/providers/profile_provider.dart'
    show userRemoteDataSourceProvider;
import 'package:pairing_planet2_frontend/features/recipe/providers/browse_filter_provider.dart'
    show RecipeTypeFilter;

/// Other user's profile provider (parameterized by userId)
final userProfileProvider =
    FutureProvider.autoDispose.family<UserDto, String>((ref, userId) async {
  final dataSource = ref.read(userRemoteDataSourceProvider);
  return dataSource.getUserProfile(userId);
});

/// Paginated state for other user's recipes
class UserRecipesState {
  final List<RecipeSummaryDto> items;
  final bool hasNext;
  final int currentPage;
  final bool isLoading;
  final String? error;

  const UserRecipesState({
    this.items = const [],
    this.hasNext = true,
    this.currentPage = 0,
    this.isLoading = false,
    this.error,
  });

  UserRecipesState copyWith({
    List<RecipeSummaryDto>? items,
    bool? hasNext,
    int? currentPage,
    bool? isLoading,
    String? error,
  }) {
    return UserRecipesState(
      items: items ?? this.items,
      hasNext: hasNext ?? this.hasNext,
      currentPage: currentPage ?? this.currentPage,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for other user's recipes
class UserRecipesNotifier extends StateNotifier<UserRecipesState> {
  final UserRemoteDataSource _dataSource;
  final String _userId;
  RecipeTypeFilter _currentFilter = RecipeTypeFilter.all;
  bool _isRefreshing = false;

  UserRecipesNotifier({
    required UserRemoteDataSource dataSource,
    required String userId,
  })  : _dataSource = dataSource,
        _userId = userId,
        super(const UserRecipesState(isLoading: true)) {
    _fetchFromNetwork();
  }

  RecipeTypeFilter get currentFilter => _currentFilter;

  String? get _typeFilterParam => switch (_currentFilter) {
        RecipeTypeFilter.all => null,
        RecipeTypeFilter.originals => 'original',
        RecipeTypeFilter.variants => 'variants',
      };

  Future<void> setFilter(RecipeTypeFilter filter) async {
    if (_currentFilter == filter) return;
    _currentFilter = filter;
    state = const UserRecipesState(isLoading: true);
    await _fetchFromNetwork();
  }

  Future<void> _fetchFromNetwork() async {
    try {
      final response = await _dataSource.getUserRecipes(
        userId: _userId,
        page: 0,
        typeFilter: _typeFilterParam,
      );

      state = UserRecipesState(
        items: response.content,
        hasNext: response.hasNext ?? false,
        currentPage: 0,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load recipes',
      );
    }
  }

  Future<void> fetchNextPage() async {
    if (!state.hasNext || state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _dataSource.getUserRecipes(
        userId: _userId,
        page: state.currentPage + 1,
        typeFilter: _typeFilterParam,
      );
      state = state.copyWith(
        items: [...state.items, ...response.content],
        hasNext: response.hasNext ?? false,
        currentPage: state.currentPage + 1,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> refresh() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _fetchFromNetwork();
    } finally {
      _isRefreshing = false;
    }
  }
}

/// Provider for other user's recipes (parameterized by userId)
final userRecipesProvider = StateNotifierProvider.autoDispose
    .family<UserRecipesNotifier, UserRecipesState, String>((ref, userId) {
  return UserRecipesNotifier(
    dataSource: ref.read(userRemoteDataSourceProvider),
    userId: userId,
  );
});

/// Paginated state for other user's logs
class UserLogsState {
  final List<LogPostSummaryDto> items;
  final bool hasNext;
  final int currentPage;
  final bool isLoading;
  final String? error;

  const UserLogsState({
    this.items = const [],
    this.hasNext = true,
    this.currentPage = 0,
    this.isLoading = false,
    this.error,
  });

  UserLogsState copyWith({
    List<LogPostSummaryDto>? items,
    bool? hasNext,
    int? currentPage,
    bool? isLoading,
    String? error,
  }) {
    return UserLogsState(
      items: items ?? this.items,
      hasNext: hasNext ?? this.hasNext,
      currentPage: currentPage ?? this.currentPage,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for other user's logs
class UserLogsNotifier extends StateNotifier<UserLogsState> {
  final UserRemoteDataSource _dataSource;
  final String _userId;
  bool _isRefreshing = false;

  UserLogsNotifier({
    required UserRemoteDataSource dataSource,
    required String userId,
  })  : _dataSource = dataSource,
        _userId = userId,
        super(const UserLogsState(isLoading: true)) {
    _fetchFromNetwork();
  }

  Future<void> _fetchFromNetwork() async {
    try {
      final response = await _dataSource.getUserLogs(
        userId: _userId,
        page: 0,
      );

      state = UserLogsState(
        items: response.content,
        hasNext: response.hasNext ?? false,
        currentPage: 0,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load logs',
      );
    }
  }

  Future<void> fetchNextPage() async {
    if (!state.hasNext || state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _dataSource.getUserLogs(
        userId: _userId,
        page: state.currentPage + 1,
      );
      state = state.copyWith(
        items: [...state.items, ...response.content],
        hasNext: response.hasNext ?? false,
        currentPage: state.currentPage + 1,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> refresh() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _fetchFromNetwork();
    } finally {
      _isRefreshing = false;
    }
  }
}

/// Provider for other user's logs (parameterized by userId)
final userLogsProvider = StateNotifierProvider.autoDispose
    .family<UserLogsNotifier, UserLogsState, String>((ref, userId) {
  return UserLogsNotifier(
    dataSource: ref.read(userRemoteDataSourceProvider),
    userId: userId,
  );
});
