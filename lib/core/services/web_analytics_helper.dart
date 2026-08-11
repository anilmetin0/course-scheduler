// Conditional import for js - WASM compatibility
import 'web_analytics_helper_stub.dart'
    if (dart.library.js_interop) 'web_analytics_helper_js.dart';

/// Web platformu için Firebase Analytics debug ve test yardımcıları
class WebAnalyticsHelper {
  /// Web'de gtag'ın yüklenip yüklenmediğini kontrol et
  static bool isGtagLoaded() {
    return WebAnalyticsHelperImpl.isGtagLoaded();
  }

  /// Web'de Firebase Analytics'in durumunu kontrol et
  static Map<String, dynamic> getAnalyticsStatus() {
    return WebAnalyticsHelperImpl.getAnalyticsStatus();
  }

  /// Manual test event gönder
  static void sendTestEvent() {
    WebAnalyticsHelperImpl.sendTestEvent();
  }
}
