// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paged_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PagedResponseDto<T> _$PagedResponseDtoFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) =>
    PagedResponseDto<T>(
      items: (json['items'] as List<dynamic>).map(fromJsonT).toList(),
      currentPage: (json['currentPage'] as num).toInt(),
      totalPages: (json['totalPages'] as num).toInt(),
      hasNext: json['hasNext'] as bool,
    );

Map<String, dynamic> _$PagedResponseDtoToJson<T>(
  PagedResponseDto<T> instance,
  Object? Function(T value) toJsonT,
) =>
    <String, dynamic>{
      'items': instance.items.map(toJsonT).toList(),
      'currentPage': instance.currentPage,
      'totalPages': instance.totalPages,
      'hasNext': instance.hasNext,
    };
