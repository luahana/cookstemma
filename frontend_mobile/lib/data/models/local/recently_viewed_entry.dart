import 'package:isar/isar.dart';

part 'recently_viewed_entry.g.dart';

@collection
class RecentlyViewedEntry {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String publicId;

  late String jsonData;
  late DateTime viewedAt;
}
