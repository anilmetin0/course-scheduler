import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:scheduler/core/services/storage_service.dart';

part 'theme_provider.g.dart';

enum AppThemeMode { light, dark, system }

extension AppThemeModeExtension on AppThemeMode {
  ThemeMode get flutterThemeMode {
    switch (this) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  String get displayName {
    switch (this) {
      case AppThemeMode.light:
        return 'Açık';
      case AppThemeMode.dark:
        return 'Koyu';
      case AppThemeMode.system:
        return 'Sistem';
    }
  }
}

@Riverpod(keepAlive: true)
class Theme extends _$Theme {
  static const String _themeKey = 'app_theme_mode';

  @override
  AppThemeMode build() {
    _loadTheme();
    return AppThemeMode.system;
  }

  final StorageService _storage = storageService;

  ThemeMode get flutterThemeMode => state.flutterThemeMode;

  Future<void> _loadTheme() async {
    try {
      final themeIndex = await _storage.getString(_themeKey);
      if (themeIndex != null) {
        final index = int.tryParse(themeIndex) ?? AppThemeMode.system.index;
        if (index >= 0 && index < AppThemeMode.values.length) {
          state = AppThemeMode.values[index];
        }
      }
    } catch (e) {
      // Hata durumunda sistem temasını kullan
      state = AppThemeMode.system;
    }
  }

  Future<void> setTheme(AppThemeMode theme) async {
    try {
      await _storage.setString(_themeKey, theme.index.toString());
      state = theme;
    } catch (e) {
      // Hata durumunda state'i değiştirme
    }
  }
}
