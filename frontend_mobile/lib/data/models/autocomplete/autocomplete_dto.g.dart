// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'autocomplete_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AutocompleteDto _$AutocompleteDtoFromJson(Map<String, dynamic> json) =>
    AutocompleteDto(
      publicId: json['publicId'] as String?,
      name: json['name'] as String,
      type: json['type'] as String,
      score: (json['score'] as num).toDouble(),
    );

Map<String, dynamic> _$AutocompleteDtoToJson(AutocompleteDto instance) =>
    <String, dynamic>{
      'publicId': instance.publicId,
      'name': instance.name,
      'type': instance.type,
      'score': instance.score,
    };
