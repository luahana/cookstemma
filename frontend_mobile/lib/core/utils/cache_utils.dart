/// Wrapper class for cached data that includes timestamp information.
class CachedData<T> {
  final T data;
  final DateTime cachedAt;

  CachedData({
    required this.data,
    required this.cachedAt,
  });

  /// Check if the cached data has expired based on the given TTL.
  bool isExpired(Duration ttl) => DateTime.now().difference(cachedAt) > ttl;

  /// Convert to JSON for storage.
  /// Requires a function to serialize the data type.
  Map<String, dynamic> toJson(Map<String, dynamic> Function(T) dataToJson) => {
        'data': dataToJson(data),
        'cachedAt': cachedAt.toIso8601String(),
      };

  /// Create from JSON.
  /// Requires a function to deserialize the data type.
  static CachedData<T> fromJson<T>(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) dataFromJson,
  ) =>
      CachedData(
        data: dataFromJson(json['data'] as Map<String, dynamic>),
        cachedAt: DateTime.parse(json['cachedAt'] as String),
      );
}

/// TTL (Time To Live) constants for different cache types.
class CacheTTL {
  CacheTTL._();

  /// Home feed cache: 5 minutes
  static const Duration homeFeed = Duration(minutes: 5);

  /// Recipe list cache: 10 minutes
  static const Duration recipeList = Duration(minutes: 10);

  /// Recipe detail cache: 30 minutes
  static const Duration recipeDetail = Duration(minutes: 30);

  /// Log post detail cache: 30 minutes
  static const Duration logPostDetail = Duration(minutes: 30);

  /// Profile tabs cache (My Recipes, My Logs, Saved): 5 minutes
  static const Duration profileTabs = Duration(minutes: 5);
}
