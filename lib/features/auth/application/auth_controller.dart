import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_antigravity_starter_pack/app/theme/app_tokens.dart';
import 'package:flutter_antigravity_starter_pack/core/session/session_expiry.dart';
import 'package:flutter_antigravity_starter_pack/features/auth/data/auth_repository.dart';
import 'package:flutter_antigravity_starter_pack/features/auth/data/models/auth_user.dart';

/// Durasi minimum splash screen saat memulihkan sesi awal.
/// Dapat di-override menjadi [Duration.zero] pada unit test yang tidak
/// menguji timer splash.
final splashDelayProvider = Provider<Duration>((ref) => AppDurations.splash);

/// State sesi pengguna di seluruh aplikasi (`null` berarti belum login).
///
/// Tidak memakai `autoDispose` agar status autentikasi bertahan selama
/// aplikasi berjalan dan bisa diamati oleh router guard.
class AuthController extends AsyncNotifier<AuthUser?> {
  @override
  Future<AuthUser?> build() async {
    ref.listen(sessionExpiryProvider, (_, _) {
      state = const AsyncData(null);
    });
    final delay = ref.watch(splashDelayProvider);
    final restoreFuture = ref.watch(authRepositoryProvider).restoreSession();
    if (delay > Duration.zero) {
      await Future.delayed(delay);
    }
    return restoreFuture;
  }

  Future<void> login({required String email, required String password}) async {
    final user = await ref
        .read(authRepositoryProvider)
        .login(email: email, password: password);
    if (!ref.mounted) return;
    state = AsyncData(user);
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    if (!ref.mounted) return;
    state = const AsyncData(null);
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, AuthUser?>(
  AuthController.new,
);
