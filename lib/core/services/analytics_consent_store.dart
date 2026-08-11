import 'package:shared_preferences/shared_preferences.dart';

class AnalyticsConsentStore {
  static final AnalyticsConsentStore _instance =
      AnalyticsConsentStore._internal();
  factory AnalyticsConsentStore() => _instance;
  AnalyticsConsentStore._internal();

  static const String analyticsConsentKey = 'analytics_consent';

  bool? _cachedConsent;

  Future<bool> isGranted() async {
    if (_cachedConsent != null) return _cachedConsent!;
    final prefs = await SharedPreferences.getInstance();
    _cachedConsent = prefs.getBool(analyticsConsentKey) ?? false;
    return _cachedConsent!;
  }

  Future<void> setConsent(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(analyticsConsentKey, value);
    _cachedConsent = value;
  }

  void syncConsent(bool value) {
    _cachedConsent = value;
  }

  void clearCache() {
    _cachedConsent = null;
  }
}
