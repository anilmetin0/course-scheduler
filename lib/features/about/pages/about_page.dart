import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scheduler/config/constants.dart';
import 'package:scheduler/core/config/app_info.dart';
import 'package:scheduler/features/datasets/providers/asset_datasets_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:scheduler/shared/widgets/analytics_consent_dialog.dart';

/// Özelleştirilebilir Hakkında Sayfası
/// Buraya gelecekte lisanslar, katkıda bulunanlar, değişiklik listesi vb. eklenebilir.
class AboutPage extends ConsumerWidget {
  const AboutPage({super.key});

  static const String developerName = 'Anıl Metin';
  static const String developerGithubUrl = 'https://github.com/anilmetin0';
  static const String developerLinkedInUrl =
      'https://www.linkedin.com/in/anilmetin0/';
  static const String projectRepoUrl =
      'https://github.com/anilmetin0/course-scheduler';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appVersion = ref.watch(appVersionProvider);
    final versionLabel = appVersion.maybeWhen(
      data: (version) => 'v$version',
      loading: () => 'v...',
      orElse: () => 'v?',
    );
    final datasetUpdateLabel = ref.watch(assetDatasetsProvider).when(
          data: (assets) => datasetUpdateLabelFromAssets(assets),
          loading: () => 'Yükleniyor...',
          error: (error, stackTrace) => 'Bilinmiyor',
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Hakkında')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/logo/logo.png',
                  width: 72,
                  height: 72,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppConstants.appName,
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      versionLabel,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ders programlarını daha hızlı ve kolay oluşturmanıza yardımcı olmak için tasarlanmış açık kaynak bir uygulama.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Geliştirici'),
                  subtitle: const Text(developerName),
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.code),
                  title: const Text('GitHub'),
                  subtitle: const Text(developerGithubUrl),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _launch(developerGithubUrl),
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.business_center_outlined),
                  title: const Text('LinkedIn'),
                  subtitle: const Text(developerLinkedInUrl),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _launch(developerLinkedInUrl),
                ),
                const Divider(height: 0),
                ListTile(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  leading: const Icon(Icons.folder_open),
                  title: const Text('Proje Deposu'),
                  subtitle: const Text(projectRepoUrl),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _launch(projectRepoUrl),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.privacy_tip_outlined,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Gizlilik ve Veri',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 0),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: AnalyticsSettingsTile(),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Uygulama kullanımını iyileştirmek için anonim kullanım '
                    'verileri ve ders istatistikleri toplayabiliriz. '
                    'Geri bildirim gönderdiğinizde mesajınız kaydedilecektir; '
                    'kişisel bilgi yazmamanızı öneririz. '
                    'Analytics özelliğini istediğiniz zaman kapatabilirsiniz.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.update),
                  title: const Text('Veri Seti Güncelleme Tarihi'),
                  subtitle: Text(datasetUpdateLabel),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              '© ${DateTime.now().year} $developerName',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  static Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
