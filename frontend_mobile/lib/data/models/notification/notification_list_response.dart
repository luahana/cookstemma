import 'package:json_annotation/json_annotation.dart';
import 'notification_dto.dart';

part 'notification_list_response.g.dart';

@JsonSerializable()
class NotificationListResponse {
  final List<NotificationDto> notifications;
  final int unreadCount;
  final bool hasNext;

  NotificationListResponse({
    required this.notifications,
    required this.unreadCount,
    required this.hasNext,
  });

  factory NotificationListResponse.fromJson(Map<String, dynamic> json) =>
      _$NotificationListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationListResponseToJson(this);
}
