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
      Dio(BaseOptions(baseUrl: 'https://hris.test/api'))
        ..httpClientAdapter = adapter;

  group('AuthUser.fromJson', () {
    test('mem-parse payload lengkap dari Laravel Sanctum', () {
      final user = AuthUser.fromJson({
        'id': 1,
        'name': 'Budi Santoso',
        'email': 'budi@example.com',
        'avatar': 'avatars/budi.png',
        'role': 'employee',
        'department': 'Engineering',
        'position': 'Software Engineer',
      });

      expect(user.id, 1);
      expect(user.name, 'Budi Santoso');
      expect(user.email, 'budi@example.com');
      expect(user.department, 'Engineering');
      expect(user.position, 'Software Engineer');
      expect(user.fullName, 'Budi Santoso');
    });

    test('field opsional hilang memakai default', () {
      final user = AuthUser.fromJson({
        'id': 1,
        'name': 'Budi Santoso',
        'email': 'budi@example.com',
      });

      expect(user.role, 'employee');
      expect(user.department, isNull);
      expect(user.position, isNull);
    });

    test('field wajib hilang melempar TypeError', () {
      expect(() => AuthUser.fromJson({'id': 1}), throwsA(isA<TypeError>()));
    });
  });

  group('AuthRepository', () {
    test(
      'login menyimpan access_token Sanctum dan mengembalikan user',
      () async {
        final storage = InMemoryTokenStorage();
        final adapter = FakeHttpAdapter((options) {
          expect(options.path, '/auth/login');
          expect(options.extra[skipAuthKey], isTrue);
          return const FakeResponse(200, {
            'access_token': '1|sanctum-token-123',
            'token_type': 'Bearer',
            'user': {
              'id': 1,
              'name': 'Budi Santoso',
              'email': 'budi@example.com',
              'role': 'employee',
            },
          });
        });
        final repo = AuthRepository(AuthApi(createDio(adapter)), storage);

        final user = await repo.login(
          email: 'budi@example.com',
          password: 'secret',
        );

        expect(user.email, 'budi@example.com');
        expect(user.fullName, 'Budi Santoso');
        expect(storage.accessToken, '1|sanctum-token-123');
      },
    );

    test('login melempar BadResponseException jika token hilang', () async {
      final storage = InMemoryTokenStorage();
      final adapter = FakeHttpAdapter(
        (_) => const FakeResponse(200, {
          'user': {
            'id': 1,
            'name': 'Budi Santoso',
            'email': 'budi@example.com',
          },
        }),
      );
      final repo = AuthRepository(AuthApi(createDio(adapter)), storage);

      await expectLater(
        () => repo.login(email: 'budi@example.com', password: 'secret'),
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
        accessToken: '1|sanctum-token-123',
        refreshToken: '',
      );
      final adapter = FakeHttpAdapter((options) {
        expect(options.path, '/auth/me');
        return const FakeResponse(200, {
          'user': {
            'id': 1,
            'name': 'Budi Santoso',
            'email': 'budi@example.com',
          },
        });
      });
      final repo = AuthRepository(AuthApi(createDio(adapter)), storage);

      final user = await repo.restoreSession();

      expect(user?.email, 'budi@example.com');
      expect(user?.fullName, 'Budi Santoso');
    });

    test(
      'restoreSession menghapus token dan mengembalikan null saat 401',
      () async {
        final storage = InMemoryTokenStorage(
          accessToken: 'expired',
          refreshToken: '',
        );
        final adapter = FakeHttpAdapter(
          (_) => const FakeResponse(401, {'message': 'Unauthenticated.'}),
        );
        final repo = AuthRepository(AuthApi(createDio(adapter)), storage);

        final user = await repo.restoreSession();

        expect(user, isNull);
        expect(storage.accessToken, isNull);
        expect(storage.refreshToken, isNull);
      },
    );

    test(
      'logout memanggil /auth/logout dan menghapus token tersimpan',
      () async {
        final storage = InMemoryTokenStorage(
          accessToken: '1|sanctum-token-123',
          refreshToken: '',
        );
        final adapter = FakeHttpAdapter((options) {
          expect(options.path, '/auth/logout');
          return const FakeResponse(200, {'message': 'Berhasil keluar.'});
        });
        final repo = AuthRepository(AuthApi(createDio(adapter)), storage);

        await repo.logout();

        expect(adapter.requests, hasLength(1));
        expect(storage.accessToken, isNull);
        expect(storage.refreshToken, isNull);
      },
    );
  });
}
