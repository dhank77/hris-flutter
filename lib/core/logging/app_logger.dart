import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

/// Logger aplikasi. Filter default `Logger` hanya mencetak saat debug,
/// jadi aman dibiarkan di release build.
Logger createAppLogger() => Logger(
  printer: PrettyPrinter(methodCount: 0, dateTimeFormat: DateTimeFormat.none),
);

/// Di aplikasi berjalan, instance yang sama dengan `bootstrap()` di-inject
/// lewat override. Default di bawah dipakai oleh test.
final loggerProvider = Provider<Logger>((ref) => createAppLogger());
