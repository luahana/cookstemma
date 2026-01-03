import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pairing_planet2_frontend/core/network/network_info.dart';
import 'package:pairing_planet2_frontend/core/network/network_info_impl.dart';
import 'package:pairing_planet2_frontend/core/usecase/get_recipe_detail.dart';
import 'package:pairing_planet2_frontend/data/datasources/recipe_local_data_source.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_detail.dart';
import '../../../core/network/dio_provider.dart';
import '../../../data/datasources/recipe_remote_data_source.dart';
import '../../../data/repositories/recipe_repository_impl.dart';
import '../../../domain/repositories/recipe_repository.dart';

// ----------------------------------------------------------------
// 1. 기초 인프라 (Network & Storage) Providers
// ----------------------------------------------------------------

// 네트워크 연결 상태 확인 도구 (Connectivity 패키지)
final connectivityProvider = Provider<Connectivity>((ref) => Connectivity());

// 클린 아키텍처를 위한 NetworkInfo 인터페이스 구현체 주입
final networkInfoProvider = Provider<NetworkInfo>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  return NetworkInfoImpl(connectivity);
});

// 로컬 캐싱을 담당하는 데이터 소스
final recipeLocalDataSourceProvider = Provider<RecipeLocalDataSource>((ref) {
  return RecipeLocalDataSource();
});

// ----------------------------------------------------------------
// 2. Data Layer Providers
// ----------------------------------------------------------------

// 백엔드 API와 직접 통신하는 리모트 데이터 소스
final recipeDataSourceProvider = Provider<RecipeRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return RecipeRemoteDataSource(dio);
});

// 리포지토리 구현체: Remote, Local, NetworkInfo를 모두 조합하여 데이터 흐름 제어
final recipeRepositoryProvider = Provider<RecipeRepository>((ref) {
  final remoteDataSource = ref.watch(recipeDataSourceProvider);
  final localDataSource = ref.watch(recipeLocalDataSourceProvider);
  final networkInfo = ref.watch(networkInfoProvider);

  return RecipeRepositoryImpl(
    remoteDataSource: remoteDataSource,
    localDataSource: localDataSource,
    networkInfo: networkInfo,
  );
});

// ----------------------------------------------------------------
// 3. Domain Layer Providers (UseCase)
// ----------------------------------------------------------------

// 비즈니스 로직을 담당하는 UseCase
final getRecipeDetailUseCaseProvider = Provider<GetRecipeDetailUseCase>((ref) {
  final repository = ref.watch(recipeRepositoryProvider);
  return GetRecipeDetailUseCase(repository);
});

// ----------------------------------------------------------------
// 4. Presentation Layer Providers (State)
// ----------------------------------------------------------------

// UI에서 'ref.watch(recipeDetailProvider(id))'로 간단히 데이터를 불러올 때 사용
final recipeDetailProvider = FutureProvider.family<RecipeDetail, String>((
  ref,
  id,
) async {
  final useCase = ref.watch(getRecipeDetailUseCaseProvider);
  final result = await useCase(id);

  // Either 타입을 폴드(fold)하여 실패 시 에러를 던지고, 성공 시 데이터를 반환
  return result.fold((failure) => throw failure.message, (recipe) => recipe);
});
