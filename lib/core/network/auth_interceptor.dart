import 'package:dio/dio.dart';

import 'package:flutter_antigravity_starter_pack/core/network/token_refresher.dart';
import 'package:flutter_antigravity_starter_pack/core/storage/token_storage.dart';

/// Kunci `RequestOptions.extra` untuk endpoint publik (mis. login) agar
/// tidak ditempeli header Authorization.
const skipAuthKey = 'skipAuth';
const _retriedKey = 'authRetried';

/// - Menambahkan `Authorization: Bearer <token>` ke setiap request.
/// - Saat 401, mencoba refresh token SATU kali lewat [TokenRefresher] lalu
///   mengulang request. Tanpa refresher (default boilerplate), 401 langsung
///   dianggap sesi berakhir.
/// - Bila refresh gagal, token dihapus dan [onSessionExpired] dipanggil.
///
/// [QueuedInterceptor] memproses request satu per satu, sehingga beberapa
/// request yang gagal bersamaan tidak memicu refresh berkali-kali.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required TokenStorage tokenStorage,
    required Dio refreshClient,
    required void Function() onSessionExpired,
    TokenRefresher? refreshTokens,
  }) : _tokenStorage = tokenStorage,
       _refreshClient = refreshClient,
       _onSessionExpired = onSessionExpired,
       _refresher = refreshTokens;

  final TokenStorage _tokenStorage;

  /// Dio terpisah TANPA interceptor ini, supaya refresh tidak berputar-putar.
  final Dio _refreshClient;
  final void Function() _onSessionExpired;
  final TokenRefresher? _refresher;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra[skipAuthKey] != true) {
      final token = await _tokenStorage.readAccessToken();
      if (token != null) options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final isUnauthorized = err.response?.statusCode == 401;
    final canRetry =
        options.extra[skipAuthKey] != true &&
        options.extra[_retriedKey] != true;

    if (!isUnauthorized || !canRetry) {
      handler.next(err);
      return;
    }

    final newAccessToken = await _refreshTokens();
    if (newAccessToken == null) {
      await _tokenStorage.clear();
      _onSessionExpired();
      handler.next(err);
      return;
    }

    try {
      options.extra[_retriedKey] = true;
      options.headers['Authorization'] = 'Bearer $newAccessToken';
      final response = await _refreshClient.fetch<dynamic>(options);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  /// Mengembalikan access token baru, atau `null` bila refresh gagal.
  Future<String?> _refreshTokens() async {
    final refresher = _refresher;
    if (refresher == null) return null;
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null) return null;
    try {
      final tokens = await refresher(_refreshClient, refreshToken);
      if (tokens == null) return null;
      await _tokenStorage.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
      return tokens.accessToken;
    } on DioException {
      return null;
    }
  }
}
