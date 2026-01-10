import 'dart:convert';

/// Status of a sync queue item
enum SyncStatus {
  pending,   // Waiting to be synced
  syncing,   // Currently being synced
  synced,    // Successfully synced
  failed,    // Failed to sync (will retry)
  abandoned, // Failed too many times, won't retry
}

/// Type of sync operation
enum SyncOperationType {
  createLogPost,
  updateLogPost,
  deleteLogPost,
  uploadImage,
}

/// Represents an item in the offline sync queue
class SyncQueueItem {
  final String id;
  final SyncOperationType type;
  final String payload;
  final SyncStatus status;
  final int retryCount;
  final DateTime createdAt;
  final DateTime? lastAttemptAt;
  final String? errorMessage;
  final String? localId; // Local reference ID for optimistic UI

  static const int maxRetries = 3;

  const SyncQueueItem({
    required this.id,
    required this.type,
    required this.payload,
    this.status = SyncStatus.pending,
    this.retryCount = 0,
    required this.createdAt,
    this.lastAttemptAt,
    this.errorMessage,
    this.localId,
  });

  /// Check if this item should be retried
  bool get shouldRetry =>
      status == SyncStatus.failed && retryCount < maxRetries;

  /// Check if this item is ready to sync
  bool get isReadyToSync =>
      status == SyncStatus.pending ||
      (status == SyncStatus.failed && shouldRetry);

  /// Time since last attempt
  Duration? get timeSinceLastAttempt {
    if (lastAttemptAt == null) return null;
    return DateTime.now().difference(lastAttemptAt!);
  }

  /// Create a copy with updated fields
  SyncQueueItem copyWith({
    String? id,
    SyncOperationType? type,
    String? payload,
    SyncStatus? status,
    int? retryCount,
    DateTime? createdAt,
    DateTime? lastAttemptAt,
    String? errorMessage,
    String? localId,
  }) {
    return SyncQueueItem(
      id: id ?? this.id,
      type: type ?? this.type,
      payload: payload ?? this.payload,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      createdAt: createdAt ?? this.createdAt,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      errorMessage: errorMessage ?? this.errorMessage,
      localId: localId ?? this.localId,
    );
  }

  /// Mark as syncing
  SyncQueueItem markSyncing() {
    return copyWith(
      status: SyncStatus.syncing,
      lastAttemptAt: DateTime.now(),
    );
  }

  /// Mark as successfully synced
  SyncQueueItem markSynced() {
    return copyWith(
      status: SyncStatus.synced,
      lastAttemptAt: DateTime.now(),
    );
  }

  /// Mark as failed with error
  SyncQueueItem markFailed(String error) {
    final newRetryCount = retryCount + 1;
    return copyWith(
      status: newRetryCount >= maxRetries
          ? SyncStatus.abandoned
          : SyncStatus.failed,
      retryCount: newRetryCount,
      lastAttemptAt: DateTime.now(),
      errorMessage: error,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'payload': payload,
      'status': status.name,
      'retryCount': retryCount,
      'createdAt': createdAt.toIso8601String(),
      'lastAttemptAt': lastAttemptAt?.toIso8601String(),
      'errorMessage': errorMessage,
      'localId': localId,
    };
  }

  /// Create from JSON
  factory SyncQueueItem.fromJson(Map<String, dynamic> json) {
    return SyncQueueItem(
      id: json['id'] as String,
      type: SyncOperationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => SyncOperationType.createLogPost,
      ),
      payload: json['payload'] as String,
      status: SyncStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SyncStatus.pending,
      ),
      retryCount: json['retryCount'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastAttemptAt: json['lastAttemptAt'] != null
          ? DateTime.parse(json['lastAttemptAt'] as String)
          : null,
      errorMessage: json['errorMessage'] as String?,
      localId: json['localId'] as String?,
    );
  }

  /// Encode to JSON string
  String toJsonString() => jsonEncode(toJson());

  /// Decode from JSON string
  factory SyncQueueItem.fromJsonString(String jsonString) {
    return SyncQueueItem.fromJson(jsonDecode(jsonString));
  }

  @override
  String toString() {
    return 'SyncQueueItem(id: $id, type: $type, status: $status, retries: $retryCount)';
  }
}

/// Payload for creating a log post
class CreateLogPostPayload {
  final String? title;
  final String content;
  final String outcome;
  final String? recipePublicId;
  final List<String> localPhotoPaths;
  final List<String>? uploadedPhotoIds;
  final List<String>? hashtags;

  const CreateLogPostPayload({
    this.title,
    required this.content,
    required this.outcome,
    this.recipePublicId,
    required this.localPhotoPaths,
    this.uploadedPhotoIds,
    this.hashtags,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'outcome': outcome,
      'recipePublicId': recipePublicId,
      'localPhotoPaths': localPhotoPaths,
      'uploadedPhotoIds': uploadedPhotoIds,
      'hashtags': hashtags,
    };
  }

  factory CreateLogPostPayload.fromJson(Map<String, dynamic> json) {
    // Handle both old single-path format and new multi-path format
    List<String> photoPaths;
    if (json['localPhotoPaths'] != null) {
      photoPaths = (json['localPhotoPaths'] as List<dynamic>).cast<String>();
    } else if (json['localPhotoPath'] != null) {
      // Backwards compatibility with old single-path format
      photoPaths = [json['localPhotoPath'] as String];
    } else {
      photoPaths = [];
    }

    List<String>? uploadedIds;
    if (json['uploadedPhotoIds'] != null) {
      uploadedIds = (json['uploadedPhotoIds'] as List<dynamic>).cast<String>();
    } else if (json['uploadedPhotoId'] != null) {
      // Backwards compatibility
      uploadedIds = [json['uploadedPhotoId'] as String];
    }

    return CreateLogPostPayload(
      title: json['title'] as String?,
      content: json['content'] as String,
      outcome: json['outcome'] as String,
      recipePublicId: json['recipePublicId'] as String?,
      localPhotoPaths: photoPaths,
      uploadedPhotoIds: uploadedIds,
      hashtags: (json['hashtags'] as List<dynamic>?)?.cast<String>(),
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory CreateLogPostPayload.fromJsonString(String jsonString) {
    return CreateLogPostPayload.fromJson(jsonDecode(jsonString));
  }
}
