// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationDto _$NotificationDtoFromJson(Map<String, dynamic> json) =>
    NotificationDto(
      publicId: json['publicId'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      recipePublicId: json['recipePublicId'] as String?,
      logPostPublicId: json['logPostPublicId'] as String?,
      senderUsername: json['senderUsername'] as String?,
      senderProfileImageUrl: json['senderProfileImageUrl'] as String?,
      isRead: json['isRead'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      data: json['data'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$NotificationDtoToJson(NotificationDto instance) =>
    <String, dynamic>{
      'publicId': instance.publicId,
      'type': instance.type,
      'title': instance.title,
      'body': instance.body,
      'recipePublicId': instance.recipePublicId,
      'logPostPublicId': instance.logPostPublicId,
      'senderUsername': instance.senderUsername,
      'senderProfileImageUrl': instance.senderProfileImageUrl,
      'isRead': instance.isRead,
      'createdAt': instance.createdAt.toIso8601String(),
      'data': instance.data,
    };
