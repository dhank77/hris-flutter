import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import 'package:flutter_antigravity_starter_pack/core/error/app_exception.dart';

/// Mencatat setiap provider yang gagal, sehingga error tidak "hilang"
/// diam-diam ketika UI belum menampilkannya.
///
/// - [AppException] (error yang sudah diantisipasi) → warning singkat.
/// - Error lain (bug)                              → error + stack trace.
final class ProviderLogger extends ProviderObserver {
  ProviderLogger(this._logger);

  final Logger _logger;

  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    final provider = context.provider;
    final name = provider.name ?? provider.runtimeType.toString();
    if (error is AppException) {
      _logger.w('[$name] $error');
    } else {
      _logger.e('[$name] gagal', error: error, stackTrace: stackTrace);
    }
  }
}
