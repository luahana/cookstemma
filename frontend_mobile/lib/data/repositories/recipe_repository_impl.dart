import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/core/error/failures.dart';
import 'package:pairing_planet2_frontend/data/models/recipe/create_recipe_request_dtos.dart';
import 'package:pairing_planet2_frontend/data/models/recipe/update_recipe_request_dto.dart';
import 'package:pairing_planet2_frontend/domain/entities/common/cursor_page_response.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/create_recipe_request.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_detail.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_modifiable.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_summary.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/update_recipe_request.dart';
import '../../core/network/network_info.dart';
import '../datasources/recipe/recipe_local_data_source.dart';
import '../../domain/repositories/recipe_repository.dart';
import '../datasources/recipe/recipe_remote_data_source.dart';

class RecipeRepositoryImpl implements RecipeRepository {
  final RecipeRemoteDataSource remoteDataSource;
  final RecipeLocalDataSource localDataSource; // 추가
  final NetworkInfo networkInfo; // 추가

  RecipeRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, String>> createRecipe(
    CreateRecipeRequest recipe,
  ) async {
    // 1. 네트워크 연결 상태 확인
    if (await networkInfo.isConnected) {
      try {
        // 2. Domain entity를 DTO로 변환
        final dto = CreateRecipeRequestDto.fromEntity(recipe);

        // 3. 서버에 레시피 생성 요청
        final newPublicId = await remoteDataSource.createRecipe(dto);

        // 💡 Unit 대신 받은 ID를 반환하여 스크린에서 사용할 수 있게 함
        return Right(newPublicId);
      } on DioException catch (e) {
        // 4. 에러 발생 시 기존 헬퍼 메서드로 Failure 매핑
        return Left(_mapDioExceptionToFailure(e));
      } catch (e) {
        return Left(UnknownFailure(e.toString()));
      }
    } else {
      // 5. 오프라인 상태 에러 반환
      return Left(ConnectionFailure('error.offlineCannotCreateRecipe'));
    }
  }

  @override
  Future<Either<Failure, RecipeDetail>> getRecipeDetail(String id) async {
    // 1. 로컬 캐시 데이터 먼저 확인
    final localData = await localDataSource.getLastRecipeDetail(id);

    // 2. 네트워크 연결 상태 확인
    if (await networkInfo.isConnected) {
      try {
        // 3. 온라인인 경우 서버에서 최신 데이터 요청
        final remoteDto = await remoteDataSource.getRecipeDetail(id);

        // 4. 서버 데이터 성공 시 로컬 캐시에 저장/갱신
        await localDataSource.cacheRecipeDetail(remoteDto);

        return Right(remoteDto.toEntity());
      } on DioException catch (e) {
        // 서버 에러가 났지만 로컬 데이터가 있다면 사용자에게 이전 데이터를 보여줌 (Fallback)
        if (localData != null) return Right(localData.toEntity());
        return Left(_mapDioExceptionToFailure(e));
      } catch (e) {
        if (localData != null) return Right(localData.toEntity());
        return Left(UnknownFailure(e.toString()));
      }
    } else {
      // 5. 오프라인인 경우 로컬 캐시 데이터 반환
      if (localData != null) {
        return Right(localData.toEntity());
      } else {
        // 캐시도 없고 오프라인인 경우 에러 반환
        return Left(ConnectionFailure('error.offlineNoData'));
      }
    }
  }

  @override
  Future<Either<Failure, CursorPageResponse<RecipeSummary>>> getRecipes({
    String? cursor,
    int size = 20,
    String? query,
    String? cuisineFilter,
    String? typeFilter,
    String? sort,
  }) async {
    // Check if any filters are active
    final hasFilters = (query != null && query.isNotEmpty) ||
        cuisineFilter != null ||
        typeFilter != null ||
        sort != null;

    // Filter/search mode: always fetch from network, no caching
    if (hasFilters) {
      try {
        final responseDto = await remoteDataSource.getRecipes(
          cursor: cursor,
          size: size,
          query: query,
          cuisineFilter: cuisineFilter,
          typeFilter: typeFilter,
          sort: sort,
        );
        return Right(responseDto.toEntity((dto) => dto.toEntity()));
      } on DioException catch (e) {
        return Left(_mapDioExceptionToFailure(e));
      } catch (e) {
        return Left(UnknownFailure(e.toString()));
      }
    }

    // Only cache initial page (cursor == null) when not searching/filtering
    if (cursor == null) {
      return _getRecipesWithCache(size: size);
    }

    // Subsequent pages: network-only (no caching for pagination)
    try {
      final responseDto = await remoteDataSource.getRecipes(cursor: cursor, size: size);
      return Right(responseDto.toEntity((dto) => dto.toEntity()));
    } on DioException catch (e) {
      return Left(_mapDioExceptionToFailure(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  /// Cache-first strategy for the initial page of recipes.
  Future<Either<Failure, CursorPageResponse<RecipeSummary>>> _getRecipesWithCache({
    int size = 20,
  }) async {
    // 1. Check for cached data
    final cached = await localDataSource.getCachedRecipeList();

    // 2. Check network connectivity
    if (await networkInfo.isConnected) {
      try {
        // 3. Fetch fresh data from server
        final responseDto = await remoteDataSource.getRecipes(cursor: null, size: size);

        // 4. Cache the first page on success
        await localDataSource.cacheRecipeList(responseDto.content);

        // 5. Return fresh data
        return Right(responseDto.toEntity((dto) => dto.toEntity()));
      } on DioException catch (e) {
        // Network error: fallback to cache if available
        if (cached != null) {
          return Right(CursorPageResponse(
            content: cached.data.map((d) => d.toEntity()).toList(),
            nextCursor: null,
            hasNext: true, // Assume there's more (can't verify offline)
            size: cached.data.length,
            isFromCache: true,
            cachedAt: cached.cachedAt,
          ));
        }
        return Left(_mapDioExceptionToFailure(e));
      } catch (e) {
        if (cached != null) {
          return Right(CursorPageResponse(
            content: cached.data.map((d) => d.toEntity()).toList(),
            nextCursor: null,
            hasNext: true,
            size: cached.data.length,
            isFromCache: true,
            cachedAt: cached.cachedAt,
          ));
        }
        return Left(UnknownFailure(e.toString()));
      }
    } else {
      // Offline: use cached data
      if (cached != null) {
        return Right(CursorPageResponse(
          content: cached.data.map((d) => d.toEntity()).toList(),
          nextCursor: null,
          hasNext: false, // Can't paginate offline
          size: cached.data.length,
          isFromCache: true,
          cachedAt: cached.cachedAt,
        ));
      }
      return Left(ConnectionFailure('error.offlineNoData'));
    }
  }

  // P1: 레시피 저장 (북마크)
  @override
  Future<Either<Failure, void>> saveRecipe(String publicId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.saveRecipe(publicId);
        return const Right(null);
      } on DioException catch (e) {
        return Left(_mapDioExceptionToFailure(e));
      } catch (e) {
        return Left(UnknownFailure(e.toString()));
      }
    } else {
      return Left(ConnectionFailure('error.noNetwork'));
    }
  }

  // P1: 레시피 저장 취소
  @override
  Future<Either<Failure, void>> unsaveRecipe(String publicId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.unsaveRecipe(publicId);
        return const Right(null);
      } on DioException catch (e) {
        return Left(_mapDioExceptionToFailure(e));
      } catch (e) {
        return Left(UnknownFailure(e.toString()));
      }
    } else {
      return Left(ConnectionFailure('error.noNetwork'));
    }
  }

  // Recipe modification: check if recipe can be edited/deleted
  @override
  Future<Either<Failure, RecipeModifiable>> checkRecipeModifiable(
    String publicId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final dto = await remoteDataSource.checkRecipeModifiable(publicId);
        return Right(dto.toEntity());
      } on DioException catch (e) {
        return Left(_mapDioExceptionToFailure(e));
      } catch (e) {
        return Left(UnknownFailure(e.toString()));
      }
    } else {
      return Left(
        ConnectionFailure('error.offlineCannotCheck'),
      );
    }
  }

  // Recipe modification: update recipe in-place
  @override
  Future<Either<Failure, RecipeDetail>> updateRecipe(
    String publicId,
    UpdateRecipeRequest request,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final dto = UpdateRecipeRequestDto.fromEntity(request);
        final responseDto = await remoteDataSource.updateRecipe(publicId, dto);

        // Update local cache
        await localDataSource.cacheRecipeDetail(responseDto);

        return Right(responseDto.toEntity());
      } on DioException catch (e) {
        return Left(_mapDioExceptionToFailure(e));
      } catch (e) {
        return Left(UnknownFailure(e.toString()));
      }
    } else {
      return Left(ConnectionFailure('error.offlineCannotEditRecipe'));
    }
  }

  // Recipe modification: delete recipe (soft delete)
  @override
  Future<Either<Failure, void>> deleteRecipe(String publicId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteRecipe(publicId);

        // Remove from local cache
        await localDataSource.removeRecipeDetail(publicId);

        return const Right(null);
      } on DioException catch (e) {
        return Left(_mapDioExceptionToFailure(e));
      } catch (e) {
        return Left(UnknownFailure(e.toString()));
      }
    } else {
      return Left(ConnectionFailure('error.offlineCannotDeleteRecipe'));
    }
  }

  Failure _mapDioExceptionToFailure(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.connectionError:
        return ConnectionFailure();

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == HttpStatus.notFound) return NotFoundFailure();
        if (statusCode == HttpStatus.unauthorized) return UnauthorizedFailure();
        if (statusCode == HttpStatus.serverError) return ServerFailure();
        return ServerFailure('Error code: $statusCode');

      default:
        return UnknownFailure();
    }
  }
}
