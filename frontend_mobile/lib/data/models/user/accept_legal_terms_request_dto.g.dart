// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'accept_legal_terms_request_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AcceptLegalTermsRequestDto _$AcceptLegalTermsRequestDtoFromJson(
        Map<String, dynamic> json) =>
    AcceptLegalTermsRequestDto(
      termsVersion: json['termsVersion'] as String,
      privacyVersion: json['privacyVersion'] as String,
      marketingAgreed: json['marketingAgreed'] as bool?,
    );

Map<String, dynamic> _$AcceptLegalTermsRequestDtoToJson(
        AcceptLegalTermsRequestDto instance) =>
    <String, dynamic>{
      'termsVersion': instance.termsVersion,
      'privacyVersion': instance.privacyVersion,
      'marketingAgreed': instance.marketingAgreed,
    };
