import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Konfigurasi yang berbeda per lingkungan (dev/staging/prod).
///
/// Nilai dibaca dari `--dart-define` / `--dart-define-from-file`, contoh:
/// `flutter run --dart-define-from-file=config/dev.json`.
/// Jangan menaruh secret di sini: semua nilai dart-define ikut ter-bundle
/// ke dalam aplikasi dan bisa dibaca orang lain.
class Env {
  const Env({
    required this.apiBaseUrl,
    required this.enableHttpLogs,
    this.googleClientId = '',
    this.googleServerClientId = '',
  });

  factory Env.fromEnvironment() {
    const defaultUrl = 'http://127.0.0.1:8000/api';
    const rawUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: defaultUrl,
    );
    final apiBaseUrl =
        (rawUrl.isEmpty ||
            rawUrl.contains('dummyjson.com') ||
            rawUrl.contains('ngrok-free.app'))
        ? defaultUrl
        : rawUrl;

    return Env(
      apiBaseUrl: apiBaseUrl,
      enableHttpLogs: const bool.fromEnvironment(
        'ENABLE_HTTP_LOGS',
        defaultValue: kDebugMode,
      ),
      googleClientId: const String.fromEnvironment(
        'GOOGLE_CLIENT_ID',
        defaultValue:
            '606874341263-g023t9jdgigb9abmr8v3n85u19tss46p.apps.googleusercontent.com',
      ),
      googleServerClientId: const String.fromEnvironment(
        'GOOGLE_SERVER_CLIENT_ID',
        defaultValue:
            '606874341263-ate3jcvcfugol5gvv9phn7egi9pfl97n.apps.googleusercontent.com',
      ),
    );
  }

  final String apiBaseUrl;
  final bool enableHttpLogs;
  final String googleClientId;
  final String googleServerClientId;
}

final envProvider = Provider<Env>((ref) => Env.fromEnvironment());
