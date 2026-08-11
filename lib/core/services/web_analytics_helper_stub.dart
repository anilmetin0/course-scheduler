/// Stub implementation - WASM compatibility
class WebAnalyticsHelperImpl {
  static bool isGtagLoaded() {
    return false;
  }

  static Map<String, dynamic> getAnalyticsStatus() {
    return {
      'platform': 'wasm',
      'gtag_loaded': false,
      'note': 'Limited web API support in WASM',
    };
  }

  static void sendTestEvent() {
    // WASM mode - no operation
  }
}
