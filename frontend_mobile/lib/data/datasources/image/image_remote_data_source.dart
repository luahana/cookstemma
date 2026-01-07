import 'dart:io';
import 'package:dio/dio.dart';
import '../../models/image/image_upload_response_dto.dart';

class ImageRemoteDataSource {
  final Dio _dio;

  ImageRemoteDataSource(this._dio);

  Future<ImageUploadResponseDto> uploadImage({
    required File file,
    required String type,
  }) async {
    // 💡 multipart/form-data 구성을 위한 FormData 생성
    final formData = FormData.fromMap({
      'type': type,
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.path.split('/').last,
      ),
    });

    final response = await _dio.post(
      '/images/upload',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    return ImageUploadResponseDto.fromJson(response.data);
  }
}
