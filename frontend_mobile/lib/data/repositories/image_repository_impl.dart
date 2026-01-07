import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:pairing_planet2_frontend/core/error/failures.dart';
import 'package:pairing_planet2_frontend/data/datasources/image/image_remote_data_source.dart';
import 'package:pairing_planet2_frontend/data/models/image/image_upload_response_dto.dart';
import 'package:pairing_planet2_frontend/domain/repositories/image_repository.dart';

class ImageRepositoryImpl implements ImageRepository {
  final ImageRemoteDataSource _remoteDataSource;

  ImageRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, ImageUploadResponseDto>> uploadImage({
    required File file,
    required String type,
  }) async {
    try {
      // 1. 데이터 소스를 통해 이미지 업로드 수행
      final result = await _remoteDataSource.uploadImage(
        file: file,
        type: type,
      );

      // 2. 성공 시 DTO 반환 (필요 시 여기서 Entity로 변환 가능)
      return Right(result);
    } catch (e) {
      // 3. 서버 에러 또는 네트워크 에러 발생 시 Failure 반환
      return Left(ServerFailure(e.toString()));
    }
  }
}
