import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_antigravity_starter_pack/core/error/app_exception.dart';
import 'package:flutter_antigravity_starter_pack/core/storage/token_storage.dart';
import 'package:flutter_antigravity_starter_pack/features/auth/data/auth_api.dart';
import 'package:flutter_antigravity_starter_pack/features/auth/data/models/auth_user.dart';

/// Pintu masuk data Auth untuk layer aplikasi.
/// Mengkoordinasikan API autentikasi Laravel Sanctum dan penyimpanan token terenkripsi.
class AuthRepository {
  AuthRepository(this._api, this._tokenStorage);

  final AuthApi _api;
  final TokenStorage _tokenStorage;

  /// Memulihkan sesi dari token tersimpan. Mengembalikan `null` bila belum
  /// login atau token sudah tidak valid.
  Future<AuthUser?> restoreSession() async {
    final token = await _tokenStorage.readAccessToken();
    if (token == null || token.isEmpty) return null;
    try {
      return await _api.fetchMe();
    } on UnauthorizedException {
      await _tokenStorage.clear();
      return null;
    }
  }

  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final result = await _api.login(email: email, password: password);
    await _tokenStorage.saveTokens(
      accessToken: result.accessToken,
      refreshToken: '',
    );
    return result.user;
  }

  Future<void> logout() async {
    final token = await _tokenStorage.readAccessToken();
    if (token != null && token.isNotEmpty) {
      try {
        await _api.logout();
      } on AppException {
        // Tetap hapus token lokal meskipun pencabutan token di server gagal.
      }
    }
    await _tokenStorage.clear();
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(authApiProvider),
    ref.watch(tokenStorageProvider),
  ),
);
