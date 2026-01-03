import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/recipe/recipe_summary.dart';

class RecipeListNotifier extends AsyncNotifier<List<RecipeSummary>> {
  int _currentPage = 1;
  bool _hasNext = true;

  @override
  Future<List<RecipeSummary>> build() async {
    return _fetchRecipes();
  }

  Future<List<RecipeSummary>> _fetchRecipes() async {
    final repository = ref.read(recipeRepositoryProvider);
    final result = await repository.getRecipes(page: _currentPage);

    return result.fold((failure) => throw failure.message, (pagedData) {
      _hasNext = pagedData.hasNext;
      return pagedData.items;
    });
  }

  /// 다음 페이지 로드 (UI에서 스크롤이 끝에 닿았을 때 호출)
  Future<void> fetchNextPage() async {
    if (state.isLoading || !_hasNext) return;

    state = const AsyncLoading<List<RecipeSummary>>().copyWithPrevious(state);

    final repository = ref.read(recipeRepositoryProvider);
    _currentPage++;

    final result = await repository.getRecipes(page: _currentPage);

    result.fold(
      (failure) {
        _currentPage--; // 실패 시 페이지 번호 롤백
        state = AsyncError(failure.message, StackTrace.current);
      },
      (pagedData) {
        _hasNext = pagedData.hasNext;
        // 기존 리스트에 새로운 아이템 추가
        final currentItems = state.value ?? [];
        state = AsyncData([...currentItems, ...pagedData.items]);
      },
    );
  }
}

final recipeListProvider =
    AsyncNotifierProvider<RecipeListNotifier, List<RecipeSummary>>(
      RecipeListNotifier.new,
    );
