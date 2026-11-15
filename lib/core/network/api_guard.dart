import 'package:dio/dio.dart';

import 'package:flutter_antigravity_starter_pack/core/error/app_exception.dart';

/// Membungkus pemanggilan API agar semua kegagalan keluar sebagai
/// [AppException]:
/// - [DioException]      → dipetakan oleh [mapDioException]
/// - TypeError/Format    → JSON tidak sesuai kontrak ([BadResponseException])
Future<T> guardApi<T>(Future<T> Function() request) async {
  try {
    return await request();
  } on AppException {
    rethrow;
  } on DioException catch (error) {
    throw mapDioException(error);
  } on FormatException {
    throw const BadResponseException();
  } on TypeError {
    // json_serializable melempar TypeError bila tipe field tidak cocok,
    // mis. `null` untuk field wajib.
    throw const BadResponseException();
  }
}

/// Memastikan body respons adalah objek JSON sebelum di-parse.
Map<String, dynamic> asJsonObject(Object? data) {
  if (data is Map<String, dynamic>) return data;
  throw const BadResponseException();
}
