import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:flutter_antigravity_starter_pack/core/error/app_exception.dart';
import 'package:flutter_antigravity_starter_pack/features/auth/application/auth_controller.dart';
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
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          splashDelayProvider.overrideWithValue(Duration.zero),
        ],
        child: const MaterialApp(home: LoginPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('menampilkan validasi jika field kosong', (tester) async {
    await pumpLoginPage(tester);

    await tester.tap(find.byKey(const Key('login.submit')));
    await tester.pumpAndSettle();

    expect(find.text('Email wajib diisi.'), findsOneWidget);
    expect(find.text('Password wajib diisi.'), findsOneWidget);
    verifyNever(
      () => repository.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    );
  });

  testWidgets('menampilkan validasi jika format email tidak valid', (
    tester,
  ) async {
    await pumpLoginPage(tester);

    await tester.enterText(find.byKey(const Key('login.email')), 'bukan-email');
    await tester.enterText(find.byKey(const Key('login.password')), 'secret');
    await tester.tap(find.byKey(const Key('login.submit')));
    await tester.pumpAndSettle();

    expect(find.text('Format email tidak valid.'), findsOneWidget);
    verifyNever(
      () => repository.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    );
  });

  testWidgets('menampilkan snackbar error saat login gagal', (tester) async {
    when(
      () => repository.login(email: 'budi@example.com', password: 'wrong'),
    ).thenThrow(const UnauthorizedException('Email atau password salah.'));

    await pumpLoginPage(tester);

    await tester.enterText(
      find.byKey(const Key('login.email')),
      'budi@example.com',
    );
    await tester.enterText(find.byKey(const Key('login.password')), 'wrong');
    await tester.tap(find.byKey(const Key('login.submit')));
    await tester.pumpAndSettle();

    expect(find.text('Email atau password salah.'), findsOneWidget);
  });

  testWidgets('memanggil repository.login saat form valid', (tester) async {
    when(
      () => repository.login(email: 'budi@example.com', password: 'secret'),
    ).thenAnswer(
      (_) async => const AuthUser(
        id: 1,
        name: 'Budi Santoso',
        email: 'budi@example.com',
      ),
    );

    await pumpLoginPage(tester);

    await tester.enterText(
      find.byKey(const Key('login.email')),
      'budi@example.com',
    );
    await tester.enterText(find.byKey(const Key('login.password')), 'secret');
    await tester.tap(find.byKey(const Key('login.submit')));
    await tester.pumpAndSettle();

    verify(
      () => repository.login(email: 'budi@example.com', password: 'secret'),
    ).called(1);
  });

  testWidgets(
    'memanggil repository.loginWithGoogle saat tombol Google ditekan',
    (tester) async {
      when(() => repository.loginWithGoogle()).thenAnswer(
        (_) async => const AuthUser(
          id: 2,
          name: 'Budi Google',
          email: 'budi.google@example.com',
        ),
      );

      await pumpLoginPage(tester);

      await tester.tap(find.byKey(const Key('login.google')));
      await tester.pumpAndSettle();

      verify(() => repository.loginWithGoogle()).called(1);
    },
  );

  testWidgets(
    'memanggil repository.loginWithGoogle saat tombol Google ditekan',
    (tester) async {
      when(() => repository.loginWithGoogle()).thenAnswer(
        (_) async => const AuthUser(
          id: 2,
          name: 'Budi Google',
          email: 'budi.google@example.com',
        ),
      );

      await pumpLoginPage(tester);

      await tester.tap(find.byKey(const Key('login.google')));
      await tester.pumpAndSettle();

      verify(() => repository.loginWithGoogle()).called(1);
    },
  );
}
