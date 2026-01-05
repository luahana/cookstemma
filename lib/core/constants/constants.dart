class ApiEndpoints {
  // Recipes 관련
  static const String recipes = '/recipes'; //
  static const String rootRecipes = '/recipes/roots'; //
  static String recipeDetail(String id) => '/recipes/$id'; //

  static const String log_posts = '/log_posts'; //

  // Feed 관련
  static const String homeFeed = '/home/feed'; //

  // Logs 관련
  static const String logs = '/logs'; //
  static String logDetail(String id) => '/logs/$id'; //
}

class RouteConstants {
  static const String home = '/';
  static const String login = '/login';
  static const String recipeCreate = '/recipe/create';
  static const String recipes = '/recipes';
  static const String recipeDetail = ':id'; // 하위 경로용
  static const String logPostCreate = '/log_post/create';
  static const String logDetail = '/log/:id'; // 💡 추가
  static const String search = '/search';
  static const String profile = '/profile';

  // 이동 시 사용할 전체 경로 헬퍼
  static String recipeDetailPath(String id) => '/recipes/$id';
  static String logDetailPath(String id) => '/log/$id';
}

class HttpStatus {
  static const int ok = 200;
  static const int created = 201;
  static const int badRequest = 400;
  static const int unauthorized = 401;
  static const int forbidden = 403;
  static const int notFound = 404;
  static const int serverError = 500;
}
