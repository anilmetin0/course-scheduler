// Web için Firebase konfigürasyonu
// Environment variables ile tamamen güvenli konfigürasyon
// Default value'lar yok - tüm değerler runtime'da environment'tan alınır

import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return web;
  }

  static FirebaseOptions get web {
    // Environment variables'ların varlığını kontrol et
    const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
    const appId = String.fromEnvironment('FIREBASE_APP_ID');
    const messagingSenderId = String.fromEnvironment(
      'FIREBASE_MESSAGING_SENDER_ID',
    );
    const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
    const authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
    const storageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
    const measurementId = String.fromEnvironment('FIREBASE_MEASUREMENT_ID');

    // Kritik değerlerin varlığını kontrol et
    if (apiKey.isEmpty || appId.isEmpty || projectId.isEmpty) {
      throw Exception(
        'Firebase konfigürasyonu eksik! '
        'Uygulama environment variables ile çalıştırılmalı. '
        'Detaylar için README.md dosyasını kontrol edin.',
      );
    }

    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: messagingSenderId,
      projectId: projectId,
      authDomain: authDomain,
      storageBucket: storageBucket,
      measurementId: measurementId,
    );
  }
}
