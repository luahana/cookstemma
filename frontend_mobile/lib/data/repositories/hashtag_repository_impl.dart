import 'package:dartz/dartz.dart';
import 'package:pairing_planet2_frontend/core/error/failures.dart';
import 'package:pairing_planet2_frontend/data/datasources/hashtag/hashtag_remote_data_source.dart';
import 'package:pairing_planet2_frontend/domain/entities/common/cursor_page_response.dart';
import 'package:pairing_planet2_frontend/domain/entities/log_post/log_post_summary.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_summary.dart';
import 'package:pairing_planet2_frontend/domain/repositories/hashtag_repository.dart';

class HashtagRepositoryImpl implements HashtagRepository {
  final HashtagRemoteDataSource _remoteDataSource;

  HashtagRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, CursorPageResponse<RecipeSummary>>> getRecipesByHashtag({
    required String hashtagName,
    String? cursor,
    int size = 20,
  }) async {
    try {
      final dto = await _remoteDataSource.getRecipesByHashtag(
        hashtagName: hashtagName,
        cursor: cursor,
        size: size,
      );
      return Right(dto.toEntity((item) => item.toEntity()));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CursorPageResponse<LogPostSummary>>> getLogPostsByHashtag({
    required String hashtagName,
    String? cursor,
    int size = 20,
  }) async {
    try {
      final dto = await _remoteDataSource.getLogPostsByHashtag(
        hashtagName: hashtagName,
        cursor: cursor,
        size: size,
      );
      return Right(dto.toEntity((item) => item.toEntity()));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
