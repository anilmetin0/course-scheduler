import 'package:flutter_test/flutter_test.dart';
import 'package:scheduler/core/services/web_analytics_helper.dart';

void main() {
  test('WebAnalyticsHelper stub returns default status', () {
    expect(WebAnalyticsHelper.isGtagLoaded(), isFalse);

    final status = WebAnalyticsHelper.getAnalyticsStatus();
    expect(status['platform'], 'wasm');
    expect(status['gtag_loaded'], isFalse);
  });
}
