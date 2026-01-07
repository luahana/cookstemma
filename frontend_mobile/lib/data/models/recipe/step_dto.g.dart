// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'step_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StepDto _$StepDtoFromJson(Map<String, dynamic> json) => StepDto(
      stepNumber: (json['stepNumber'] as num).toInt(),
      description: json['description'] as String?,
      imagePublicId: json['imagePublicId'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );

Map<String, dynamic> _$StepDtoToJson(StepDto instance) => <String, dynamic>{
      'stepNumber': instance.stepNumber,
      'description': instance.description,
      'imagePublicId': instance.imagePublicId,
      'imageUrl': instance.imageUrl,
    };
