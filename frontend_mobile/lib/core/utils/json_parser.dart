import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Utility for parsing JSON in background isolates to avoid UI thread blocking.
/// Use for large JSON payloads (home feeds, user profiles with many items, etc.)

/// Parse a JSON string in background isolate.
/// Returns the decoded Map that can be used with DTO.fromJson() on main thread.
Future<Map<String, dynamic>> parseJsonInBackground(String jsonString) async {
  if (jsonString.isEmpty) {
    return {};
  }
  return compute(_decodeJsonMap, jsonString);
}

/// Parse a JSON array string in background isolate.
/// Returns a list of Maps for DTO list conversion.
Future<List<Map<String, dynamic>>> parseJsonListInBackground(
    String jsonString) async {
  if (jsonString.isEmpty) {
    return [];
  }
  return compute(_decodeJsonList, jsonString);
}

/// Top-level function for compute() - decodes JSON to Map.
Map<String, dynamic> _decodeJsonMap(String jsonString) {
  final decoded = jsonDecode(jsonString);
  if (decoded is Map<String, dynamic>) {
    return decoded;
  }
  throw FormatException('Expected JSON object, got ${decoded.runtimeType}');
}

/// Top-level function for compute() - decodes JSON to List of Maps.
List<Map<String, dynamic>> _decodeJsonList(String jsonString) {
  final decoded = jsonDecode(jsonString);
  if (decoded is List) {
    return decoded.cast<Map<String, dynamic>>();
  }
  throw FormatException('Expected JSON array, got ${decoded.runtimeType}');
}

/// Parse and convert JSON to a DTO in background.
/// The fromJson function must be a top-level or static function.
///
/// Example:
/// ```dart
/// final dto = await parseAndConvertJson<RecipeDto>(
///   jsonString,
///   RecipeDto.fromJson,
/// );
/// ```
Future<T> parseAndConvertJson<T>(
  String jsonString,
  T Function(Map<String, dynamic>) fromJson,
) async {
  final map = await parseJsonInBackground(jsonString);
  // fromJson runs on main thread but is typically fast
  return fromJson(map);
}

/// Parse and convert a JSON array to a list of DTOs.
///
/// Example:
/// ```dart
/// final dtos = await parseAndConvertJsonList<RecipeDto>(
///   jsonString,
///   RecipeDto.fromJson,
/// );
/// ```
Future<List<T>> parseAndConvertJsonList<T>(
  String jsonString,
  T Function(Map<String, dynamic>) fromJson,
) async {
  final list = await parseJsonListInBackground(jsonString);
  // Map conversion runs on main thread but is typically fast
  return list.map((map) => fromJson(map)).toList();
}
