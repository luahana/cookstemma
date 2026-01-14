class ApiEndpoints {
  // Recipes 관련
  static const String recipes = '/recipes'; //
  static const String rootRecipes = '/recipes/roots'; //
  static String recipeDetail(String id) => '/recipes/$id'; //
  static String recipeSave(String id) => '/recipes/$id/save'; // P1: 북마크
  static String recipeModifiable(String id) => '/recipes/$id/modifiable'; // Recipe edit/delete check

  static const String logPosts = '/log_posts'; //
  static String logsByRecipe(String recipeId) => '/log_posts/recipe/$recipeId'; // Logs for a specific recipe

  // Feed 관련
  static const String homeFeed = '/home'; //

  // Logs 관련
  static const String logs = '/logs'; //
  static String logDetail(String id) => '/logs/$id'; //

  // User 관련
  static const String myProfile = '/users/me';
  static const String myCookingDna = '/users/me/cooking-dna';
  static const String myRecipes = '/recipes/my';
  static const String myLogs = '/log_posts/my';
  static const String savedRecipes = '/recipes/saved';
  static const String savedLogs = '/log_posts/saved';
  static String logPostSave(String id) => '/log_posts/$id/save';

  // Other User Profile 관련
  static String userProfile(String userId) => '/users/$userId';
  static String userRecipes(String userId) => '/users/$userId/recipes';
  static String userLogs(String userId) => '/users/$userId/logs';

  // Follow 관련
  static String follow(String userId) => '/users/$userId/follow';
  static String followStatus(String userId) => '/users/$userId/follow-status';
  static String followers(String userId) => '/users/$userId/followers';
  static String following(String userId) => '/users/$userId/following';

  // Block 관련
  static String block(String userId) => '/users/$userId/block';
  static String blockStatus(String userId) => '/users/$userId/block-status';
  static const String blockedUsers = '/users/me/blocked';

  // Report 관련
  static String report(String userId) => '/users/$userId/report';

  // Analytics 관련
  static const String events = '/events'; // 단일 이벤트 추적
  static const String eventsBatch = '/events/batch'; // 배치 이벤트 추적

  // Hashtags 관련
  static const String hashtags = '/hashtags';
  static const String hashtagSearch = '/hashtags/search';
}

class RouteConstants {
  static const String splash = '/splash';
  static const String home = '/';
  static const String login = '/login';
  static const String recipeCreate = '/recipe/create';
  static const String recipeEdit = '/recipe/edit/:id'; // Recipe edit screen
  static const String recipes = '/recipes';
  static const String recipeDetail = ':id'; // 하위 경로용
  static const String logPostCreate = '/log_post/create';
  static const String logPostDetail = '/log_post/:id';
  static const String logPosts = '/log_posts'; // 로그 포스트 리스트
  static const String search = '/search';
  static const String profile = '/profile';
  static const String profileEdit = '/profile/edit';
  static const String settings = '/profile/settings';
  static const String deleteAccount = '/profile/delete-account';
  static const String notifications = '/notifications';

  // User Profile 관련
  static const String userProfile = '/users/:userId';

  // Follow 관련
  static const String followers = '/users/:userId/followers';

  // Settings 관련
  static const String blockedUsers = '/settings/blocked-users';

  // Top-level recipe routes (with :id parameter for router)
  static const String recipeDetailFull = '/recipes/:id';
  static const String recipeStar = '/recipes/:id/star';
  static const String recipeVariationsFull = '/recipes/:id/variations';
  static const String recipeVariations = 'variations'; // Nested path only

  // 이동 시 사용할 전체 경로 헬퍼
  static String recipeDetailPath(String id) => '/recipes/$id';
  static String recipeEditPath(String id) => '/recipe/edit/$id';
  static String recipeStarPath(String id) => '/recipes/$id/star';
  static String recipeVariationsPath(String id) => '/recipes/$id/variations';
  static String logPostDetailPath(String id) => '/log_post/$id';

  static String userProfilePath(String userId) => '/users/$userId';
  static String followersPath(String userId) => '/users/$userId/followers';

  /// Build search path with optional query parameters.
  /// Used by View More buttons to navigate to filtered search results.
  /// [query] - search text query
  /// [sort] - 'recent', 'mostForked', 'trending'
  /// [contentType] - 'recipes', 'logPosts', 'all'
  /// [recipeId] - filter log posts by specific recipe
  static String searchPath({
    String? query,
    String? sort,
    String? contentType,
    String? recipeId,
  }) {
    final params = <String, String>{};
    if (query != null && query.isNotEmpty) params['q'] = query;
    if (sort != null && sort.isNotEmpty) params['sort'] = sort;
    if (contentType != null && contentType.isNotEmpty) {
      params['type'] = contentType;
    }
    if (recipeId != null && recipeId.isNotEmpty) {
      params['recipeId'] = recipeId;
    }

    if (params.isEmpty) return search;
    final queryString = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    return '$search?$queryString';
  }
}

class HttpStatus {
  static const int ok = 200;
  static const int created = 201;
  static const int noContent = 204;
  static const int badRequest = 400;
  static const int unauthorized = 401;
  static const int forbidden = 403;
  static const int notFound = 404;
  static const int serverError = 500;
}
