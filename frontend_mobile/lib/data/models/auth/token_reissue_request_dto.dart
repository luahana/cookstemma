import 'package:json_annotation/json_annotation.dart';

part 'token_reissue_request_dto.g.dart';

@JsonSerializable()
class TokenReissueRequestDto {
  final String refreshToken; // 만료된 Access Token을 갱신하기 위한 토큰

  TokenReissueRequestDto({required this.refreshToken});

  factory TokenReissueRequestDto.fromJson(Map<String, dynamic> json) =>
      _$TokenReissueRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TokenReissueRequestDtoToJson(this);
}
