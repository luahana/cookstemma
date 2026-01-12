import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pairing_planet2_frontend/core/network/network_info.dart';
import 'package:pairing_planet2_frontend/core/network/network_info_impl.dart';
import 'package:pairing_planet2_frontend/core/providers/isar_provider.dart';
import 'package:pairing_planet2_frontend/domain/entities/common/slice_response.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_detail.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_summary.dart';
import 'package:pairing_planet2_frontend/domain/usecases/recipe/create_recipe_usecase.dart';
import 'package:pairing_planet2_frontend/domain/usecases/recipe/get_recipe_detail.dart';
import 'package:pairing_planet2_frontend/data/datasources/recipe/recipe_local_data_source.dart';
import '../../../core/network/dio_provider.dart';
import '../../../data/datasources/recipe/recipe_remote_data_source.dart';
import '../../../data/repositories/recipe_repository_impl.dart';
import '../../../domain/repositories/recipe_repository.dart';

// Re-export split providers for backward compatibility
export 'recipe_draft_provider.dart';
export 'recipe_crud_providers.dart';
export 'recipe_tracking_provider.dart';

// ----------------------------------------------------------------
// 1. Infrastructure Providers (Network & Storage)
// ----------------------------------------------------------------

final connectivityProvider = Provider<Connectivity>((ref) => Connectivity());

final networkInfoProvider = Provider<NetworkInfo>((ref) {
  final connectivity = ref.read(connectivityProvider);
  return NetworkInfoImpl(connectivity);
});

final recipeLocalDataSourceProvider = Provider<RecipeLocalDataSource>((ref) {
  final isar = ref.read(isarProvider);
  return RecipeLocalDataSource(isar);
});

// ----------------------------------------------------------------
// 2. Data Layer Providers
// ----------------------------------------------------------------

final recipeRemoteDataSourceProvider = Provider<RecipeRemoteDataSource>((ref) {
  final dio = ref.read(dioProvider);
  return RecipeRemoteDataSource(dio);
});

final recipeRepositoryProvider = Provider<RecipeRepository>((ref) {
  final remoteDataSource = ref.read(recipeRemoteDataSourceProvider);
  final localDataSource = ref.read(recipeLocalDataSourceProvider);
  final networkInfo = ref.read(networkInfoProvider);

  return RecipeRepositoryImpl(
    remoteDataSource: remoteDataSource,
    localDataSource: localDataSource,
    networkInfo: networkInfo,
  );
});

// ----------------------------------------------------------------
// 3. Domain Layer Providers (UseCase)
// ----------------------------------------------------------------

final getRecipeDetailUseCaseProvider = Provider<GetRecipeDetailUseCase>((ref) {
  final repository = ref.read(recipeRepositoryProvider);
  return GetRecipeDetailUseCase(repository);
});

final createRecipeUseCaseProvider = Provider<CreateRecipeUseCase>((ref) {
  final repository = ref.read(recipeRepositoryProvider);
  return CreateRecipeUseCase(repository);
});

// ----------------------------------------------------------------
// 4. Basic Presentation Providers
// ----------------------------------------------------------------

final recipeDetailProvider = FutureProvider.family<RecipeDetail, String>((
  ref,
  id,
) async {
  final useCase = ref.watch(getRecipeDetailUseCaseProvider);
  final result = await useCase(id);
  return result.fold((failure) => throw failure.message, (recipe) => recipe);
});

final recipesProvider =
    FutureProvider.family<SliceResponse<RecipeSummary>, int>((
  ref,
  page,
) async {
  final repository = ref.watch(recipeRepositoryProvider);
  final result = await repository.getRecipes(page: page, size: 10);
  return result.fold(
    (failure) => throw failure,
    (sliceResponse) => sliceResponse,
  );
});
