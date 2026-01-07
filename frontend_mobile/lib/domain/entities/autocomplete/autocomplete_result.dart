class AutocompleteResult {
  final String? publicId; // 💡 String 뒤에 '?'를 붙여 null 허용
  final String name;
  final String type;

  AutocompleteResult({
    this.publicId, // 필수(required) 제거
    required this.name,
    required this.type,
  });

  factory AutocompleteResult.fromJson(Map<String, dynamic> json) {
    return AutocompleteResult(
      // 💡 null 체크 로직 강화
      publicId: json['publicId'] as String?,
      name: json['name'] as String,
      type: json['type'] as String,
    );
  }
}
