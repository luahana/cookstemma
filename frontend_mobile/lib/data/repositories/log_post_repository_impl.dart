import 'package:dartz/dartz.dart';
import 'package:pairing_planet2_frontend/core/error/failures.dart';
import 'package:pairing_planet2_frontend/data/datasources/log_post/log_post_local_data_source.dart';
import 'package:pairing_planet2_frontend/data/datasources/log_post/log_post_remote_data_source.dart';
import 'package:pairing_planet2_frontend/data/models/log_post/create_log_post_request_dto.dart';
import 'package:pairing_planet2_frontend/domain/entities/common/slice_response.dart';
import 'package:pairing_planet2_frontend/domain/entities/log_post/create_log_post_request.dart';
import 'package:pairing_planet2_frontend/domain/entities/log_post/log_post_detail.dart';
import 'package:pairing_planet2_frontend/domain/entities/log_post/log_post_summary.dart';
import 'package:pairing_planet2_frontend/domain/repositories/log_post_repository.dart';
import '../../core/network/network_info.dart';

class LogPostRepositoryImpl implements LogPostRepository {
  final LogPostRemoteDataSource remoteDataSource;
  final LogPostLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  LogPostRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, LogPostDetail>> createLog(
    CreateLogPostRequest request,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final dto = CreateLogPostRequestDto.fromEntity(request);
        final result = await remoteDataSource.createLog(dto);
        return Right(result.toEntity());
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    }
    return Left(ConnectionFailure());
  }

  @override
  Future<Either<Failure, LogPostDetail>> getLogDetail(String publicId) async {
    // 1. 로컬 캐시 먼저 확인
    final localData = await localDataSource.getLastLogDetail(publicId);

    if (await networkInfo.isConnected) {
      try {
        // 2. 서버 데이터 요청
        final remoteDto = await remoteDataSource.getLogDetail(publicId);

        // 3. 최신 데이터 캐싱
        await localDataSource.cacheLogDetail(remoteDto);

        return Right(remoteDto.toEntity());
      } catch (e) {
        // 서버 에러 시 캐시 데이터가 있다면 반환
        if (localData != null) return Right(localData.toEntity());
        return Left(ServerFailure(e.toString()));
      }
    } else {
      // 4. 오프라인일 때 로컬 데이터 반환
      if (localData != null) return Right(localData.toEntity());
      return Left(ConnectionFailure('오프라인 상태이며 저장된 데이터가 없습니다.'));
    }
  }

  @override
  Future<Either<Failure, SliceResponse<LogPostSummary>>> getLogPosts({
    int page = 0,
    int size = 20,
    String? query,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final sliceDto = await remoteDataSource.getLogPosts(
          page: page,
          size: size,
          query: query,
        );
        return Right(sliceDto.toEntity((dto) => dto.toEntity()));
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    }
    return Left(ConnectionFailure());
  }
}
