// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_list_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationListResponse _$NotificationListResponseFromJson(
        Map<String, dynamic> json) =>
    NotificationListResponse(
      notifications: (json['notifications'] as List<dynamic>)
          .map((e) => NotificationDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      unreadCount: (json['unreadCount'] as num).toInt(),
      hasNext: json['hasNext'] as bool,
    );

Map<String, dynamic> _$NotificationListResponseToJson(
        NotificationListResponse instance) =>
    <String, dynamic>{
      'notifications': instance.notifications,
      'unreadCount': instance.unreadCount,
      'hasNext': instance.hasNext,
    };
