import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_antigravity_starter_pack/app/router/app_routes.dart';
import 'package:flutter_antigravity_starter_pack/app/router/route_guards.dart';
import 'package:flutter_antigravity_starter_pack/features/auth/data/models/auth_user.dart';

void main() {
  const user = AuthUser(
    id: 1,
    name: 'Emily Johnson',
    email: 'emily@example.com',
  );

  test('tidak redirect saat auth masih loading', () {
    expect(
      resolveAuthRedirect(
        authState: const AsyncLoading(),
        location: AppRoutes.home,
      ),
      isNull,
    );
  });

  test('belum login di / diarahkan ke /login', () {
    expect(
      resolveAuthRedirect(
        authState: const AsyncData(null),
        location: AppRoutes.home,
      ),
      AppRoutes.login,
    );
  });

  test('belum login di /settings menyimpan parameter from', () {
    expect(
      resolveAuthRedirect(
        authState: const AsyncData(null),
        location: AppRoutes.settings,
      ),
      '/login?from=%2Fsettings',
    );
  });

  test('belum login di /login tidak di-redirect', () {
    expect(
      resolveAuthRedirect(
        authState: const AsyncData(null),
        location: AppRoutes.login,
      ),
      isNull,
    );
  });

  test('sudah login di /login diarahkan ke /', () {
    expect(
      resolveAuthRedirect(
        authState: const AsyncData(user),
        location: AppRoutes.login,
      ),
      AppRoutes.home,
    );
  });

  test('sudah login di /login dengan from diarahkan ke from', () {
    expect(
      resolveAuthRedirect(
        authState: const AsyncData(user),
        location: AppRoutes.login,
        from: AppRoutes.settings,
      ),
      AppRoutes.settings,
    );
  });

  test('sudah login di / tidak di-redirect', () {
    expect(
      resolveAuthRedirect(
        authState: const AsyncData(user),
        location: AppRoutes.home,
      ),
      isNull,
    );
  });
}
