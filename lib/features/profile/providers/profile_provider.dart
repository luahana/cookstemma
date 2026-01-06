import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pairing_planet2_frontend/core/network/dio_provider.dart';
import 'package:pairing_planet2_frontend/data/datasources/user/user_remote_data_source.dart';
import 'package:pairing_planet2_frontend/data/models/log_post/log_post_summary_dto.dart';
import 'package:pairing_planet2_frontend/data/models/recipe/recipe_summary_dto.dart';
import 'package:pairing_planet2_frontend/data/models/user/my_profile_response_dto.dart';

/// 내 프로필 Provider
final myProfileProvider = FutureProvider.autoDispose<MyProfileResponseDto>((ref) async {
  final dataSource = UserRemoteDataSource(ref.read(dioProvider));
  return dataSource.getMyProfile();
});

/// 내 레시피 페이지네이션 상태
class MyRecipesState {
  final List<RecipeSummaryDto> items;
  final bool hasNext;
  final int currentPage;
  final bool isLoading;

  MyRecipesState({
    this.items = const [],
    this.hasNext = true,
    this.currentPage = 0,
    this.isLoading = false,
  });

  MyRecipesState copyWith({
    List<RecipeSummaryDto>? items,
    bool? hasNext,
    int? currentPage,
    bool? isLoading,
  }) {
    return MyRecipesState(
      items: items ?? this.items,
      hasNext: hasNext ?? this.hasNext,
      currentPage: currentPage ?? this.currentPage,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// 내 레시피 목록 Notifier
class MyRecipesNotifier extends StateNotifier<AsyncValue<MyRecipesState>> {
  final UserRemoteDataSource _dataSource;

  MyRecipesNotifier(this._dataSource) : super(const AsyncValue.loading()) {
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    try {
      final response = await _dataSource.getMyRecipes(page: 0);
      state = AsyncValue.data(MyRecipesState(
        items: response.content,
        hasNext: response.hasNext ?? false,
        currentPage: 0,
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> fetchNextPage() async {
    final currentState = state.valueOrNull;
    if (currentState == null || !currentState.hasNext || currentState.isLoading) return;

    state = AsyncValue.data(currentState.copyWith(isLoading: true));

    try {
      final response = await _dataSource.getMyRecipes(page: currentState.currentPage + 1);
      state = AsyncValue.data(currentState.copyWith(
        items: [...currentState.items, ...response.content],
        hasNext: response.hasNext ?? false,
        currentPage: currentState.currentPage + 1,
        isLoading: false,
      ));
    } catch (e) {
      state = AsyncValue.data(currentState.copyWith(isLoading: false));
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _loadInitial();
  }
}

final myRecipesProvider = StateNotifierProvider.autoDispose<MyRecipesNotifier, AsyncValue<MyRecipesState>>((ref) {
  final dataSource = UserRemoteDataSource(ref.read(dioProvider));
  return MyRecipesNotifier(dataSource);
});

/// 내 로그 페이지네이션 상태
class MyLogsState {
  final List<LogPostSummaryDto> items;
  final bool hasNext;
  final int currentPage;
  final bool isLoading;

  MyLogsState({
    this.items = const [],
    this.hasNext = true,
    this.currentPage = 0,
    this.isLoading = false,
  });

  MyLogsState copyWith({
    List<LogPostSummaryDto>? items,
    bool? hasNext,
    int? currentPage,
    bool? isLoading,
  }) {
    return MyLogsState(
      items: items ?? this.items,
      hasNext: hasNext ?? this.hasNext,
      currentPage: currentPage ?? this.currentPage,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// 내 로그 목록 Notifier
class MyLogsNotifier extends StateNotifier<AsyncValue<MyLogsState>> {
  final UserRemoteDataSource _dataSource;

  MyLogsNotifier(this._dataSource) : super(const AsyncValue.loading()) {
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    try {
      final response = await _dataSource.getMyLogs(page: 0);
      state = AsyncValue.data(MyLogsState(
        items: response.content,
        hasNext: response.hasNext ?? false,
        currentPage: 0,
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> fetchNextPage() async {
    final currentState = state.valueOrNull;
    if (currentState == null || !currentState.hasNext || currentState.isLoading) return;

    state = AsyncValue.data(currentState.copyWith(isLoading: true));

    try {
      final response = await _dataSource.getMyLogs(page: currentState.currentPage + 1);
      state = AsyncValue.data(currentState.copyWith(
        items: [...currentState.items, ...response.content],
        hasNext: response.hasNext ?? false,
        currentPage: currentState.currentPage + 1,
        isLoading: false,
      ));
    } catch (e) {
      state = AsyncValue.data(currentState.copyWith(isLoading: false));
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _loadInitial();
  }
}

final myLogsProvider = StateNotifierProvider.autoDispose<MyLogsNotifier, AsyncValue<MyLogsState>>((ref) {
  final dataSource = UserRemoteDataSource(ref.read(dioProvider));
  return MyLogsNotifier(dataSource);
});

/// 저장한 레시피 페이지네이션 상태
class SavedRecipesState {
  final List<RecipeSummaryDto> items;
  final bool hasNext;
  final int currentPage;
  final bool isLoading;

  SavedRecipesState({
    this.items = const [],
    this.hasNext = true,
    this.currentPage = 0,
    this.isLoading = false,
  });

  SavedRecipesState copyWith({
    List<RecipeSummaryDto>? items,
    bool? hasNext,
    int? currentPage,
    bool? isLoading,
  }) {
    return SavedRecipesState(
      items: items ?? this.items,
      hasNext: hasNext ?? this.hasNext,
      currentPage: currentPage ?? this.currentPage,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// 저장한 레시피 목록 Notifier
class SavedRecipesNotifier extends StateNotifier<AsyncValue<SavedRecipesState>> {
  final UserRemoteDataSource _dataSource;

  SavedRecipesNotifier(this._dataSource) : super(const AsyncValue.loading()) {
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    try {
      final response = await _dataSource.getSavedRecipes(page: 0);
      state = AsyncValue.data(SavedRecipesState(
        items: response.content,
        hasNext: response.hasNext ?? false,
        currentPage: 0,
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> fetchNextPage() async {
    final currentState = state.valueOrNull;
    if (currentState == null || !currentState.hasNext || currentState.isLoading) return;

    state = AsyncValue.data(currentState.copyWith(isLoading: true));

    try {
      final response = await _dataSource.getSavedRecipes(page: currentState.currentPage + 1);
      state = AsyncValue.data(currentState.copyWith(
        items: [...currentState.items, ...response.content],
        hasNext: response.hasNext ?? false,
        currentPage: currentState.currentPage + 1,
        isLoading: false,
      ));
    } catch (e) {
      state = AsyncValue.data(currentState.copyWith(isLoading: false));
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _loadInitial();
  }
}

final savedRecipesProvider = StateNotifierProvider.autoDispose<SavedRecipesNotifier, AsyncValue<SavedRecipesState>>((ref) {
  final dataSource = UserRemoteDataSource(ref.read(dioProvider));
  return SavedRecipesNotifier(dataSource);
});
