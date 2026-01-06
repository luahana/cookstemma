import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pairing_planet2_frontend/core/error/failures.dart';
import 'package:pairing_planet2_frontend/data/models/image/image_upload_response_dto.dart';
import 'package:pairing_planet2_frontend/data/repositories/image_repository_impl.dart';
import 'package:pairing_planet2_frontend/domain/entities/analytics/app_event.dart';
import 'package:pairing_planet2_frontend/domain/repositories/analytics_repository.dart';
import 'package:pairing_planet2_frontend/domain/repositories/image_repository.dart';
import 'package:uuid/uuid.dart';
import '../network/dio_provider.dart';
import '../../data/datasources/image/image_remote_data_source.dart';
import '../../domain/usecases/image/upload_image_usecase.dart';
import 'analytics_providers.dart';

// 1. Data Source
final imageRemoteDataSourceProvider = Provider((ref) {
  return ImageRemoteDataSource(ref.read(dioProvider));
});

// 2. Repository
final imageRepositoryProvider = Provider<ImageRepository>((ref) {
  return ImageRepositoryImpl(ref.read(imageRemoteDataSourceProvider));
});

// 3. UseCase
final uploadImageUseCaseProvider = Provider((ref) {
  return UploadImageUseCase(ref.read(imageRepositoryProvider));
});

// 4. Upload Image with Analytics Tracking
final uploadImageWithTrackingUseCaseProvider = Provider((ref) {
  return UploadImageWithTrackingUseCase(
    ref.read(uploadImageUseCaseProvider),
    ref.read(analyticsRepositoryProvider),
  );
});

class UploadImageWithTrackingUseCase {
  final UploadImageUseCase _uploadImageUseCase;
  final AnalyticsRepository _analyticsRepository;

  UploadImageWithTrackingUseCase(
    this._uploadImageUseCase,
    this._analyticsRepository,
  );

  Future<Either<Failure, ImageUploadResponseDto>> execute({
    required File file,
    required String type,
  }) async {
    final result = await _uploadImageUseCase.execute(file: file, type: type);

    return result.fold(
      (failure) => Left(failure),
      (response) {
        // Track photo upload event
        _analyticsRepository.trackEvent(AppEvent(
          eventId: const Uuid().v4(),
          eventType: EventType.logPhotoUploaded,
          timestamp: DateTime.now(),
          priority: EventPriority.batched,
          properties: {
            'image_size': file.lengthSync(),
            'image_type': type, // 'recipe' or 'log'
            'format': file.path.split('.').last,
            'public_id': response.imagePublicId,
          },
        ));

        return Right(response);
      },
    );
  }
}
