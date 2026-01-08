import 'package:json_annotation/json_annotation.dart';

part 'notification_dto.g.dart';

@JsonSerializable()
class NotificationDto {
  final String publicId;
  final String type; // RECIPE_COOKED, RECIPE_VARIATION
  final String title;
  final String body;
  final String? recipePublicId;
  final String? logPostPublicId;
  final String? senderUsername;
  final String? senderProfileImageUrl;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? data;

  NotificationDto({
    required this.publicId,
    required this.type,
    required this.title,
    required this.body,
    this.recipePublicId,
    this.logPostPublicId,
    this.senderUsername,
    this.senderProfileImageUrl,
    required this.isRead,
    required this.createdAt,
    this.data,
  });

  factory NotificationDto.fromJson(Map<String, dynamic> json) =>
      _$NotificationDtoFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationDtoToJson(this);

  NotificationDto copyWith({bool? isRead}) {
    return NotificationDto(
      publicId: publicId,
      type: type,
      title: title,
      body: body,
      recipePublicId: recipePublicId,
      logPostPublicId: logPostPublicId,
      senderUsername: senderUsername,
      senderProfileImageUrl: senderProfileImageUrl,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      data: data,
    );
  }
}
