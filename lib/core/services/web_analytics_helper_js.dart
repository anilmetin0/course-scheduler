import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:flutter/foundation.dart';

/// JavaScript implementation - Full web support
class WebAnalyticsHelperImpl {
  static JSObject get _context => globalContext;

  static bool isGtagLoaded() {
    if (!kIsWeb) return false;

    try {
      return _context.has('gtag');
    } catch (e) {
      return false;
    }
  }

  static Map<String, dynamic> getAnalyticsStatus() {
    if (!kIsWeb) {
      return {'error': 'Not web platform'};
    }

    try {
      final context = _context;
      return {
        'platform': 'js_interop',
        'gtag_loaded': context.has('gtag'),
        'dataLayer_exists': context.has('dataLayer'),
        'firebase_loaded': context.has('firebase'),
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static void sendTestEvent() {
    if (!kIsWeb) return;

    try {
      if (isGtagLoaded()) {
        final params = JSObject();
        params['test_source'] = 'web_helper'.toJS;
        params['timestamp'] = DateTime.now().toIso8601String().toJS;
        _context.callMethodVarArgs<JSAny?>(
          'gtag'.toJS,
          <JSAny?>['event'.toJS, 'web_manual_test'.toJS, params],
        );
      }
    } catch (e) {
      // Silent error handling for production
    }
  }
}
