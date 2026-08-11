import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/analytics_service.dart';

/// Global function to show analytics consent dialog
Future<void> showAnalyticsConsentDialog(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  final hasShownConsent = prefs.getBool('analytics_consent_shown') ?? false;

  if (!hasShownConsent && context.mounted) {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AnalyticsConsentDialog(),
    );
  }
}

/// Analytics kullanıcı onayı için dialog widget
class AnalyticsConsentDialog extends StatelessWidget {
  const AnalyticsConsentDialog({super.key});

  /// Kullanıcı onayını kontrol et ve gerekirse dialog göster
  static Future<void> checkAndShowConsent(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final hasShownConsent = prefs.getBool('analytics_consent_shown') ?? false;

    if (!hasShownConsent && context.mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AnalyticsConsentDialog(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.analytics_outlined, color: Colors.blue),
          SizedBox(width: 8),
          Text('Uygulama İyileştirmeleri'),
        ],
      ),
      content: const SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Uygulamayı geliştirmek için anonim kullanım verilerini toplamak istiyoruz.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 16),
            Text('Toplanan veriler (onayınızla):'),
            SizedBox(height: 8),
            _DataItem(
              icon: Icons.screen_search_desktop,
              title: 'Sayfa görüntülemeleri',
              description: 'Hangi özelliklerin kullanıldığı',
            ),
            _DataItem(
              icon: Icons.touch_app,
              title: 'Kullanıcı etkileşimleri',
              description: 'Buton tıklamaları ve özellik kullanımı',
            ),
            _DataItem(
              icon: Icons.table_chart_outlined,
              title: 'Ders istatistikleri',
              description:
                  'Ders ekleme/çıkarma, çakışmalar ve birlikte seçilen dersler',
            ),
            _DataItem(
              icon: Icons.save_outlined,
              title: 'Program kayıtları',
              description: 'Kaydedilen programların ders dağılımı',
            ),
            _DataItem(
              icon: Icons.feedback_outlined,
              title: 'Geri bildirimler',
              description: 'Paylaştığınız notlar anonim olarak kaydedilir',
            ),
            _DataItem(
              icon: Icons.bug_report,
              title: 'Hata raporları',
              description: 'Uygulama hatalarını tespit etmek için',
            ),
            _DataItem(
              icon: Icons.speed,
              title: 'Performans verileri',
              description: 'Uygulama hızını optimize etmek için',
            ),
            SizedBox(height: 16),
            Text(
              '• Kişisel veri toplanmaz, kimlik bilgisi istenmez\n'
              '• Cihazınıza özel anonim bir ID ile veriler ilişkilendirilir\n'
              '• Cihazınıza özel anonim bir ID ile veriler ilişkilendirilir\n'
              '• Veriler anonim/özet olarak Firebase Analytics ve Firestore\'da saklanır\n'
              '• İstediğiniz zaman kapatabilirsiniz\n'
              '• KVKK kapsamında açık rıza esaslıdır',
              style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => _handleConsent(context, false),
          child: const Text('Hayır, Teşekkürler'),
        ),
        ElevatedButton(
          onPressed: () => _handleConsent(context, true),
          child: const Text('Kabul Ediyorum'),
        ),
      ],
    );
  }

  Future<void> _handleConsent(BuildContext context, bool consent) async {
    // Kullanıcı tercihini kaydet
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('analytics_consent_shown', true);

    // Analytics servisine bildir
    await AnalyticsService().setAnalyticsConsent(consent);

    if (context.mounted) {
      Navigator.of(context).pop();

      // Kullanıcıya teşekkür mesajı
      if (consent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Teşekkürler! Bu, uygulamayı geliştirmemize yardımcı olacak.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}

class _DataItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _DataItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Ayarlar sayfası için analytics toggle widget
class AnalyticsSettingsTile extends StatefulWidget {
  const AnalyticsSettingsTile({super.key});

  @override
  State<AnalyticsSettingsTile> createState() => _AnalyticsSettingsTileState();
}

class _AnalyticsSettingsTileState extends State<AnalyticsSettingsTile> {
  bool _analyticsEnabled = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalyticsPreference();
  }

  Future<void> _loadAnalyticsPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _analyticsEnabled = prefs.getBool('analytics_consent') ?? false;
      _loading = false;
    });
  }

  Future<void> _toggleAnalytics(bool value) async {
    setState(() {
      _loading = true;
    });

    await AnalyticsService().setAnalyticsConsent(value);

    setState(() {
      _analyticsEnabled = value;
      _loading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'Analytics etkinleştirildi'
                : 'Analytics devre dışı bırakıldı',
          ),
          backgroundColor: value ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const ListTile(
        leading: Icon(Icons.analytics_outlined),
        title: Text('Kullanım Analitikleri'),
        trailing: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return ListTile(
      leading: const Icon(Icons.analytics_outlined),
      title: const Text('Kullanım Analitikleri'),
      subtitle: Text(
        _analyticsEnabled
            ? 'Anonim kullanım ve ders istatistikleri toplanıyor'
            : 'Kullanım verileri toplanmıyor',
      ),
      trailing: Switch(value: _analyticsEnabled, onChanged: _toggleAnalytics),
    );
  }
}
