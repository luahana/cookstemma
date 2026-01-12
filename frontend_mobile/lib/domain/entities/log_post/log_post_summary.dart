import 'package:pairing_planet2_frontend/data/models/sync/sync_queue_item.dart';

class LogPostSummary {
  final String id;
  final String title;
  final String? outcome; // SUCCESS, PARTIAL, FAILED
  final String? thumbnailUrl;
  final String? creatorPublicId; // Creator's publicId for profile navigation
  final String? creatorName;
  final DateTime? createdAt;
  final bool isPending; // For optimistic UI - true if not yet synced to server

  LogPostSummary({
    required this.id,
    required this.title,
    this.outcome,
    this.thumbnailUrl,
    this.creatorPublicId,
    this.creatorName,
    this.createdAt,
    this.isPending = false,
  });

  /// Create a LogPostSummary from a pending sync queue item for optimistic display
  factory LogPostSummary.fromSyncQueueItem(SyncQueueItem item) {
    final payload = CreateLogPostPayload.fromJsonString(item.payload);

    // Use localId as temporary ID
    final id = item.localId ?? item.id;

    // Use local file path for thumbnail (will display from local storage)
    String? thumbnailUrl;
    if (payload.localPhotoPaths.isNotEmpty) {
      thumbnailUrl = 'file://${payload.localPhotoPaths.first}';
    }

    return LogPostSummary(
      id: id,
      title: payload.title ?? 'Quick Log',
      outcome: payload.outcome,
      thumbnailUrl: thumbnailUrl,
      creatorName: null, // User's own log, no need to show name
      createdAt: item.createdAt,
      isPending: true,
    );
  }
}
