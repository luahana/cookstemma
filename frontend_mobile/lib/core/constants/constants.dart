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

  // Follow 관련
  static String follow(String userId) => '/users/$userId/follow';
  static String followStatus(String userId) => '/users/$userId/follow-status';
  static String followers(String userId) => '/users/$userId/followers';
  static String following(String userId) => '/users/$userId/following';

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

  // Follow 관련
  static const String followers = '/users/:userId/followers';

  // Star view for recipe family
  static const String recipeStar = '/recipes/:id/star';
  static const String recipeVariations = 'variations';

  // 이동 시 사용할 전체 경로 헬퍼
  static String recipeDetailPath(String id) => '/recipes/$id';
  static String recipeEditPath(String id) => '/recipe/edit/$id';
  static String recipeStarPath(String id) => '/recipes/$id/star';
  static String recipeVariationsPath(String id) => '/recipes/$id/variations';
  static String logPostDetailPath(String id) => '/log_post/$id';
  static String followersPath(String userId) => '/users/$userId/followers';
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
