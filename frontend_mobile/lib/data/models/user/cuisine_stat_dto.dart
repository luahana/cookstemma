import 'package:json_annotation/json_annotation.dart';

part 'cuisine_stat_dto.g.dart';

@JsonSerializable()
class CuisineStatDto {
  final String categoryCode;
  final String categoryName;
  final int count;
  final double percentage;

  CuisineStatDto({
    required this.categoryCode,
    required this.categoryName,
    required this.count,
    required this.percentage,
  });

  factory CuisineStatDto.fromJson(Map<String, dynamic> json) =>
      _$CuisineStatDtoFromJson(json);
  Map<String, dynamic> toJson() => _$CuisineStatDtoToJson(this);
}
