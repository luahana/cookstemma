import 'package:json_annotation/json_annotation.dart';

part 'auth_response_dto.g.dart';

@JsonSerializable()
class AuthResponseDto {
  final String accessToken;
  final String refreshToken;
  final String userPublicId; // Java의 UUID는 String으로 매핑
  final String username;

  AuthResponseDto({
    required this.accessToken,
    required this.refreshToken,
    required this.userPublicId,
    required this.username,
  });

  // JSON 직렬화 로직
  factory AuthResponseDto.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AuthResponseDtoToJson(this);
}
