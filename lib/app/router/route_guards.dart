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
  // Tunggu proses restore session selesai sebelum memutuskan redirect.
  if (authState.isLoading) return null;

  final isAuthenticated = authState.asData?.value != null;
  final isLoggingIn = location == AppRoutes.login;

  if (!isAuthenticated) {
    if (isLoggingIn) return null;
    if (location == AppRoutes.home) return AppRoutes.login;
    return Uri(
      path: AppRoutes.login,
      queryParameters: {'from': location},
    ).toString();
  }

  if (isLoggingIn) {
    if (from != null && from.startsWith('/') && from != AppRoutes.login) {
      return from;
    }
    return AppRoutes.home;
  }

  return null;
}
