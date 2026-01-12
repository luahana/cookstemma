import 'package:isar/isar.dart';

part 'cached_recipe.g.dart';

@collection
class CachedRecipe {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String cacheKey;

  late String jsonData;
  late DateTime cachedAt;
}
