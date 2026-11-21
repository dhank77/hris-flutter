import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_antigravity_starter_pack/core/error/app_exception.dart';
import 'package:flutter_antigravity_starter_pack/core/network/api_guard.dart';
import 'package:flutter_antigravity_starter_pack/core/network/auth_interceptor.dart';
import 'package:flutter_antigravity_starter_pack/core/network/dio_provider.dart';
import 'package:flutter_antigravity_starter_pack/features/auth/data/models/auth_user.dart';

/// Hasil respons login beserta personal access token dari Laravel Sanctum.
typedef LoginResponse = ({AuthUser user, String accessToken});

/// Data source HTTP untuk fitur Auth (Laravel Sanctum).
class AuthApi {
  AuthApi(this._dio);

  final Dio _dio;

  Future<LoginResponse> login({
    required String email,
    required String password,
    String deviceName = 'flutter-hris',
  }) => guardApi(() async {
    final response = await _dio.post<Object?>(
      '/auth/login',
      data: {'email': email, 'password': password, 'device_name': deviceName},
      options: Options(extra: const {skipAuthKey: true}),
    );
    final json = asJsonObject(response.data);
    final accessToken = json['access_token'];
    final userJson = json['user'];
    if (accessToken is! String ||
        accessToken.isEmpty ||
        userJson is! Map<String, dynamic>) {
      throw const BadResponseException();
    }
    return (user: AuthUser.fromJson(userJson), accessToken: accessToken);
  });

  Future<LoginResponse> loginWithGoogle({
    String? idToken,
    String? accessToken,
    String deviceName = 'flutter-hris',
  }) => guardApi(() async {
    final response = await _dio.post<Object?>(
      '/auth/google',
      data: {
        if (idToken != null && idToken.isNotEmpty) 'id_token': idToken,
        if (accessToken != null && accessToken.isNotEmpty)
          'access_token': accessToken,
        'device_name': deviceName,
      },
      options: Options(extra: const {skipAuthKey: true}),
    );
    final json = asJsonObject(response.data);
    final sanctumToken = json['access_token'];
    final userJson = json['user'];
    if (sanctumToken is! String ||
        sanctumToken.isEmpty ||
        userJson is! Map<String, dynamic>) {
      throw const BadResponseException();
    }
    return (user: AuthUser.fromJson(userJson), accessToken: sanctumToken);
  });

  Future<AuthUser> fetchMe() => guardApi(() async {
    final response = await _dio.get<Object?>('/auth/me');
    final json = asJsonObject(response.data);
    final userJson = json['user'];
    return AuthUser.fromJson(
      userJson is Map<String, dynamic> ? userJson : json,
    );
  });

  Future<void> logout() => guardApi(() async {
    await _dio.post<Object?>('/auth/logout');
  });
}

final authApiProvider = Provider<AuthApi>(
  (ref) => AuthApi(ref.watch(dioProvider)),
);
