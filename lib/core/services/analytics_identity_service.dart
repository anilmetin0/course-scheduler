import 'dart:convert';
import 'dart:math';

import 'package:scheduler/core/services/storage_service.dart';

class AnalyticsIdentityService {
  static final AnalyticsIdentityService _instance =
      AnalyticsIdentityService._internal();
  factory AnalyticsIdentityService() => _instance;
  AnalyticsIdentityService._internal();

  static const String _anonymousIdKey = 'analytics_anonymous_id';

  String? _cachedId;

  Future<String> getOrCreateAnonymousId() async {
    if (_cachedId != null && _cachedId!.isNotEmpty) return _cachedId!;
    final existing = await storageService.getString(_anonymousIdKey);
    if (existing != null && existing.isNotEmpty) {
      _cachedId = existing;
      return existing;
    }

    final newId = _generateAnonymousId();
    await storageService.setString(_anonymousIdKey, newId);
    _cachedId = newId;
    return newId;
  }

  Future<void> reset() async {
    _cachedId = null;
    await storageService.remove(_anonymousIdKey);
  }

  String _generateAnonymousId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }
}
