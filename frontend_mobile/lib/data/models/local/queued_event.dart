import 'package:isar/isar.dart';

part 'queued_event.g.dart';

enum SyncStatus {
  pending,
  syncing,
  synced,
  failed,
}

@collection
class QueuedEvent {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String eventId;

  late String eventType;
  String? userId;
  late DateTime timestamp;
  String? recipeId;
  String? logId;
  late String propertiesJson; // Serialized JSON
  late String priority; // 'immediate' or 'batched'

  @enumerated
  late SyncStatus status;

  int retryCount = 0;
  DateTime? lastAttempt;
}
