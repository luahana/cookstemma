import 'package:dio/dio.dart';
import '../../models/autocomplete/autocomplete_dto.dart';

class AutocompleteRemoteDataSource {
  final Dio _dio;

  AutocompleteRemoteDataSource(this._dio);

  Future<List<AutocompleteDto>> getAutocomplete(
    String keyword,
    String locale,
  ) async {
    final response = await _dio.get(
      '/autocomplete', //
      queryParameters: {
        'keyword': keyword,
        'locale': locale, //
      },
    );

    // List 형태로 반환되는 응답 처리
    return (response.data as List)
        .map((e) => AutocompleteDto.fromJson(e))
        .toList();
  }
}
