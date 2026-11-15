import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_antigravity_starter_pack/core/error/app_exception.dart';

DioException _badResponse(int status, [Object? data]) {
  final options = RequestOptions(path: '/x');
  return DioException.badResponse(
    statusCode: status,
    requestOptions: options,
    response: Response<Object?>(
      requestOptions: options,
      statusCode: status,
      data: data,
    ),
  );
}

void main() {
  group('mapDioException', () {
    test('timeout menjadi NetworkException', () {
      final error = DioException.connectionTimeout(
        timeout: const Duration(seconds: 1),
        requestOptions: RequestOptions(path: '/x'),
      );
      expect(mapDioException(error), isA<NetworkException>());
    });

    test('connection error menjadi NetworkException', () {
      final error = DioException.connectionError(
        requestOptions: RequestOptions(path: '/x'),
        reason: 'offline',
      );
      expect(mapDioException(error), isA<NetworkException>());
    });

    test('401 menjadi UnauthorizedException', () {
      expect(mapDioException(_badResponse(401)), isA<UnauthorizedException>());
    });

    test('pesan dari server dipakai bila ada', () {
      final mapped = mapDioException(
        _badResponse(400, {'message': 'Invalid credentials'}),
      );
      expect(mapped, isA<ServerException>());
      expect(mapped.message, 'Invalid credentials');
      expect((mapped as ServerException).statusCode, 400);
    });

    test('5xx menyembunyikan detail server', () {
      final mapped = mapDioException(
        _badResponse(500, {'message': 'NullPointer at line 42'}),
      );
      expect(mapped.message, isNot(contains('NullPointer')));
    });

    test('cancel menjadi CancelledException', () {
      final error = DioException.requestCancelled(
        requestOptions: RequestOptions(path: '/x'),
        reason: 'disposed',
      );
      expect(mapDioException(error), isA<CancelledException>());
    });
  });

  test('describeError memberi pesan umum untuk error non-aplikasi', () {
    expect(describeError(StateError('boom')), const UnknownException().message);
    expect(describeError(const NetworkException('offline')), 'offline');
  });
}
