import 'package:json_annotation/json_annotation.dart';

part 'paged_response_dto.g.dart';

@JsonSerializable(genericArgumentFactories: true)
class PagedResponseDto<T> {
  final List<T> items;
  final int currentPage;
  final int totalPages;
  final bool hasNext;

  PagedResponseDto({
    required this.items,
    required this.currentPage,
    required this.totalPages,
    required this.hasNext,
  });

  // 💡 제네릭 타입을 위해 fromJson에 파싱 함수를 추가로 받습니다.
  factory PagedResponseDto.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) => _$PagedResponseDtoFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) =>
      _$PagedResponseDtoToJson(this, toJsonT);
}
