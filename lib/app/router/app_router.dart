import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_antigravity_starter_pack/app/router/app_routes.dart';
import 'package:flutter_antigravity_starter_pack/core/widgets/state_views.dart';
import 'package:flutter_antigravity_starter_pack/features/home/presentation/home_page.dart';
import 'package:flutter_antigravity_starter_pack/features/settings/presentation/settings_page.dart';

// <generator:imports> — scripts/new_feature.sh menambahkan import di atas baris ini.

/// GoRouter dibuat SEKALI untuk seluruh umur aplikasi.
///
/// Butuh halaman login? Tambahkan `refreshListenable` + `redirect` yang
/// membaca status auth. Contoh lengkapnya (guard sebagai fungsi murni yang
/// teruji) ada di branch `example`: `app/router/route_guards.dart`.
final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: kDebugMode,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsPage(),
      ),
      // <generator:routes> — scripts/new_feature.sh menambahkan route di atas baris ini.
    ],
    errorBuilder: (context, state) => const _NotFoundPage(),
  );
  ref.onDispose(router.dispose);
  return router;
});

class _NotFoundPage extends StatelessWidget {
  const _NotFoundPage();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: const EmptyView(
      icon: Icons.explore_off_outlined,
      message: 'Halaman tidak ditemukan.',
    ),
  );
}
