import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_antigravity_starter_pack/app/router/app_routes.dart';
import 'package:flutter_antigravity_starter_pack/features/auth/data/models/auth_user.dart';

/// Fungsi murni untuk menentukan redirect berdasarkan status autentikasi.
/// Mudah diuji secara unit test tanpa perlu membuat `GoRouter`.
String? resolveAuthRedirect({
  required AsyncValue<AuthUser?> authState,
  required String location,
  String? from,
}) {
  final isSplash = location == AppRoutes.splash;
  final isLoggingIn = location == AppRoutes.login;

  // Selama proses restore session masih berjalan, tahan pengguna di halaman
  // splash agar halaman yang butuh autentikasi (seperti Home) tidak sempat
  // ter-render lebih dulu.
  if (authState.isLoading) {
    if (isSplash) return null;
    if (location == AppRoutes.home || isLoggingIn) return AppRoutes.splash;
    return Uri(
      path: AppRoutes.splash,
      queryParameters: {'from': location},
    ).toString();
  }

  final isAuthenticated = authState.asData?.value != null;
  final hasValidFrom =
      from != null &&
      from.startsWith('/') &&
      from != AppRoutes.login &&
      from != AppRoutes.splash;

  if (!isAuthenticated) {
    if (isLoggingIn) return null;
    if (isSplash) {
      if (hasValidFrom) {
        return Uri(
          path: AppRoutes.login,
          queryParameters: {'from': from},
        ).toString();
      }
      return AppRoutes.login;
    }
    if (location == AppRoutes.home) return AppRoutes.login;
    return Uri(
      path: AppRoutes.login,
      queryParameters: {'from': location},
    ).toString();
  }

  if (isLoggingIn || isSplash) {
    if (hasValidFrom) return from;
    return AppRoutes.home;
  }

  return null;
}
