import 'package:pairing_planet2_frontend/domain/entities/common/cursor_page_response.dart';

/// DTO for unified pagination responses from the API.
/// Maps to backend `UnifiedPageResponse<T>` Java record.
///
/// Supports both cursor-based (mobile) and offset-based (web) pagination:
/// - Mobile requests (with cursor param) → nextCursor is populated, offset fields are null
/// - Web requests (with page param) → offset fields are populated, nextCursor is null
class CursorPageResponseDto<T> {
  final List<T> content;
  final String? nextCursor;
  final bool hasNext;
  final int size;

  // Offset pagination fields (null for cursor-based requests)
  final int? totalElements;
  final int? totalPages;
  final int? currentPage;

  CursorPageResponseDto({
    required this.content,
    this.nextCursor,
    required this.hasNext,
    required this.size,
    this.totalElements,
    this.totalPages,
    this.currentPage,
  });

  factory CursorPageResponseDto.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return CursorPageResponseDto<T>(
      content: (json['content'] as List<dynamic>)
          .map((e) => fromJsonT(e as Map<String, dynamic>))
          .toList(),
      nextCursor: json['nextCursor'] as String?,
      hasNext: json['hasNext'] as bool? ?? false,
      size: json['size'] as int? ?? 20,
      totalElements: json['totalElements'] as int?,
      totalPages: json['totalPages'] as int?,
      currentPage: json['currentPage'] as int?,
    );
  }

  CursorPageResponse<E> toEntity<E>(E Function(T) mapper) {
    return CursorPageResponse<E>(
      content: content.map(mapper).toList(),
      nextCursor: nextCursor,
      hasNext: hasNext,
      size: size,
    );
  }
}
