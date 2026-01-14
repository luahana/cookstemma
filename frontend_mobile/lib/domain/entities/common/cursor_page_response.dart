/// Entity for cursor-based pagination responses.
/// Used for infinite scroll lists that use cursor-based pagination.
class CursorPageResponse<T> {
  final List<T> content;
  final String? nextCursor;
  final bool hasNext;
  final int size;
  final bool isFromCache;
  final DateTime? cachedAt;

  CursorPageResponse({
    required this.content,
    this.nextCursor,
    required this.hasNext,
    required this.size,
    this.isFromCache = false,
    this.cachedAt,
  });

  /// Creates a copy with updated values.
  CursorPageResponse<T> copyWith({
    List<T>? content,
    String? nextCursor,
    bool? hasNext,
    int? size,
    bool? isFromCache,
    DateTime? cachedAt,
  }) {
    return CursorPageResponse(
      content: content ?? this.content,
      nextCursor: nextCursor ?? this.nextCursor,
      hasNext: hasNext ?? this.hasNext,
      size: size ?? this.size,
      isFromCache: isFromCache ?? this.isFromCache,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  /// Creates an empty response.
  factory CursorPageResponse.empty({int size = 20}) {
    return CursorPageResponse(
      content: [],
      nextCursor: null,
      hasNext: false,
      size: size,
    );
  }
}
