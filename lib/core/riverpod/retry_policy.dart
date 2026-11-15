import 'package:flutter_antigravity_starter_pack/core/error/app_exception.dart';

/// Kebijakan retry otomatis untuk SEMUA provider (fitur Riverpod 3).
///
/// Default Riverpod mengulang provider yang gagal hingga 10x untuk error apa
/// pun. Di sini dibatasi: hanya error jaringan, maksimal 2x (jeda 1s, 2s).
/// Error lain (401, 404, format JSON salah) langsung ditampilkan ke UI.
Duration? appRetryPolicy(int retryCount, Object error) {
  if (error is NetworkException && retryCount < 2) {
    return Duration(seconds: retryCount + 1);
  }
  return null;
}
