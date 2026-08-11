import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scheduler/config/constants.dart';
import 'package:scheduler/core/config/app_info.dart';
import 'package:scheduler/features/about/pages/about_page.dart';
import 'package:scheduler/shared/widgets/theme_switcher.dart';
import 'package:scheduler/shared/widgets/analytics_consent_dialog.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appVersion = ref.watch(appVersionProvider);
    final versionLabel = appVersion.maybeWhen(
      data: (version) => version,
      loading: () => 'Yükleniyor...',
      orElse: () => 'Bilinmiyor',
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Tema Ayarları
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Görünüm',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  const ThemeSwitcher(),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Gizlilik ve Veri Ayarları
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gizlilik ve Veri',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  const AnalyticsSettingsTile(),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Uygulama Bilgileri
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Uygulama Bilgileri',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Uygulama Adı'),
                    subtitle: Text(AppConstants.appName),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Versiyon'),
                    subtitle: Text(versionLabel),
                  ),
                  const Divider(height: 32),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('Hakkında'),
                    subtitle: const Text(
                      'Lisanslar, geliştirici ve daha fazlası',
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AboutPage()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
