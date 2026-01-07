import 'package:json_annotation/json_annotation.dart';

part 'user_dto.g.dart';

@JsonSerializable()
class UserDto {
  final String id;
  final String username;
  final String? profileImageId;
  final String? profileImageUrl;
  final String? gender;
  final String? birthDate;

  UserDto({
    required this.id,
    required this.username,
    this.profileImageId,
    this.profileImageUrl,
    this.gender,
    this.birthDate,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) => _$UserDtoFromJson(json);
  Map<String, dynamic> toJson() => _$UserDtoToJson(this);
}
