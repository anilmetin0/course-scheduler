import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scheduler/app/theme/theme_provider.dart';

class ThemeSwitcher extends ConsumerWidget {
  const ThemeSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider);
    final themeNotifier = ref.watch(themeProvider.notifier);

    return PopupMenuButton<AppThemeMode>(
      icon: Icon(
        currentTheme == AppThemeMode.light
            ? Icons.light_mode
            : currentTheme == AppThemeMode.dark
            ? Icons.dark_mode
            : Icons.auto_mode,
      ),
      onSelected: (AppThemeMode theme) {
        themeNotifier.setTheme(theme);
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<AppThemeMode>>[
        const PopupMenuItem<AppThemeMode>(
          value: AppThemeMode.light,
          child: Row(
            children: [
              Icon(Icons.light_mode),
              SizedBox(width: 8),
              Text('Aydınlık Tema'),
            ],
          ),
        ),
        const PopupMenuItem<AppThemeMode>(
          value: AppThemeMode.dark,
          child: Row(
            children: [
              Icon(Icons.dark_mode),
              SizedBox(width: 8),
              Text('Karanlık Tema'),
            ],
          ),
        ),
        const PopupMenuItem<AppThemeMode>(
          value: AppThemeMode.system,
          child: Row(
            children: [
              Icon(Icons.auto_mode),
              SizedBox(width: 8),
              Text('Sistem Teması'),
            ],
          ),
        ),
      ],
    );
  }
}
