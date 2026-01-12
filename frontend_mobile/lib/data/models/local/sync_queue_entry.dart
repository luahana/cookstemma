import 'package:isar/isar.dart';

part 'sync_queue_entry.g.dart';

enum SyncQueueStatus {
  pending,
  syncing,
  synced,
  failed,
  abandoned,
}

@collection
class SyncQueueEntry {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String entryId;

  late String operationType;
  late String payload;

  @enumerated
  late SyncQueueStatus status;

  int retryCount = 0;
  late DateTime createdAt;
  DateTime? lastAttemptAt;
  String? errorMessage;
  String? localId;
}
