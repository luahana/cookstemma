/// Utility class for log post outcome handling
/// Centralizes emoji mappings to avoid duplication across files
class OutcomeUtils {
  static const Map<String, String> emojis = {
    'SUCCESS': '😊',
    'PARTIAL': '🙂',
    'FAILED': '😢',
  };

  static const String defaultEmoji = '🍳';

  /// Get emoji for outcome
  static String getEmoji(String? outcome) {
    if (outcome == null) return defaultEmoji;
    return emojis[outcome] ?? defaultEmoji;
  }
}
