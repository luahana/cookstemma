import 'package:json_annotation/json_annotation.dart';
import '../../../domain/entities/autocomplete/autocomplete_result.dart';

part 'autocomplete_dto.g.dart';

@JsonSerializable()
class AutocompleteDto {
  // 💡 String? 로 변경하여 null 허용 (파싱 에러 방지)
  final String? publicId;
  final String name;
  final String type;
  final double score;

  AutocompleteDto({
    this.publicId, // 💡 required 제거
    required this.name,
    required this.type,
    required this.score,
  });

  factory AutocompleteDto.fromJson(Map<String, dynamic> json) =>
      _$AutocompleteDtoFromJson(json);

  AutocompleteResult toEntity() =>
      AutocompleteResult(publicId: publicId, name: name, type: type);
}
