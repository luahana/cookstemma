import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pairing_planet2_frontend/data/models/recipe/ingredient_dto.dart';

const String _prefKey = 'measurement_preference';

/// Provider for user's measurement preference.
/// Persisted to SharedPreferences.
final measurementPreferenceProvider =
    StateNotifierProvider<MeasurementPreferenceNotifier, MeasurementPreference>(
  (ref) => MeasurementPreferenceNotifier(),
);

class MeasurementPreferenceNotifier extends StateNotifier<MeasurementPreference> {
  MeasurementPreferenceNotifier() : super(_getDefaultFromLocale()) {
    _loadFromPrefs();
  }

  /// Get default preference based on device locale.
  /// US uses imperial (cups, oz), most other countries use metric.
  static MeasurementPreference _getDefaultFromLocale() {
    final locale = PlatformDispatcher.instance.locale;
    final countryCode = locale.countryCode?.toUpperCase();

    // US, Liberia, and Myanmar use imperial
    if (countryCode == 'US' || countryCode == 'LR' || countryCode == 'MM') {
      return MeasurementPreference.us;
    }
    // Everyone else uses metric
    return MeasurementPreference.metric;
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);

    if (saved != null) {
      state = MeasurementPreference.values.firstWhere(
        (e) => e.name == saved,
        orElse: () => _getDefaultFromLocale(),
      );
    }
  }

  Future<void> setPreference(MeasurementPreference preference) async {
    state = preference;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, preference.name);
  }
}

/// Extension to get display name for measurement preference.
extension MeasurementPreferenceDisplay on MeasurementPreference {
  String get displayName {
    switch (this) {
      case MeasurementPreference.metric:
        return 'Metric (g, ml)';
      case MeasurementPreference.us:
        return 'US (cups, oz)';
      case MeasurementPreference.original:
        return 'Original';
    }
  }

  String get displayNameKo {
    switch (this) {
      case MeasurementPreference.metric:
        return '미터법 (g, ml)';
      case MeasurementPreference.us:
        return '미국식 (컵, 온스)';
      case MeasurementPreference.original:
        return '원본 그대로';
    }
  }
}
