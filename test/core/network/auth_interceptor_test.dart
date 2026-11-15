import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_antigravity_starter_pack/core/network/auth_interceptor.dart';
import 'package:flutter_antigravity_starter_pack/core/network/token_refresher.dart';

import '../../helpers/fakes.dart';

void main() {
  late InMemoryTokenStorage storage;
  late int expiredCount;

  /// Refresher contoh: POST /auth/refresh → {accessToken, refreshToken}.
  Future<TokenPair?> refresher(Dio client, String refreshToken) async {
    final res = await client.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    final access = res.data?['accessToken'];
    final refresh = res.data?['refreshToken'];
    if (access is! String || refresh is! String) return null;
    return (accessToken: access, refreshToken: refresh);
  }

  Dio buildDio(FakeHttpAdapter adapter, {TokenRefresher? refreshTokens}) {
    final options = BaseOptions(baseUrl: 'https://api.test');
    final refreshClient = Dio(options)..httpClientAdapter = adapter;
    final dio = Dio(options)..httpClientAdapter = adapter;
    dio.interceptors.add(
      AuthInterceptor(
        tokenStorage: storage,
        refreshClient: refreshClient,
        onSessionExpired: () => expiredCount++,
        refreshTokens: refreshTokens,
      ),
    );
    return dio;
  }

  setUp(() {
    storage = InMemoryTokenStorage(accessToken: 'old', refreshToken: 'r1');
    expiredCount = 0;
  });

  test('menambahkan header Authorization', () async {
    final adapter = FakeHttpAdapter((_) => const FakeResponse(200));
    await buildDio(adapter).get<Object?>('/me');

    expect(adapter.requests.single.headers['Authorization'], 'Bearer old');
  });

  test('endpoint dengan skipAuth tidak diberi token', () async {
    final adapter = FakeHttpAdapter((_) => const FakeResponse(200));
    await buildDio(adapter).post<Object?>(
      '/auth/login',
      options: Options(extra: {skipAuthKey: true}),
    );

    expect(adapter.requests.single.headers['Authorization'], isNull);
  });

  test('401 → refresh token → request diulang dengan token baru', () async {
    final adapter = FakeHttpAdapter((options) {
      if (options.path == '/auth/refresh') {
        return const FakeResponse(200, {
          'accessToken': 'new',
          'refreshToken': 'r2',
        });
      }
      final authorized = options.headers['Authorization'] == 'Bearer new';
      return authorized
          ? const FakeResponse(200, {'ok': true})
          : const FakeResponse(401);
    });

    final response = await buildDio(
      adapter,
      refreshTokens: refresher,
    ).get<Object?>('/secure');

    expect(response.data, {'ok': true});
    expect(storage.accessToken, 'new');
    expect(storage.refreshToken, 'r2');
    expect(expiredCount, 0);
  });

  test('refresh gagal → token dihapus dan sesi dinyatakan berakhir', () async {
    final adapter = FakeHttpAdapter((_) => const FakeResponse(401));

    await expectLater(
      buildDio(adapter, refreshTokens: refresher).get<Object?>('/secure'),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'status',
          401,
        ),
      ),
    );
    expect(storage.accessToken, isNull);
    expect(expiredCount, 1);
    // Request awal + satu kali refresh, tidak ada loop.
    expect(adapter.requests, hasLength(2));
  });

  test('tanpa refresher → 401 langsung mengakhiri sesi', () async {
    final adapter = FakeHttpAdapter((_) => const FakeResponse(401));

    await expectLater(
      buildDio(adapter).get<Object?>('/secure'),
      throwsA(isA<DioException>()),
    );
    expect(storage.accessToken, isNull);
    expect(expiredCount, 1);
    expect(adapter.requests, hasLength(1));
  });
}
