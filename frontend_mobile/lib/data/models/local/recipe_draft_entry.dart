import 'package:isar/isar.dart';

part 'recipe_draft_entry.g.dart';

@collection
class RecipeDraftEntry {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String draftKey;

  late String jsonData;
  late DateTime createdAt;
}
