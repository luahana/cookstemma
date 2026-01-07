import 'package:json_annotation/json_annotation.dart';

part 'social_login_request_dto.g.dart';

@JsonSerializable()
class SocialLoginRequestDto {
  final String idToken; // Firebase에서 발급받은 ID Token
  final String locale; // 유저의 시스템 언어 설정

  SocialLoginRequestDto({required this.idToken, required this.locale});

  factory SocialLoginRequestDto.fromJson(Map<String, dynamic> json) =>
      _$SocialLoginRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SocialLoginRequestDtoToJson(this);
}
