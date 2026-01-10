enum EventType {
  // Write events (immediate priority)
  recipeCreated,
  recipeUpdated,
  recipeDeleted,
  logCreated,
  variationCreated,
  logFailed,

  // Read events (batched priority)
  recipeViewed,
  logViewed,
  recipeSaved,
  recipeShared,
  variationTreeViewed,
  searchPerformed,
  logPhotoUploaded,
}

enum EventPriority {
  immediate, // Critical write operations - sent immediately
  batched, // Analytics/metrics - batched every 30-60 seconds
}

class AppEvent {
  final String eventId; // UUID for idempotency
  final EventType eventType;
  final String? userId; // Null for anonymous users
  final DateTime timestamp;
  final Map<String, dynamic> properties;
  final String? recipeId;
  final String? logId;
  final EventPriority priority;

  AppEvent({
    required this.eventId,
    required this.eventType,
    this.userId,
    required this.timestamp,
    this.properties = const {},
    this.recipeId,
    this.logId,
    required this.priority,
  });

  Map<String, dynamic> toJson() => {
        'eventId': eventId,
        'eventType': eventType.name,
        'userId': userId,
        'timestamp': timestamp.toIso8601String(),
        'properties': properties,
        'recipeId': recipeId,
        'logId': logId,
      };
}
