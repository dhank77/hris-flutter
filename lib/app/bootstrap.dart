import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_antigravity_starter_pack/core/logging/app_logger.dart';
import 'package:flutter_antigravity_starter_pack/core/logging/provider_logger.dart';
import 'package:flutter_antigravity_starter_pack/core/network/token_refresher.dart';
import 'package:flutter_antigravity_starter_pack/core/riverpod/retry_policy.dart';
import 'package:flutter_antigravity_starter_pack/core/storage/preferences.dart';
import 'package:flutter_antigravity_starter_pack/features/auth/data/auth_api.dart';

/// Titik awal aplikasi. Semua inisialisasi yang harus selesai SEBELUM UI
/// pertama digambar dikumpulkan di sini, sehingga `main.dart` tetap satu baris.
///
/// Tambahkan inisialisasi baru (Firebase, database lokal, dsb.) di bagian
/// "Dependensi async", lalu inject lewat `overrides`.
Future<void> bootstrap(Widget Function() builder) async {
  WidgetsFlutterBinding.ensureInitialized();

  final logger = createAppLogger();

  // Error yang tidak tertangkap: widget/framework dan async (zona root).
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    logger.e(
      'Flutter error',
      error: details.exception,
      stackTrace: details.stack,
    );
  };
  WidgetsBinding.instance.platformDispatcher.onError = (error, stackTrace) {
    logger.e('Uncaught error', error: error, stackTrace: stackTrace);
    return true;
  };

  // --- Dependensi async ---------------------------------------------------
  final preferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      retry: appRetryPolicy,
      observers: [ProviderLogger(logger)],
      overrides: [
        loggerProvider.overrideWithValue(logger),
        sharedPreferencesProvider.overrideWithValue(preferences),
        tokenRefresherProvider.overrideWithValue(refreshAuthTokens),
      ],
      child: builder(),
    ),
  );
}
