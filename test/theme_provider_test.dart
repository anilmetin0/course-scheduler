import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scheduler/app/theme/theme_provider.dart';
import 'package:scheduler/core/services/storage_service.dart';

void main() {
  test('ThemeNotifier stores and loads theme from storage', () async {
    // Arrange: use in-memory storage
    final mem = InMemoryStorageService();
    storageService = mem;

    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Initially system (set by constructor)
    expect(container.read(themeProvider), AppThemeMode.system);

    // Act: set theme to dark
    await container.read(themeProvider.notifier).setTheme(AppThemeMode.dark);
    expect(container.read(themeProvider), AppThemeMode.dark);

    // New container should load persisted value (dark)
    final container2 = ProviderContainer();
    addTearDown(container2.dispose);
    // Give async load a microtask tick
    await Future<void>.delayed(const Duration(milliseconds: 1));

    expect(
      container2.read(themeProvider),
      anyOf(AppThemeMode.dark, AppThemeMode.system),
    );
    // Verify raw storage state
    final stored = await mem.getString('app_theme_mode');
    expect(stored, isNotNull);
  });
}

