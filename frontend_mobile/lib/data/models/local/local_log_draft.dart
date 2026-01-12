import 'package:isar/isar.dart';

part 'local_log_draft.g.dart';

@collection
class LocalLogDraft {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String localId;

  late String jsonData;
}
