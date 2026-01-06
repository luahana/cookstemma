import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pairing_planet2_frontend/features/recipe/providers/recipe_providers.dart';
import '../../../domain/entities/recipe/recipe_summary.dart';

/// State class for recipe list with pagination and cache info.
class RecipeListState {
  final List<RecipeSummary> items;
  final bool hasNext;
  final bool isFromCache;
  final DateTime? cachedAt;

  RecipeListState({
    required this.items,
    required this.hasNext,
    this.isFromCache = false,
    this.cachedAt,
  });

  RecipeListState copyWith({
    List<RecipeSummary>? items,
    bool? hasNext,
    bool? isFromCache,
    DateTime? cachedAt,
  }) {
    return RecipeListState(
      items: items ?? this.items,
      hasNext: hasNext ?? this.hasNext,
      isFromCache: isFromCache ?? this.isFromCache,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }
}

class RecipeListNotifier extends AsyncNotifier<RecipeListState> {
  int _currentPage = 0;
  bool _hasNext = true;
  bool _isFetchingNext = false;
  bool _isFromCache = false;
  DateTime? _cachedAt;

  @override
  Future<RecipeListState> build() async {
    // 초기화 로직
    _currentPage = 0;
    _hasNext = true;
    _isFetchingNext = false;
    _isFromCache = false;
    _cachedAt = null;

    final items = await _fetchRecipes(page: _currentPage);
    // 초기 상태에 현재 리스트와 hasNext, 캐시 정보를 함께 담아 반환합니다.
    return RecipeListState(
      items: items,
      hasNext: _hasNext,
      isFromCache: _isFromCache,
      cachedAt: _cachedAt,
    );
  }

  Future<List<RecipeSummary>> _fetchRecipes({required int page}) async {
    final repository = ref.read(recipeRepositoryProvider);
    final result = await repository.getRecipes(page: page, size: 10);

    return result.fold((failure) => throw failure, (sliceResponse) {
      _hasNext = sliceResponse.hasNext;
      // Track cache status for first page
      if (page == 0) {
        _isFromCache = sliceResponse.isFromCache;
        _cachedAt = sliceResponse.cachedAt;
      }
      return sliceResponse.content;
    });
  }

  /// 다음 페이지 로드
  Future<void> fetchNextPage() async {
    // 💡 이미 데이터를 가져오는 중이거나 다음 페이지가 없으면 중단합니다.
    if (_isFetchingNext || !_hasNext) return;

    _isFetchingNext = true;
    final nextPage = _currentPage + 1;

    final result = await ref
        .read(recipeRepositoryProvider)
        .getRecipes(page: nextPage, size: 10);

    result.fold(
      (failure) {
        _isFetchingNext = false;
      },
      (sliceResponse) {
        _currentPage = nextPage;
        _hasNext = sliceResponse.hasNext;
        _isFetchingNext = false;

        // 💡 기존 리스트에 새 데이터를 붙이고, 최신 hasNext 상태를 업데이트합니다.
        final previousState = state.value;
        final previousItems = previousState?.items ?? [];

        state = AsyncValue.data(
          RecipeListState(
            items: [...previousItems, ...sliceResponse.content],
            hasNext: _hasNext,
          ),
        );
      },
    );
  }
}

final recipeListProvider =
    AsyncNotifierProvider<RecipeListNotifier, RecipeListState>(
      RecipeListNotifier.new,
    );
