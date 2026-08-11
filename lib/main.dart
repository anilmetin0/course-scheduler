import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:scheduler/features/schedule/pages/schedule_page.dart';
import 'package:scheduler/config/constants.dart';
import 'package:scheduler/app/theme/theme_provider.dart';
import 'package:scheduler/core/services/analytics_service.dart';
import 'package:scheduler/core/services/analytics_data_service.dart';
import 'package:scheduler/shared/widgets/analytics_consent_dialog.dart';
import 'package:scheduler/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase başlatma (sadece web platformu için)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Analytics servisini başlat
    await AnalyticsService().initialize();
  } catch (e) {
    // Silent error handling
  }

  runApp(const ProviderScope(child: SchedulerApp()));
}

class SchedulerApp extends StatelessWidget {
  const SchedulerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final themeMode = ref.watch(themeProvider);

        return MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,

          // Analytics Navigator Observer
          navigatorObservers: [
            if (AnalyticsService().observer != null)
              AnalyticsService().observer!,
          ],

          // Tema ayarları
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              brightness: Brightness.light,
            ),
            appBarTheme: AppBarTheme(
              centerTitle: true,
              elevation: 0,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            snackBarTheme: SnackBarThemeData(
              backgroundColor: Colors.grey[800],
              contentTextStyle: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              actionTextColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              brightness: Brightness.dark,
            ),
            appBarTheme: AppBarTheme(
              centerTitle: true,
              elevation: 0,
              backgroundColor: Colors.grey[900],
              foregroundColor: Colors.white,
            ),
            snackBarTheme: SnackBarThemeData(
              backgroundColor: Colors.grey[850],
              contentTextStyle: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              actionTextColor: AppColors.secondary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          themeMode: themeMode.flutterThemeMode,

          // Lokalizasyon ayarları
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('tr', 'TR'), Locale('en', 'US')],
          locale: const Locale('tr', 'TR'),

          // Ana sayfa
          home: const SchedulePageWithAnalytics(),
        );
      },
    );
  }
}

/// Analytics consent dialog ile birlikte ana sayfa
class SchedulePageWithAnalytics extends StatefulWidget {
  const SchedulePageWithAnalytics({super.key});

  @override
  State<SchedulePageWithAnalytics> createState() =>
      _SchedulePageWithAnalyticsState();
}

class _SchedulePageWithAnalyticsState extends State<SchedulePageWithAnalytics> {
  @override
  void initState() {
    super.initState();

    // Uygulama açılışında kullanıcı onayını kontrol et
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsConsentDialog.checkAndShowConsent(context);
      AnalyticsService().logAppOpen();
      AnalyticsDataService().logAppOpen();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const SchedulePage();
  }
}
