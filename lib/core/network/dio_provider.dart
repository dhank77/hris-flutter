import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_antigravity_starter_pack/core/config/env.dart';
import 'package:flutter_antigravity_starter_pack/core/logging/app_logger.dart';
import 'package:flutter_antigravity_starter_pack/core/network/auth_interceptor.dart';
import 'package:flutter_antigravity_starter_pack/core/network/redacting_log_interceptor.dart';
import 'package:flutter_antigravity_starter_pack/core/network/token_refresher.dart';
import 'package:flutter_antigravity_starter_pack/core/session/session_expiry.dart';
import 'package:flutter_antigravity_starter_pack/core/storage/token_storage.dart';

BaseOptions _baseOptions(Env env) => BaseOptions(
  baseUrl: env.apiBaseUrl,
  connectTimeout: const Duration(seconds: 10),
  receiveTimeout: const Duration(seconds: 15),
  sendTimeout: const Duration(seconds: 15),
  headers: {'Accept': 'application/json'},
  contentType: Headers.jsonContentType,
);

/// Satu instance Dio bersama untuk seluruh aplikasi.
///
/// `Provider` biasa (bukan autoDispose) → hidup selama aplikasi berjalan.
/// Widget TIDAK boleh membuat Dio sendiri; akses selalu lewat repository.
final dioProvider = Provider<Dio>((ref) {
  final env = ref.watch(envProvider);
  final logger = ref.watch(loggerProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  final tokenRefresher = ref.watch(tokenRefresherProvider);

  final dio = Dio(_baseOptions(env));
  final refreshClient = Dio(_baseOptions(env));

  dio.interceptors.add(
    AuthInterceptor(
      tokenStorage: tokenStorage,
      refreshClient: refreshClient,
      refreshTokens: tokenRefresher,
      // Dibaca saat dipanggil (bukan saat build) → tidak ada dependency cycle.
      onSessionExpired: () =>
          ref.read(sessionExpiryProvider.notifier).notifyExpired(),
    ),
  );
  if (env.enableHttpLogs) {
    final logInterceptor = RedactingLogInterceptor(logger);
    dio.interceptors.add(logInterceptor);
    refreshClient.interceptors.add(logInterceptor);
  }

  ref.onDispose(() {
    dio.close();
    refreshClient.close();
  });
  return dio;
});
