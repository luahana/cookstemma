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
