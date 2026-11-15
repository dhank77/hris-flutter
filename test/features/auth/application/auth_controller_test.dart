import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:flutter_antigravity_starter_pack/core/error/app_exception.dart';
import 'package:flutter_antigravity_starter_pack/core/session/session_expiry.dart';
import 'package:flutter_antigravity_starter_pack/features/auth/application/auth_controller.dart';
import 'package:flutter_antigravity_starter_pack/features/auth/application/login_controller.dart';
import 'package:flutter_antigravity_starter_pack/features/auth/data/auth_repository.dart';
import 'package:flutter_antigravity_starter_pack/features/auth/data/models/auth_user.dart';

import '../../../helpers/fakes.dart';

class _MockRepository extends Mock implements AuthRepository {}

void main() {
  const sampleUser = AuthUser(
    id: 1,
    username: 'emilys',
    firstName: 'Emily',
    lastName: 'Johnson',
  );

  late _MockRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = _MockRepository();
    container = ProviderContainer.test(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
      retry: (_, _) => null,
    );
  });

  test('restoreSession mengisi state awal AuthController', () async {
    when(() => repository.restoreSession()).thenAnswer((_) async => sampleUser);

    final sub = container.listen(authControllerProvider, (_, _) {});
    addTearDown(sub.close);
    await settle();

    expect(container.read(authControllerProvider).requireValue, sampleUser);
  });

  test('login dan logout memperbarui state AuthController', () async {
    when(() => repository.restoreSession()).thenAnswer((_) async => null);
    when(
      () => repository.login(username: 'emilys', password: 'secret'),
    ).thenAnswer((_) async => sampleUser);
    when(() => repository.logout()).thenAnswer((_) async {});

    final sub = container.listen(authControllerProvider, (_, _) {});
    addTearDown(sub.close);
    await settle();

    expect(container.read(authControllerProvider).requireValue, isNull);

    await container
        .read(authControllerProvider.notifier)
        .login(username: 'emilys', password: 'secret');
    expect(container.read(authControllerProvider).requireValue, sampleUser);

    await container.read(authControllerProvider.notifier).logout();
    expect(container.read(authControllerProvider).requireValue, isNull);
  });

  test('sessionExpiryProvider mereset state AuthController ke null', () async {
    when(() => repository.restoreSession()).thenAnswer((_) async => sampleUser);

    final sub = container.listen(authControllerProvider, (_, _) {});
    addTearDown(sub.close);
    await settle();

    expect(container.read(authControllerProvider).requireValue, sampleUser);

    container.read(sessionExpiryProvider.notifier).notifyExpired();
    expect(container.read(authControllerProvider).requireValue, isNull);
  });

  group('LoginController', () {
    test('submit mengembalikan true saat berhasil', () async {
      when(() => repository.restoreSession()).thenAnswer((_) async => null);
      when(
        () => repository.login(username: 'emilys', password: 'secret'),
      ).thenAnswer((_) async => sampleUser);

      final authSub = container.listen(authControllerProvider, (_, _) {});
      final loginSub = container.listen(loginControllerProvider, (_, _) {});
      addTearDown(authSub.close);
      addTearDown(loginSub.close);
      await settle();

      final ok = await container
          .read(loginControllerProvider.notifier)
          .submit(username: 'emilys', password: 'secret');

      expect(ok, isTrue);
      expect(container.read(loginControllerProvider).hasError, isFalse);
      expect(container.read(authControllerProvider).requireValue, sampleUser);
    });

    test('submit mengembalikan false dan AsyncError saat gagal', () async {
      when(() => repository.restoreSession()).thenAnswer((_) async => null);
      when(
        () => repository.login(username: 'emilys', password: 'wrong'),
      ).thenThrow(const UnauthorizedException('Username atau password salah.'));

      final authSub = container.listen(authControllerProvider, (_, _) {});
      final loginSub = container.listen(loginControllerProvider, (_, _) {});
      addTearDown(authSub.close);
      addTearDown(loginSub.close);
      await settle();

      final ok = await container
          .read(loginControllerProvider.notifier)
          .submit(username: 'emilys', password: 'wrong');

      expect(ok, isFalse);
      expect(container.read(loginControllerProvider).hasError, isTrue);
    });
  });
}
