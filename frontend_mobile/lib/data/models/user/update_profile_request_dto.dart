import 'package:json_annotation/json_annotation.dart';

part 'update_profile_request_dto.g.dart';

@JsonSerializable()
class UpdateProfileRequestDto {
  final String? username;
  final String? profileImagePublicId;
  final String? gender;  // MALE, FEMALE, OTHER
  final String? birthDate;  // yyyy-MM-dd format
  final String? preferredDietaryId;
  final bool? marketingAgreed;
  final String? locale;  // ko-KR, en-US

  UpdateProfileRequestDto({
    this.username,
    this.profileImagePublicId,
    this.gender,
    this.birthDate,
    this.preferredDietaryId,
    this.marketingAgreed,
    this.locale,
  });

  factory UpdateProfileRequestDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateProfileRequestDtoFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateProfileRequestDtoToJson(this);
}
