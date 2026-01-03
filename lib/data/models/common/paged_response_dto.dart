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

  // 팩토리 메서드는 각 도메인 DTO에서 items를 파싱하여 호출하도록 구성합니다.
}
