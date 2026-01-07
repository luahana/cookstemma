import 'package:talker_flutter/talker_flutter.dart';

// 💡 전역적으로 접근 가능한 talker 인스턴스
final talker = TalkerFlutter.init(
  settings: TalkerSettings(
    maxHistoryItems: 100, // 로그 최대 보관 개수
    useConsoleLogs: true, // 터미널에 로그 출력 여부
  ),
);
