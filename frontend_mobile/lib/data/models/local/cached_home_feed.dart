import 'package:isar/isar.dart';

part 'cached_home_feed.g.dart';

@collection
class CachedHomeFeed {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String cacheKey;

  late String jsonData;
  late DateTime cachedAt;
}
