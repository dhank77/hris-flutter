import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_antigravity_starter_pack/core/error/app_exception.dart';
import 'package:flutter_antigravity_starter_pack/core/network/auth_interceptor.dart';
import 'package:flutter_antigravity_starter_pack/features/auth/data/auth_api.dart';
import 'package:flutter_antigravity_starter_pack/features/auth/data/auth_repository.dart';
import 'package:flutter_antigravity_starter_pack/features/auth/data/models/auth_user.dart';

import '../../../helpers/fakes.dart';

void main() {
  Dio createDio(FakeHttpAdapter adapter) =>
      Dio(BaseOptions(baseUrl: 'https://example.test'))
        ..httpClientAdapter = adapter;

  group('AuthUser.fromJson', () {
    test('mem-parse payload lengkap', () {
      final user = AuthUser.fromJson({
        'id': 1,
        'username': 'emilys',
        'email': 'emily@example.com',
        'firstName': 'Emily',
        'lastName': 'Johnson',
        'image': 'https://example.test/avatar.png',
      });

      expect(user.id, 1);
      expect(user.username, 'emilys');
      expect(user.fullName, 'Emily Johnson');
    });

    test('field opsional hilang memakai default', () {
      final user = AuthUser.fromJson({'id': 1, 'username': 'emilys'});

      expect(user.email, '');
      expect(user.fullName, 'emilys');
    });

    test('field wajib hilang melempar TypeError', () {
      expect(() => AuthUser.fromJson({'id': 1}), throwsA(isA<TypeError>()));
    });
  });

  group('AuthRepository', () {
    test('login menyimpan token dan mengembalikan user', () async {
      final storage = InMemoryTokenStorage();
      final adapter = FakeHttpAdapter((options) {
        expect(options.path, '/auth/login');
        expect(options.extra[skipAuthKey], isTrue);
        return const FakeResponse(200, {
          'id': 1,
          'username': 'emilys',
          'firstName': 'Emily',
          'lastName': 'Johnson',
          'accessToken': 'access-123',
          'refreshToken': 'refresh-456',
        });
      });
      final repo = AuthRepository(AuthApi(createDio(adapter)), storage);

      final user = await repo.login(username: 'emilys', password: 'secret');

      expect(user.username, 'emilys');
      expect(storage.accessToken, 'access-123');
      expect(storage.refreshToken, 'refresh-456');
    });

    test('login melempar BadResponseException jika token hilang', () async {
      final storage = InMemoryTokenStorage();
      final adapter = FakeHttpAdapter(
        (_) => const FakeResponse(200, {'id': 1, 'username': 'emilys'}),
      );
      final repo = AuthRepository(AuthApi(createDio(adapter)), storage);

      await expectLater(
        () => repo.login(username: 'emilys', password: 'secret'),
        throwsA(isA<BadResponseException>()),
      );
      expect(storage.accessToken, isNull);
    });

    test('restoreSession mengembalikan null bila tidak ada token', () async {
      final storage = InMemoryTokenStorage();
      final adapter = FakeHttpAdapter((_) => const FakeResponse(200, {}));
      final repo = AuthRepository(AuthApi(createDio(adapter)), storage);

      final user = await repo.restoreSession();

      expect(user, isNull);
      expect(adapter.requests, isEmpty);
    });

    test('restoreSession memuat /auth/me bila token ada', () async {
      final storage = InMemoryTokenStorage(
        accessToken: 'access-123',
        refreshToken: 'refresh-456',
      );
      final adapter = FakeHttpAdapter((options) {
        expect(options.path, '/auth/me');
        return const FakeResponse(200, {'id': 1, 'username': 'emilys'});
      });
      final repo = AuthRepository(AuthApi(createDio(adapter)), storage);

      final user = await repo.restoreSession();

      expect(user?.username, 'emilys');
    });

    test(
      'restoreSession menghapus token dan mengembalikan null saat 401',
      () async {
        final storage = InMemoryTokenStorage(
          accessToken: 'expired',
          refreshToken: 'refresh',
        );
        final adapter = FakeHttpAdapter(
          (_) => const FakeResponse(401, {'message': 'Invalid token'}),
        );
        final repo = AuthRepository(AuthApi(createDio(adapter)), storage);

        final user = await repo.restoreSession();

        expect(user, isNull);
        expect(storage.accessToken, isNull);
        expect(storage.refreshToken, isNull);
      },
    );

    test('logout menghapus token tersimpan', () async {
      final storage = InMemoryTokenStorage(
        accessToken: 'access-123',
        refreshToken: 'refresh-456',
      );
      final repo = AuthRepository(
        AuthApi(createDio(FakeHttpAdapter((_) => const FakeResponse(200)))),
        storage,
      );

      await repo.logout();

      expect(storage.accessToken, isNull);
      expect(storage.refreshToken, isNull);
    });
  });

  group('refreshAuthTokens', () {
    test('mengembalikan pasangan token baru saat berhasil', () async {
      final adapter = FakeHttpAdapter((options) {
        expect(options.path, '/auth/refresh');
        return const FakeResponse(200, {
          'accessToken': 'new-access',
          'refreshToken': 'new-refresh',
        });
      });

      final pair = await refreshAuthTokens(createDio(adapter), 'old-refresh');

      expect(pair?.accessToken, 'new-access');
      expect(pair?.refreshToken, 'new-refresh');
    });

    test('mengembalikan null jika respons tidak punya accessToken', () async {
      final adapter = FakeHttpAdapter((_) => const FakeResponse(200, {}));

      final pair = await refreshAuthTokens(createDio(adapter), 'old-refresh');

      expect(pair, isNull);
    });
  });
}
