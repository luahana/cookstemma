import 'package:pairing_planet2_frontend/domain/entities/common/slice_response.dart';

class SliceResponseDto<T> {
  final List<T> content;
  final int? number;
  final int? size;
  final bool? first;
  final bool? last;
  final bool? hasNext;

  SliceResponseDto({
    required this.content,
    this.number,
    this.size,
    this.first,
    this.last,
    this.hasNext,
  });

  factory SliceResponseDto.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return SliceResponseDto<T>(
      content: (json['content'] as List<dynamic>)
          .map((e) => fromJsonT(e as Map<String, dynamic>))
          .toList(),
      number: json['number'] as int?,
      size: json['size'] as int?,
      first: json['first'] as bool?,
      last: json['last'] as bool?,
      hasNext: json['hasNext'] as bool?,
    );
  }

  SliceResponse<E> toEntity<E>(E Function(T) mapper) {
    return SliceResponse<E>(
      content: content.map(mapper).toList(),
      number: number ?? 0,
      size: size ?? 0,
      first: first ?? false,
      last: last ?? false,
      hasNext: hasNext ?? false,
    );
  }
}
