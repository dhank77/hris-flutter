import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:flutter_antigravity_starter_pack/core/error/app_exception.dart';
import 'package:flutter_antigravity_starter_pack/features/auth/data/auth_repository.dart';
import 'package:flutter_antigravity_starter_pack/features/auth/data/models/auth_user.dart';
import 'package:flutter_antigravity_starter_pack/features/auth/presentation/login_page.dart';

class _MockRepository extends Mock implements AuthRepository {}

void main() {
  late _MockRepository repository;

  setUp(() {
    repository = _MockRepository();
    when(() => repository.restoreSession()).thenAnswer((_) async => null);
  });

  Future<void> pumpLoginPage(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: LoginPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('menampilkan validasi jika field kosong', (tester) async {
    await pumpLoginPage(tester);

    await tester.tap(find.byKey(const Key('login.submit')));
    await tester.pumpAndSettle();

    expect(find.text('Username wajib diisi.'), findsOneWidget);
    expect(find.text('Password wajib diisi.'), findsOneWidget);
    verifyNever(
      () => repository.login(
        username: any(named: 'username'),
        password: any(named: 'password'),
      ),
    );
  });

  testWidgets('menampilkan snackbar error saat login gagal', (tester) async {
    when(
      () => repository.login(username: 'emilys', password: 'wrong'),
    ).thenThrow(const UnauthorizedException('Kredensial tidak valid.'));

    await pumpLoginPage(tester);

    await tester.enterText(find.byKey(const Key('login.username')), 'emilys');
    await tester.enterText(find.byKey(const Key('login.password')), 'wrong');
    await tester.tap(find.byKey(const Key('login.submit')));
    await tester.pumpAndSettle();

    expect(find.text('Kredensial tidak valid.'), findsOneWidget);
  });

  testWidgets('memanggil repository.login saat form valid', (tester) async {
    when(
      () => repository.login(username: 'emilys', password: 'secret'),
    ).thenAnswer((_) async => const AuthUser(id: 1, username: 'emilys'));

    await pumpLoginPage(tester);

    await tester.enterText(find.byKey(const Key('login.username')), 'emilys');
    await tester.enterText(find.byKey(const Key('login.password')), 'secret');
    await tester.tap(find.byKey(const Key('login.submit')));
    await tester.pumpAndSettle();

    verify(
      () => repository.login(username: 'emilys', password: 'secret'),
    ).called(1);
  });
}
