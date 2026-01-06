import 'package:json_annotation/json_annotation.dart';
import 'user_dto.dart';

part 'my_profile_response_dto.g.dart';

@JsonSerializable()
class MyProfileResponseDto {
  final UserDto user;
  final int recipeCount;
  final int logCount;
  final int savedCount;

  MyProfileResponseDto({
    required this.user,
    required this.recipeCount,
    required this.logCount,
    required this.savedCount,
  });

  factory MyProfileResponseDto.fromJson(Map<String, dynamic> json) =>
      _$MyProfileResponseDtoFromJson(json);
  Map<String, dynamic> toJson() => _$MyProfileResponseDtoToJson(this);
}
