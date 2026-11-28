import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:flutter_antigravity_starter_pack/app/router/app_routes.dart';
import 'package:flutter_antigravity_starter_pack/features/attendance/data/attendance_repository.dart';
import 'package:flutter_antigravity_starter_pack/features/attendance/data/models/attendance.dart';
import 'package:flutter_antigravity_starter_pack/features/auth/application/auth_controller.dart';
import 'package:flutter_antigravity_starter_pack/features/auth/data/auth_repository.dart';
import 'package:flutter_antigravity_starter_pack/features/auth/data/models/auth_user.dart';
import 'package:flutter_antigravity_starter_pack/features/home/presentation/home_page.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockAttendanceRepository extends Mock implements AttendanceRepository {}

void main() {
  const sampleUser = AuthUser(
    id: 1,
    name: 'Emily Johnson',
    email: 'emily@example.com',
  );

  const defaultOverview = AttendanceOverview(
    today: '2026-11-22',
    officeLocation: OfficeLocation(),
    recap: AttendanceRecap(),
  );

  Future<void> pumpHomePage(
    WidgetTester tester, {
    AuthUser? user,
    AttendanceOverview overview = defaultOverview,
  }) async {
    final repository = _MockAuthRepository();
    final attendanceRepository = _MockAttendanceRepository();
    when(() => repository.restoreSession()).thenAnswer((_) async => user);
    when(
      () => attendanceRepository.getTodayOverview(),
    ).thenAnswer((_) async => overview);

    final router = GoRouter(
      initialLocation: AppRoutes.home,
      routes: [
        GoRoute(path: AppRoutes.home, builder: (_, _) => const HomePage()),
        GoRoute(
          path: AppRoutes.attendance,
          builder: (_, _) => const Scaffold(body: Text('Halaman Absensi')),
        ),
        GoRoute(
          path: AppRoutes.profile,
          builder: (_, _) => const Scaffold(body: Text('Halaman Profil')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          attendanceRepositoryProvider.overrideWithValue(attendanceRepository),
          splashDelayProvider.overrideWithValue(Duration.zero),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('menampilkan kartu profil pengguna yang login di dashboard', (
    tester,
  ) async {
    await pumpHomePage(tester, user: sampleUser);

    expect(find.text('Emily Johnson'), findsOneWidget);
    expect(find.text('emily@example.com'), findsOneWidget);
    expect(find.byKey(const Key('home.profileAvatar')), findsOneWidget);
    expect(find.text('EJ'), findsOneWidget);
    expect(find.text('Ringkasan Hari Ini'), findsOneWidget);
  });

  testWidgets('menampilkan jabatan, departemen, dan foto avatar pengguna', (
    tester,
  ) async {
    const userWithAvatar = AuthUser(
      id: 2,
      name: 'Ohan Farhanah',
      email: 'ohan@example.com',
      avatar: 'https://example.com/avatars/ohan.png',
      position: 'HR Manager',
      department: 'PT Enzym Bioteknologi Internusa',
    );

    await pumpHomePage(tester, user: userWithAvatar);

    expect(find.text('Ohan Farhanah'), findsOneWidget);
    expect(
      find.text('HR Manager\nPT Enzym Bioteknologi Internusa'),
      findsOneWidget,
    );
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets(
    'menampilkan bottom navigation Home, Absensi (bulat besar), dan Setting',
    (tester) async {
      await pumpHomePage(tester, user: sampleUser);

      expect(find.byKey(const Key('home.nav.home')), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);

      final absensiFinder = find.byKey(const Key('home.absensi'));
      expect(absensiFinder, findsOneWidget);
      expect(find.text('Absensi'), findsOneWidget);
      expect(find.byKey(const Key('home.settings')), findsOneWidget);
      expect(find.text('Setting'), findsOneWidget);

      await tester.tap(absensiFinder);
      await tester.pumpAndSettle();
      expect(find.text('Halaman Absensi'), findsOneWidget);
    },
  );

  testWidgets('menampilkan jam masuk dan pulang dari API', (tester) async {
    final clockIn = DateTime(2026, 11, 22, 8, 15).toIso8601String();
    final clockOut = DateTime(2026, 11, 22, 17, 5).toIso8601String();

    await pumpHomePage(
      tester,
      user: sampleUser,
      overview: AttendanceOverview(
        today: '2026-11-22',
        attendance: Attendance(
          id: 1,
          date: '2026-11-22',
          clockInAt: clockIn,
          clockOutAt: clockOut,
          status: 'present',
        ),
        officeLocation: const OfficeLocation(),
        recap: const AttendanceRecap(),
      ),
    );

    expect(find.text('Selesai'), findsOneWidget);
    expect(find.text('08:15'), findsOneWidget);
    expect(find.text('17:05'), findsOneWidget);
  });

  testWidgets('mengetuk banner profil membuka halaman profil', (tester) async {
    await pumpHomePage(tester, user: sampleUser);

    await tester.tap(find.byKey(const Key('home.profileBanner')));
    await tester.pumpAndSettle();

    expect(find.text('Halaman Profil'), findsOneWidget);
  });
}
