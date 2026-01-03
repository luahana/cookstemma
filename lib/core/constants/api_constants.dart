class ApiEndpoints {
  // Recipes 관련
  static const String recipes = '/recipes'; //
  static String recipeDetail(String id) => '/recipes/$id'; //

  // Feed 관련
  static const String homeFeed = '/home/feed'; //

  // Logs 관련
  static const String logs = '/logs'; //
  static String logDetail(String id) => '/logs/$id'; //
}

class HttpStatus {
  static const int ok = 200;
  static const int created = 201;
  static const int badRequest = 400;
  static const int unauthorized = 401; // 💡 401
  static const int forbidden = 403;
  static const int notFound = 404; // 💡 404
  static const int serverError = 500; // 💡 500
}
