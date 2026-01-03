import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:pairing_planet2_frontend/core/constants/api_constants.dart';
import 'package:pairing_planet2_frontend/core/error/failures.dart';
import 'package:pairing_planet2_frontend/data/models/common/paged_response_dto.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_detail.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_summary.dart';
import '../../core/network/network_info.dart'; // 네트워크 상태 확인용 (추가 필요)
import '../datasources/recipe_local_data_source.dart'; // 로컬 데이터 소스 (추가 필요)
import '../../domain/repositories/recipe_repository.dart';
import '../datasources/recipe_remote_data_source.dart';

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
        return Left(ConnectionFailure('오프라인 상태이며 저장된 데이터가 없습니다.'));
      }
    }
  }

  @override
  Future<Either<Failure, PagedResponseDto<RecipeSummary>>> getRecipes({
    required int page,
    int size = 10,
  }) async {
    try {
      // 1. RemoteDataSource 호출
      final pagedDto = await remoteDataSource.getRecipes(
        page: page,
        size: size,
      );

      // 2. DTO 리스트를 엔티티 리스트로 변환
      final items = pagedDto.items.map((dto) => dto.toEntity()).toList();

      // 3. 변환된 데이터를 담은 새로운 PagedResponseDto 반환
      return Right(
        PagedResponseDto<RecipeSummary>(
          items: items,
          currentPage: pagedDto.currentPage,
          totalPages: pagedDto.totalPages,
          hasNext: pagedDto.hasNext,
        ),
      );
    } on DioException catch (e) {
      return Left(_mapDioExceptionToFailure(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
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
        return ServerFailure('에러 코드: $statusCode');

      default:
        return UnknownFailure();
    }
  }
}
