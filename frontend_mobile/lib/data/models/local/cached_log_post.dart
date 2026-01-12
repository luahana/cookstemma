import 'package:isar/isar.dart';

part 'cached_log_post.g.dart';

@collection
class CachedLogPost {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String publicId;

  late String jsonData;
  late DateTime cachedAt;
}
