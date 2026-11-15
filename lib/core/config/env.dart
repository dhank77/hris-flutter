import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Konfigurasi yang berbeda per lingkungan (dev/staging/prod).
///
/// Nilai dibaca dari `--dart-define` / `--dart-define-from-file`, contoh:
/// `flutter run --dart-define-from-file=config/dev.json`.
/// Jangan menaruh secret di sini: semua nilai dart-define ikut ter-bundle
/// ke dalam aplikasi dan bisa dibaca orang lain.
class Env {
  const Env({required this.apiBaseUrl, required this.enableHttpLogs});

  factory Env.fromEnvironment() => const Env(
    apiBaseUrl: String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://dummyjson.com',
    ),
    enableHttpLogs: bool.fromEnvironment(
      'ENABLE_HTTP_LOGS',
      defaultValue: kDebugMode,
    ),
  );

  final String apiBaseUrl;
  final bool enableHttpLogs;
}

final envProvider = Provider<Env>((ref) => Env.fromEnvironment());
