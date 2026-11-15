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
    username: 'emilys',
    firstName: 'Emily',
    lastName: 'Johnson',
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
    await tester.pumpAndSettle();
  }

  testWidgets('pengguna belum login diarahkan ke halaman Masuk', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(find.byKey(const Key('login.submit')), findsOneWidget);
  });

  testWidgets('membuka Beranda lalu pindah ke Pengaturan', (tester) async {
    await pumpApp(tester, initialUser: sampleUser);
    expect(find.text('Beranda'), findsOneWidget);

    await tester.tap(find.byKey(const Key('home.settings')));
    await tester.pumpAndSettle();

    expect(find.text('Pengaturan'), findsOneWidget);
    expect(find.text('Tema'), findsOneWidget);
    expect(find.byKey(const Key('settings.logout')), findsOneWidget);
  });

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

    await tester.tap(find.byKey(const Key('settings.logout')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('login.submit')), findsOneWidget);
  });
}
