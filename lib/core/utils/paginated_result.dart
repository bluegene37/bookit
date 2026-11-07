// Gene - Nov 07, 2026: Generic PaginatedResult model for offset/range pagination across high-scale discovery and admin lists
class PaginatedResult<T> {
  final List<T> items;
  final int page;
  final int pageSize;
  final int totalCount;
  final bool hasMore;

  const PaginatedResult({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.hasMore,
  });

  factory PaginatedResult.fromFullList({
    required List<T> fullList,
    required int page,
    required int pageSize,
  }) {
    final safePage = page < 0 ? 0 : page;
    final safeSize = pageSize <= 0 ? 20 : pageSize;
    final total = fullList.length;
    final start = safePage * safeSize;

    if (start >= total) {
      return PaginatedResult<T>(
        items: const [],
        page: safePage,
        pageSize: safeSize,
        totalCount: total,
        hasMore: false,
      );
    }

    final end = (start + safeSize) > total ? total : (start + safeSize);
    return PaginatedResult<T>(
      items: fullList.sublist(start, end),
      page: safePage,
      pageSize: safeSize,
      totalCount: total,
      hasMore: end < total,
    );
  }
}
