import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_antigravity_starter_pack/core/error/app_exception.dart';
import 'package:flutter_antigravity_starter_pack/core/network/api_guard.dart';
import 'package:flutter_antigravity_starter_pack/core/network/auth_interceptor.dart';
import 'package:flutter_antigravity_starter_pack/core/network/dio_provider.dart';
import 'package:flutter_antigravity_starter_pack/core/network/token_refresher.dart';
import 'package:flutter_antigravity_starter_pack/features/auth/data/models/auth_user.dart';

/// Hasil respons login beserta pasangan token dari server.
typedef LoginResponse = ({
  AuthUser user,
  String accessToken,
  String refreshToken,
});

/// Data source HTTP untuk fitur Auth (DummyJSON).
class AuthApi {
  AuthApi(this._dio);

  final Dio _dio;

  Future<LoginResponse> login({
    required String username,
    required String password,
  }) => guardApi(() async {
    final response = await _dio.post<Object?>(
      '/auth/login',
      data: {'username': username, 'password': password},
      options: Options(extra: const {skipAuthKey: true}),
    );
    final json = asJsonObject(response.data);
    final accessToken = json['accessToken'];
    final refreshToken = json['refreshToken'];
    if (accessToken is! String ||
        accessToken.isEmpty ||
        refreshToken is! String ||
        refreshToken.isEmpty) {
      throw const BadResponseException();
    }
    return (
      user: AuthUser.fromJson(json),
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  });

  Future<AuthUser> fetchMe() => guardApi(() async {
    final response = await _dio.get<Object?>('/auth/me');
    return AuthUser.fromJson(asJsonObject(response.data));
  });
}

/// Menukar refresh token DummyJSON dengan pasangan token baru.
/// Dipasang ke `tokenRefresherProvider` di `bootstrap.dart`.
Future<TokenPair?> refreshAuthTokens(Dio client, String refreshToken) async {
  final response = await client.post<Object?>(
    '/auth/refresh',
    data: {'refreshToken': refreshToken},
  );
  final data = response.data;
  if (data is! Map<String, dynamic>) return null;
  final access = data['accessToken'];
  final refresh = data['refreshToken'];
  if (access is! String || access.isEmpty) return null;
  return (
    accessToken: access,
    refreshToken: refresh is String && refresh.isNotEmpty
        ? refresh
        : refreshToken,
  );
}

final authApiProvider = Provider<AuthApi>(
  (ref) => AuthApi(ref.watch(dioProvider)),
);
