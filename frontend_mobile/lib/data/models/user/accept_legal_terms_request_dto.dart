import 'package:json_annotation/json_annotation.dart';

part 'accept_legal_terms_request_dto.g.dart';

@JsonSerializable()
class AcceptLegalTermsRequestDto {
  final String termsVersion;
  final String privacyVersion;
  final bool? marketingAgreed;

  AcceptLegalTermsRequestDto({
    required this.termsVersion,
    required this.privacyVersion,
    this.marketingAgreed,
  });

  factory AcceptLegalTermsRequestDto.fromJson(Map<String, dynamic> json) =>
      _$AcceptLegalTermsRequestDtoFromJson(json);
  Map<String, dynamic> toJson() => _$AcceptLegalTermsRequestDtoToJson(this);
}
