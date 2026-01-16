import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keys for consent storage
class ConsentKeys {
  static const String analyticsConsent = 'gdpr_analytics_consent';
  static const String consentTimestamp = 'gdpr_consent_timestamp';
  static const String consentVersion = 'gdpr_consent_version';
  static const String ccpaDoNotSell = 'ccpa_do_not_sell';
}

/// Current version of consent form - increment when consent requirements change
const String currentConsentVersion = '1.0.0';

/// State class for consent preferences
class ConsentState {
  final bool? analyticsConsent; // null = not yet decided
  final bool ccpaDoNotSell;
  final bool hasShownConsentBanner;
  final String? consentVersion;
  final bool isLoaded; // Whether preferences have been loaded from storage

  const ConsentState({
    this.analyticsConsent,
    this.ccpaDoNotSell = false,
    this.hasShownConsentBanner = false,
    this.consentVersion,
    this.isLoaded = false,
  });

  /// Only show consent banner after preferences are loaded AND consent is needed
  bool get needsConsentBanner =>
      isLoaded && (!hasShownConsentBanner || consentVersion != currentConsentVersion);

  ConsentState copyWith({
    bool? analyticsConsent,
    bool? ccpaDoNotSell,
    bool? hasShownConsentBanner,
    String? consentVersion,
    bool? isLoaded,
  }) {
    return ConsentState(
      analyticsConsent: analyticsConsent ?? this.analyticsConsent,
      ccpaDoNotSell: ccpaDoNotSell ?? this.ccpaDoNotSell,
      hasShownConsentBanner: hasShownConsentBanner ?? this.hasShownConsentBanner,
      consentVersion: consentVersion ?? this.consentVersion,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}

/// Notifier for managing consent preferences
class ConsentPreferencesNotifier extends StateNotifier<ConsentState> {
  ConsentPreferencesNotifier() : super(const ConsentState()) {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    final hasAnalyticsConsent = prefs.getBool(ConsentKeys.analyticsConsent);
    final ccpaDoNotSell = prefs.getBool(ConsentKeys.ccpaDoNotSell) ?? false;
    final consentVersion = prefs.getString(ConsentKeys.consentVersion);
    final hasTimestamp = prefs.getString(ConsentKeys.consentTimestamp) != null;

    state = ConsentState(
      analyticsConsent: hasAnalyticsConsent,
      ccpaDoNotSell: ccpaDoNotSell,
      hasShownConsentBanner: hasTimestamp,
      consentVersion: consentVersion,
      isLoaded: true, // Mark as loaded after reading from storage
    );

    // Apply analytics setting
    if (hasAnalyticsConsent != null) {
      await _applyAnalyticsConsent(hasAnalyticsConsent && !ccpaDoNotSell);
    }
  }

  /// Accept all tracking
  Future<void> acceptAll() async {
    await _saveConsent(analyticsConsent: true);
    state = state.copyWith(
      analyticsConsent: true,
      hasShownConsentBanner: true,
      consentVersion: currentConsentVersion,
    );
    await _applyAnalyticsConsent(true);
  }

  /// Reject all tracking
  Future<void> rejectAll() async {
    await _saveConsent(analyticsConsent: false);
    state = state.copyWith(
      analyticsConsent: false,
      hasShownConsentBanner: true,
      consentVersion: currentConsentVersion,
    );
    await _applyAnalyticsConsent(false);
  }

  /// Update analytics consent
  Future<void> setAnalyticsConsent(bool consent) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(ConsentKeys.analyticsConsent, consent);
    state = state.copyWith(analyticsConsent: consent);
    await _applyAnalyticsConsent(consent && !state.ccpaDoNotSell);
  }

  /// Update CCPA Do Not Sell preference
  Future<void> setCcpaDoNotSell(bool doNotSell) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(ConsentKeys.ccpaDoNotSell, doNotSell);
    state = state.copyWith(ccpaDoNotSell: doNotSell);

    // If user opts out of selling, disable analytics
    if (doNotSell) {
      await _applyAnalyticsConsent(false);
    } else if (state.analyticsConsent == true) {
      await _applyAnalyticsConsent(true);
    }
  }

  Future<void> _saveConsent({required bool analyticsConsent}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(ConsentKeys.analyticsConsent, analyticsConsent);
    await prefs.setString(
      ConsentKeys.consentTimestamp,
      DateTime.now().toIso8601String(),
    );
    await prefs.setString(ConsentKeys.consentVersion, currentConsentVersion);
  }

  Future<void> _applyAnalyticsConsent(bool enabled) async {
    // TODO: Re-enable when firebase_analytics is added back
    // await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(enabled);
  }
}

/// Provider for consent preferences
final consentPreferencesProvider =
    StateNotifierProvider<ConsentPreferencesNotifier, ConsentState>((ref) {
  return ConsentPreferencesNotifier();
});
