import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:flutter_antigravity_starter_pack/core/config/env.dart';
import 'package:flutter_antigravity_starter_pack/core/error/app_exception.dart';

/// Kredensial hasil autentikasi Google Sign-In di sisi perangkat.
typedef GoogleAuthTokens = ({String? idToken, String? accessToken});

/// Kontrak layanan Google Sign-In agar mudah dipalsukan di dalam unit/widget test.
abstract interface class GoogleAuthService {
  /// Memicu dialog pilih akun Google dan mengembalikan token untuk diverifikasi
  /// ke backend Laravel. Melempar [CancelledException] bila dibatalkan pengguna.
  Future<GoogleAuthTokens> signIn();

  /// Memutus sesi Google lokal saat pengguna keluar dari aplikasi.
  Future<void> signOut();
}

/// Implementasi [GoogleAuthService] berbasis plugin resmi `google_sign_in`.
class PluginGoogleAuthService implements GoogleAuthService {
  PluginGoogleAuthService({required Env env, GoogleSignIn? googleSignIn})
    : _env = env,
      _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final Env _env;
  final GoogleSignIn _googleSignIn;
  Future<void>? _initFuture;

  Future<void> _ensureInitialized() {
    return _initFuture ??= _googleSignIn.initialize(
      clientId: _env.googleClientId.isEmpty ? null : _env.googleClientId,
      serverClientId: _env.googleServerClientId.isEmpty
          ? null
          : _env.googleServerClientId,
    );
  }

  @override
  Future<GoogleAuthTokens> signIn() async {
    try {
      await _ensureInitialized();
      final account = await _googleSignIn.authenticate(
        scopeHint: const ['email', 'profile', 'openid'],
      );
      final idToken = account.authentication.idToken;
      String? accessToken;
      if (idToken == null || idToken.isEmpty) {
        final authz = await account.authorizationClient.authorizeScopes(const [
          'email',
          'profile',
          'openid',
        ]);
        accessToken = authz.accessToken;
      }
      if ((idToken == null || idToken.isEmpty) &&
          (accessToken == null || accessToken.isEmpty)) {
        throw const UnauthorizedException(
          'Tidak dapat memperoleh token dari akun Google.',
        );
      }
      return (idToken: idToken, accessToken: accessToken);
    } on GoogleSignInException catch (error) {
      throw _mapGoogleException(error);
    } on AppException {
      rethrow;
    } catch (_) {
      throw const UnknownException('Gagal masuk dengan Google.');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _ensureInitialized();
      await _googleSignIn.signOut();
    } catch (_) {
      // Abaikan kegagalan sign out lokal Google agar proses logout aplikasi tetap tuntas.
    }
  }

  AppException _mapGoogleException(GoogleSignInException error) {
    return switch (error.code) {
      GoogleSignInExceptionCode.canceled ||
      GoogleSignInExceptionCode.interrupted => const CancelledException(
        'Login Google dibatalkan.',
      ),
      GoogleSignInExceptionCode.clientConfigurationError ||
      GoogleSignInExceptionCode
          .providerConfigurationError => const ServerException(
        'Konfigurasi Google Sign-In belum lengkap. Pastikan GOOGLE_SERVER_CLIENT_ID / OAuth Client sudah diatur.',
      ),
      _ => UnauthorizedException(
        error.description?.isNotEmpty == true
            ? 'Gagal masuk dengan Google: ${error.description}'
            : 'Gagal masuk dengan Google. Silakan coba lagi.',
      ),
    };
  }
}

final googleAuthServiceProvider = Provider<GoogleAuthService>(
  (ref) => PluginGoogleAuthService(env: ref.watch(envProvider)),
);
