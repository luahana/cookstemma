import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:pairing_planet2_frontend/data/models/image/image_upload_response_dto.dart';
import '../../../core/error/failures.dart';

abstract class ImageRepository {
  Future<Either<Failure, ImageUploadResponseDto>> uploadImage({
    required File file,
    required String type,
  });
}
