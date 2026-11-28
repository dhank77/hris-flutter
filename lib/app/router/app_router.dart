import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_antigravity_starter_pack/app/router/app_routes.dart';
import 'package:flutter_antigravity_starter_pack/app/router/route_guards.dart';
import 'package:flutter_antigravity_starter_pack/core/widgets/state_views.dart';
import 'package:flutter_antigravity_starter_pack/features/auth/application/auth_controller.dart';
import 'package:flutter_antigravity_starter_pack/features/auth/presentation/login_page.dart';
import 'package:flutter_antigravity_starter_pack/features/auth/presentation/splash_page.dart';
import 'package:flutter_antigravity_starter_pack/features/home/presentation/home_page.dart';
import 'package:flutter_antigravity_starter_pack/features/settings/presentation/about_info_page.dart';
import 'package:flutter_antigravity_starter_pack/features/settings/presentation/settings_page.dart';

import 'package:flutter_antigravity_starter_pack/features/attendance/presentation/attendance_page.dart';

import 'package:flutter_antigravity_starter_pack/features/face_recognition/presentation/face_recognition_page.dart';

import 'package:flutter_antigravity_starter_pack/features/profile/presentation/profile_page.dart';

import 'package:flutter_antigravity_starter_pack/features/leave_requests/presentation/leave_requests_page.dart';

// <generator:imports> — scripts/new_feature.sh menambahkan import di atas baris ini.

/// GoRouter dibuat SEKALI untuk seluruh umur aplikasi.
final routerProvider = Provider<GoRouter>((ref) {
  final authListenable = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (_, _) {
    authListenable.value++;
  });

  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: kDebugMode,
    refreshListenable: authListenable,
    redirect: (context, state) => resolveAuthRedirect(
      authState: ref.read(authControllerProvider),
      location: state.uri.path,
      from: state.uri.queryParameters['from'],
    ),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: AppRoutes.aboutInfo,
        builder: (context, state) => const AboutInfoPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.attendance,
        builder: (context, state) => const AttendancePage(),
      ),
      GoRoute(
        path: AppRoutes.faceRecognition,
        builder: (context, state) => FaceRecognitionPage(
          attendanceVerifyMode:
              state.uri.queryParameters['mode'] == 'attendance',
        ),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: AppRoutes.leaveRequests,
        builder: (context, state) => const LeaveRequestsPage(),
      ),
      // <generator:routes> — scripts/new_feature.sh menambahkan route di atas baris ini.
    ],
    errorBuilder: (context, state) => const _NotFoundPage(),
  );
  ref.onDispose(() {
    authListenable.dispose();
    router.dispose();
  });
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
