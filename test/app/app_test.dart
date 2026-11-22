import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_antigravity_starter_pack/app/app.dart';
import 'package:flutter_antigravity_starter_pack/core/storage/preferences.dart';
import 'package:flutter_antigravity_starter_pack/features/auth/data/auth_repository.dart';
import 'package:flutter_antigravity_starter_pack/features/auth/data/models/auth_user.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  const sampleUser = AuthUser(
    id: 1,
    name: 'Emily Johnson',
    email: 'emily@example.com',
  );

  Future<void> pumpApp(WidgetTester tester, {AuthUser? initialUser}) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final authRepository = _MockAuthRepository();
    when(
      () => authRepository.restoreSession(),
    ).thenAnswer((_) async => initialUser);
    when(() => authRepository.logout()).thenAnswer((_) async {});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          authRepositoryProvider.overrideWithValue(authRepository),
        ],
        child: const App(),
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'menampilkan splash screen selama 2 detik saat cek sesi lalu langsung ke login (tanpa sempat menampilkan Beranda)',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final authRepository = _MockAuthRepository();
      when(() => authRepository.restoreSession()).thenAnswer((_) async => null);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(preferences),
            authRepositoryProvider.overrideWithValue(authRepository),
          ],
          child: const App(),
        ),
      );
      await tester.pump();

      // Saat baru dibuka (0 detik), Splash tampil dan Beranda tidak pernah muncul.
      expect(find.byKey(const Key('splash.loading')), findsOneWidget);
      expect(find.text('Beranda'), findsNothing);
      expect(find.byKey(const Key('login.submit')), findsNothing);

      // Setelah 1 detik (belum 2 detik), masih di Splash screen.
      await tester.pump(const Duration(seconds: 1));
      expect(find.byKey(const Key('splash.loading')), findsOneWidget);
      expect(find.byKey(const Key('login.submit')), findsNothing);

      // Setelah total 2 detik berlalu, selesai loading -> langsung ke Login.
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('login.submit')), findsOneWidget);
      expect(find.text('Beranda'), findsNothing);
    },
  );

  testWidgets('pengguna belum login diarahkan ke halaman Masuk', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(find.byKey(const Key('login.submit')), findsOneWidget);
  });

  testWidgets(
    'membuka Beranda lalu pindah ke Pengaturan dan kembali ke Beranda',
    (tester) async {
      await pumpApp(tester, initialUser: sampleUser);
      expect(find.text('Beranda'), findsOneWidget);

      await tester.tap(find.byKey(const Key('home.settings')));
      await tester.pumpAndSettle();

      expect(find.text('Pengaturan'), findsOneWidget);
      expect(find.text('Tema'), findsOneWidget);
      expect(find.byKey(const Key('settings.logout')), findsOneWidget);
      expect(find.byKey(const Key('home.nav.home')), findsOneWidget);
      expect(find.byKey(const Key('home.absensi')), findsOneWidget);
      expect(find.byKey(const Key('home.settings')), findsOneWidget);

      await tester.tap(find.byKey(const Key('home.nav.home')));
      await tester.pumpAndSettle();

      expect(find.text('Beranda'), findsOneWidget);
    },
  );

  testWidgets('mengganti tema tersimpan di preferences', (tester) async {
    await pumpApp(tester, initialUser: sampleUser);
    await tester.tap(find.byKey(const Key('home.settings')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Gelap'));
    await tester.pumpAndSettle();

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('settings.theme_mode'), 'dark');
  });

  testWidgets('keluar dari Pengaturan mengarahkan ke halaman Masuk', (
    tester,
  ) async {
    await pumpApp(tester, initialUser: sampleUser);
    await tester.tap(find.byKey(const Key('home.settings')));
    await tester.pumpAndSettle();

    final logoutFinder = find.byKey(const Key('settings.logout'));
    await tester.ensureVisible(logoutFinder);
    await tester.pumpAndSettle();
    await tester.tap(logoutFinder);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('login.submit')), findsOneWidget);
  });
}
