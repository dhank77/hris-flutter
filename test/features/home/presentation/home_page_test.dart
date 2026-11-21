import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:flutter_antigravity_starter_pack/features/auth/application/auth_controller.dart';
import 'package:flutter_antigravity_starter_pack/features/auth/data/auth_repository.dart';
import 'package:flutter_antigravity_starter_pack/features/auth/data/models/auth_user.dart';
import 'package:flutter_antigravity_starter_pack/features/home/presentation/home_page.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  const sampleUser = AuthUser(
    id: 1,
    name: 'Emily Johnson',
    email: 'emily@example.com',
  );

  Future<void> pumpHomePage(WidgetTester tester, {AuthUser? user}) async {
    final repository = _MockAuthRepository();
    when(() => repository.restoreSession()).thenAnswer((_) async => user);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          splashDelayProvider.overrideWithValue(Duration.zero),
        ],
        child: const MaterialApp(home: HomePage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('menyambut pengguna yang login di dashboard', (tester) async {
    await pumpHomePage(tester, user: sampleUser);

    expect(find.text('Selamat datang,'), findsOneWidget);
    expect(find.text('Emily Johnson'), findsOneWidget);
    expect(find.text('emily@example.com'), findsOneWidget);
    expect(find.text('Ringkasan Hari Ini'), findsOneWidget);
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
      await tester.tap(absensiFinder);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('home.settings')), findsOneWidget);
      expect(find.text('Setting'), findsOneWidget);
    },
  );
}
