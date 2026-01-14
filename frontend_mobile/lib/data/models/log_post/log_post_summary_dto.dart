import 'package:json_annotation/json_annotation.dart';
import 'package:pairing_planet2_frontend/data/models/sync/sync_queue_item.dart';
import 'package:pairing_planet2_frontend/domain/entities/log_post/log_post_summary.dart';

part 'log_post_summary_dto.g.dart';

@JsonSerializable()
class LogPostSummaryDto {
  final String publicId;
  final String? title;
  final String? outcome; // SUCCESS, PARTIAL, FAILED
  final String? thumbnailUrl;
  final String? creatorPublicId; // Creator's publicId for profile navigation
  final String? creatorName;
  final String? foodName; // Dish name from linked recipe
  final List<String>? hashtags; // Hashtag names
  final bool? isVariant; // Whether the linked recipe is a variant

  @JsonKey(includeFromJson: false, includeToJson: false)
  final bool isPending;

  LogPostSummaryDto({
    required this.publicId,
    this.title,
    this.outcome,
    this.thumbnailUrl,
    this.creatorPublicId,
    this.creatorName,
    this.foodName,
    this.hashtags,
    this.isVariant,
    this.isPending = false,
  });

  /// Create a LogPostSummaryDto from a pending sync queue item for optimistic display
  factory LogPostSummaryDto.fromSyncQueueItem(SyncQueueItem item) {
    final payload = CreateLogPostPayload.fromJsonString(item.payload);

    // Use localId as temporary ID
    final id = item.localId ?? item.id;

    // Use local file path for thumbnail (will display from local storage)
    String? thumbnailUrl;
    if (payload.localPhotoPaths.isNotEmpty) {
      thumbnailUrl = 'file://${payload.localPhotoPaths.first}';
    }

    return LogPostSummaryDto(
      publicId: id,
      title: payload.title ?? 'Quick Log',
      outcome: payload.outcome,
      thumbnailUrl: thumbnailUrl,
      creatorName: null, // User's own log, no need to show name
      foodName: null, // Not available for pending items
      hashtags: payload.hashtags,
      isPending: true,
    );
  }

  factory LogPostSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$LogPostSummaryDtoFromJson(json);
  Map<String, dynamic> toJson() => _$LogPostSummaryDtoToJson(this);

  LogPostSummary toEntity() => LogPostSummary(
    id: publicId,
    title: title ?? '',
    outcome: outcome,
    thumbnailUrl: thumbnailUrl,
    creatorPublicId: creatorPublicId,
    creatorName: creatorName,
    foodName: foodName,
    hashtags: hashtags,
    isVariant: isVariant,
    isPending: isPending,
  );
}
