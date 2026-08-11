import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Universal storage service that works on both web and mobile platforms
abstract class StorageService {
  Future<String?> getString(String key);
  Future<void> setString(String key, String value);
  Future<void> remove(String key);
  Future<void> clear();
}

/// Web storage implementation using SharedPreferences
class WebStorageService implements StorageService {
  SharedPreferences? _prefs;

  Future<void> _ensurePrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  @override
  Future<String?> getString(String key) async {
    await _ensurePrefs();
    return _prefs!.getString(key);
  }

  @override
  Future<void> setString(String key, String value) async {
    await _ensurePrefs();
    await _prefs!.setString(key, value);
  }

  @override
  Future<void> remove(String key) async {
    await _ensurePrefs();
    await _prefs!.remove(key);
  }

  @override
  Future<void> clear() async {
    await _ensurePrefs();
    await _prefs!.clear();
  }
}

/// Mobile storage implementation using SharedPreferences (cross-platform)
class MobileStorageService implements StorageService {
  SharedPreferences? _prefs;

  Future<void> _ensurePrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  @override
  Future<String?> getString(String key) async {
    await _ensurePrefs();
    return _prefs!.getString(key);
  }

  @override
  Future<void> setString(String key, String value) async {
    await _ensurePrefs();
    await _prefs!.setString(key, value);
  }

  @override
  Future<void> remove(String key) async {
    await _ensurePrefs();
    await _prefs!.remove(key);
  }

  @override
  Future<void> clear() async {
    await _ensurePrefs();
    await _prefs!.clear();
  }
}

/// Factory to create the appropriate storage service based on platform
class StorageServiceFactory {
  static StorageService create() {
    if (kIsWeb) {
      return WebStorageService();
    } else {
      return MobileStorageService();
    }
  }
}

/// Simple in-memory storage, useful for tests.
class InMemoryStorageService implements StorageService {
  final Map<String, String> _map = {};

  @override
  Future<void> clear() async {
    _map.clear();
  }

  @override
  Future<String?> getString(String key) async {
    return _map[key];
  }

  @override
  Future<void> remove(String key) async {
    _map.remove(key);
  }

  @override
  Future<void> setString(String key, String value) async {
    _map[key] = value;
  }
}

/// Default storage service instance used across the app.
/// Tests can override this variable before pumping widgets.
StorageService storageService = StorageServiceFactory.create();
