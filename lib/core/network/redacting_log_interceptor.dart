import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

/// Log HTTP ringkas yang TIDAK mencetak header Authorization maupun body.
/// Body bisa berisi password/token/data pribadi, jadi hanya metode, URL,
/// status, dan durasi yang dicatat.
class RedactingLogInterceptor extends Interceptor {
  RedactingLogInterceptor(this._logger);

  final Logger _logger;
  static const _startKey = 'logStartedAt';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startKey] = DateTime.now();
    _logger.d('→ ${options.method} ${_safeUri(options.uri)}');
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final options = response.requestOptions;
    _logger.d(
      '← ${response.statusCode} ${options.method} ${_safeUri(options.uri)} '
      '(${_elapsed(options)} ms)',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final options = err.requestOptions;
    _logger.w(
      '✗ ${err.response?.statusCode ?? err.type.name} ${options.method} '
      '${_safeUri(options.uri)} (${_elapsed(options)} ms)',
    );
    handler.next(err);
  }

  int _elapsed(RequestOptions options) {
    final start = options.extra[_startKey];
    if (start is! DateTime) return 0;
    return DateTime.now().difference(start).inMilliseconds;
  }

  /// Query string bisa memuat data sensitif; tampilkan path saja.
  String _safeUri(Uri uri) => '${uri.origin}${uri.path}';
}
