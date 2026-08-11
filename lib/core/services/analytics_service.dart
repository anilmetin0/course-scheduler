import 'dart:async';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:scheduler/core/config/app_info.dart';
import 'package:scheduler/core/services/analytics_consent_store.dart';
import 'package:scheduler/core/services/analytics_identity_service.dart';

/// Firebase Analytics servisi - güvenli ve optimize edilmiş
/// Kullanıcı onayı ve performans odaklı tasarım
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  FirebaseAnalytics? _analytics;
  FirebaseAnalyticsObserver? _observer;
  bool _isInitialized = false;
  bool _analyticsEnabled = false;

  final AnalyticsConsentStore _consentStore = AnalyticsConsentStore();
  final AnalyticsIdentityService _identityService = AnalyticsIdentityService();

  /// Analytics servisi başlatılmış mı?
  bool get isInitialized => _isInitialized;

  /// Analytics etkin mi?
  bool get isEnabled => _analyticsEnabled && _isInitialized;

  /// Firebase Analytics observer'ı (Navigator için)
  FirebaseAnalyticsObserver? get observer => _observer;

  /// Analytics servisini başlat
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _analytics = FirebaseAnalytics.instance;
      _observer = FirebaseAnalyticsObserver(analytics: _analytics!);

      // Kullanıcı onayını kontrol et
      await _checkAnalyticsConsent();

      // Analytics'i kullanıcı onayına göre etkinleştir
      await _analytics!.setAnalyticsCollectionEnabled(_analyticsEnabled);

      _isInitialized = true;

      if (_analyticsEnabled) {
        await _setDefaultParameters();
        final anonId = await _identityService.getOrCreateAnonymousId();
        await setUserId(anonId);
        await logEvent('app_initialization', {
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      _isInitialized = false;
    }
  }

  /// Kullanıcı onayını kontrol et
  Future<void> _checkAnalyticsConsent() async {
    _analyticsEnabled = await _consentStore.isGranted();
  }

  /// Kullanıcı analytics onayını ayarla
  Future<void> setAnalyticsConsent(bool consent) async {
    await _consentStore.setConsent(consent);
    _analyticsEnabled = consent;

    if (_analytics != null) {
      await _analytics!.setAnalyticsCollectionEnabled(consent);
      if (consent) {
        final anonId = await _identityService.getOrCreateAnonymousId();
        await setUserId(anonId);
        await _setDefaultParameters();
      } else {
        await setUserId(null);
      }
    }
  }

  /// Varsayılan parametreleri ayarla
  Future<void> _setDefaultParameters() async {
    if (!isEnabled) return;

    try {
      final appVersion = await AppInfo.version;
      // Firebase Analytics'te varsayılan parametreler için user properties kullanılır
      await setUserProperty(name: 'app_version', value: appVersion);
      await setUserProperty(
        name: 'platform',
        value: defaultTargetPlatform.name,
      );
      await setUserProperty(name: 'debug_mode', value: kDebugMode.toString());
    } catch (e) {
      // Silent error handling
    }
  }

  /// Ekran görünümü kaydet
  Future<void> logScreenView(String screenName) async {
    if (!_analyticsEnabled || _analytics == null) {
      return;
    }

    try {
      await _analytics!.logEvent(
        name: 'screen_view',
        parameters: {'screen_name': screenName},
      );
    } catch (e) {
      // Silent error handling
    }
  }

  /// Event kaydet
  Future<void> logEvent(String name, [Map<String, Object>? parameters]) async {
    if (!_analyticsEnabled || _analytics == null) {
      return;
    }

    try {
      await _analytics!.logEvent(name: name, parameters: parameters);
    } catch (e) {
      // Silent error handling
    }
  }

  /// Kullanıcı özelliklerini ayarla
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    if (!isEnabled) return;

    try {
      await _analytics!.setUserProperty(
        name: _sanitizePropertyName(name),
        value: value,
      );
    } catch (e) {
      // Silent error handling
    }
  }

  /// Kullanıcı ID'sini ayarla
  Future<void> setUserId(String? userId) async {
    if (!isEnabled) return;

    try {
      await _analytics!.setUserId(id: userId);
    } catch (e) {
      // Silent error handling
    }
  }

  // Uygulama yaşam döngüsü olayları

  /// Uygulama açılışı
  Future<void> logAppOpen() async {
    await logEvent('app_open');
  }

  /// Ders programı oluşturma
  Future<void> logScheduleCreated({
    int? courseCount,
    String? semesterType,
  }) async {
    final parameters = <String, Object>{};
    if (courseCount != null) parameters['course_count'] = courseCount;
    if (semesterType != null) parameters['semester_type'] = semesterType;

    await logEvent(
      'schedule_created',
      parameters.isNotEmpty ? parameters : null,
    );
  }

  /// Ders programı dışa aktarma
  Future<void> logScheduleExported({
    required String format,
    int? courseCount,
  }) async {
    final parameters = <String, Object>{'export_format': format};
    if (courseCount != null) parameters['course_count'] = courseCount;

    await logEvent('schedule_exported', parameters);
  }

  /// Ders ekleme
  Future<void> logCourseAdded({
    String? courseCode,
    String? courseName,
    String? courseSection,
  }) async {
    final parameters = <String, Object>{};
    if (courseCode != null) parameters['course_code'] = courseCode;
    if (courseName != null) parameters['course_name'] = courseName;
    if (courseSection != null) parameters['course_section'] = courseSection;
    if (courseCode != null) {
      final key =
          courseSection != null ? '$courseCode-$courseSection' : courseCode;
      parameters['course_key'] = key;
    }

    await logEvent('course_added', parameters.isNotEmpty ? parameters : null);
  }

  /// Ders çıkarma
  Future<void> logCourseRemoved({
    String? courseCode,
    String? courseName,
    String? courseSection,
  }) async {
    final parameters = <String, Object>{};
    if (courseCode != null) parameters['course_code'] = courseCode;
    if (courseName != null) parameters['course_name'] = courseName;
    if (courseSection != null) parameters['course_section'] = courseSection;
    if (courseCode != null) {
      final key =
          courseSection != null ? '$courseCode-$courseSection' : courseCode;
      parameters['course_key'] = key;
    }

    await logEvent('course_removed', parameters.isNotEmpty ? parameters : null);
  }

  /// Çakışma tespit edildi
  Future<void> logConflictDetected({
    int? conflictCount,
    String? conflictType,
  }) async {
    final parameters = <String, Object>{};
    if (conflictCount != null) parameters['conflict_count'] = conflictCount;
    if (conflictType != null) parameters['conflict_type'] = conflictType;

    await logEvent(
      'conflict_detected',
      parameters.isNotEmpty ? parameters : null,
    );
  }

  /// Hata kaydetme
  Future<void> logError({
    required String errorType,
    required String errorMessage,
    String? stackTrace,
  }) async {
    final parameters = <String, Object>{
      'error_type': errorType,
      'error_message': errorMessage,
    };
    if (stackTrace != null) {
      parameters['stack_trace'] = stackTrace.substring(
        0,
        stackTrace.length > 100 ? 100 : stackTrace.length,
      );
    }

    await logEvent('app_error', parameters);
  }

  /// Özellik adını temizle
  String _sanitizePropertyName(String name) {
    // Firebase user property kuralları: alfanumerik ve alt çizgi, max 24 karakter
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]'), '_')
        .substring(0, name.length > 24 ? 24 : name.length);
  }

  /// Analytics verilerini temizle (GDPR uyumluluğu için)
  Future<void> resetAnalyticsData() async {
    if (!isEnabled) return;

    try {
      await _analytics!.resetAnalyticsData();
    } catch (e) {
      // Silent error handling
    }
  }
}
