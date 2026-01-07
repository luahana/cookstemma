class SliceResponse<T> {
  final List<T> content;
  final int number;
  final int size;
  final bool first;
  final bool last;
  final bool hasNext;
  final bool isFromCache;
  final DateTime? cachedAt;

  SliceResponse({
    required this.content,
    required this.number,
    required this.size,
    required this.first,
    required this.last,
    required this.hasNext,
    this.isFromCache = false,
    this.cachedAt,
  });

  /// Creates a copy with updated cache status.
  SliceResponse<T> copyWith({
    List<T>? content,
    int? number,
    int? size,
    bool? first,
    bool? last,
    bool? hasNext,
    bool? isFromCache,
    DateTime? cachedAt,
  }) {
    return SliceResponse(
      content: content ?? this.content,
      number: number ?? this.number,
      size: size ?? this.size,
      first: first ?? this.first,
      last: last ?? this.last,
      hasNext: hasNext ?? this.hasNext,
      isFromCache: isFromCache ?? this.isFromCache,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }
}
