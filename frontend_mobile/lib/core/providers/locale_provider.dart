import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final localeProvider = StateProvider<String>((ref) {
  // 1. 초기 상태 설정: 기기 로케일 불러오기
  final deviceLocale = PlatformDispatcher.instance.locale;

  // 2. ko-KR 포맷으로 변환 함수
  String formatLocale(Locale locale) {
    final languageCode = locale.languageCode;
    // countryCode가 없는 경우 대문자 languageCode를 대신 사용 (예: ko -> ko-KR)
    final countryCode = locale.countryCode ?? languageCode.toUpperCase();
    return '$languageCode-$countryCode';
  }

  return formatLocale(deviceLocale);
});
