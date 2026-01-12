import 'package:isar/isar.dart';

part 'cached_profile.g.dart';

@collection
class CachedProfile {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String cacheKey;

  late String jsonData;
  late DateTime cachedAt;
  late bool hasNext;
}
