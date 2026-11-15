import 'package:dio/dio.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderException;

/// Error level aplikasi. Layer presentation hanya mengenal tipe ini,
/// tidak pernah [DioException] secara langsung.
sealed class AppException implements Exception {
  const AppException(this.message);

  /// Pesan yang aman ditampilkan ke pengguna.
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// Tidak ada koneksi, timeout, atau sertifikat tidak valid.
final class NetworkException extends AppException {
  const NetworkException(super.message);
}

/// Token tidak ada/kedaluwarsa dan tidak bisa diperbarui.
final class UnauthorizedException extends AppException {
  const UnauthorizedException([
    super.message = 'Sesi berakhir. Silakan login kembali.',
  ]);
}

/// Server merespons dengan status error (4xx/5xx).
final class ServerException extends AppException {
  const ServerException(super.message, {this.statusCode});

  final int? statusCode;
}

/// Respons berhasil, tetapi bentuk JSON-nya tidak sesuai kontrak.
final class BadResponseException extends AppException {
  const BadResponseException([
    super.message = 'Format data dari server tidak sesuai.',
  ]);
}

/// Request dibatalkan (mis. pengguna meninggalkan layar).
final class CancelledException extends AppException {
  const CancelledException([super.message = 'Permintaan dibatalkan.']);
}

final class UnknownException extends AppException {
  const UnknownException([super.message = 'Terjadi kesalahan tak terduga.']);
}

/// Mengubah [DioException] menjadi [AppException]. Ini satu-satunya tempat
/// detail transport HTTP diterjemahkan.
AppException mapDioException(DioException error) {
  final type = error.type;

  if (error.error case final AppException inner) return inner;

  if (type == DioExceptionType.connectionTimeout ||
      type == DioExceptionType.sendTimeout ||
      type == DioExceptionType.receiveTimeout) {
    return const NetworkException(
      'Koneksi timeout. Periksa internet lalu coba lagi.',
    );
  }
  if (type == DioExceptionType.connectionError) {
    return const NetworkException(
      'Tidak dapat terhubung ke server. Periksa koneksi internet.',
    );
  }
  if (type == DioExceptionType.badCertificate) {
    return const NetworkException('Sertifikat server tidak valid.');
  }
  if (type == DioExceptionType.cancel) {
    return const CancelledException();
  }
  if (type == DioExceptionType.badResponse) {
    final status = error.response?.statusCode;
    final serverMessage = _extractServerMessage(error.response?.data);
    if (status == 401) {
      return serverMessage == null
          ? const UnauthorizedException()
          : UnauthorizedException(serverMessage);
    }
    if (status == 404) {
      return ServerException(
        serverMessage ?? 'Data tidak ditemukan.',
        statusCode: status,
      );
    }
    if (status != null && status >= 500) {
      return ServerException(
        'Server sedang bermasalah. Coba beberapa saat lagi.',
        statusCode: status,
      );
    }
    return ServerException(
      serverMessage ?? 'Permintaan gagal (kode $status).',
      statusCode: status,
    );
  }
  return const UnknownException();
}

String? _extractServerMessage(Object? data) {
  if (data is Map<String, dynamic>) {
    final message = data['message'];
    if (message is String && message.isNotEmpty) return message;
  }
  return null;
}

/// Pesan ramah pengguna untuk error apa pun yang sampai ke UI.
///
/// Riverpod 3 dapat membungkus error provider lain dalam [ProviderException],
/// jadi bungkus itu dibuka dulu.
String describeError(Object error) {
  var current = error;
  while (current is ProviderException) {
    current = current.exception;
  }
  if (current is AppException) return current.message;
  return const UnknownException().message;
}
