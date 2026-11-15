import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pasangan token hasil refresh.
typedef TokenPair = ({String accessToken, String refreshToken});

/// Cara menukar refresh token dengan token baru. Setiap backend punya
/// endpoint dan bentuk respons sendiri, jadi core tidak mengasumsikannya.
///
/// [client] adalah Dio TANPA `AuthInterceptor`, supaya refresh tidak
/// berputar-putar. Kembalikan `null` bila refresh ditolak.
typedef TokenRefresher =
    Future<TokenPair?> Function(Dio client, String refreshToken);

/// Default `null` → tidak ada refresh; respons 401 langsung dianggap sesi
/// berakhir. Fitur auth meng-override provider ini, contoh:
///
/// ```dart
/// tokenRefresherProvider.overrideWithValue((client, refreshToken) async {
///   final res = await client.post<Map<String, dynamic>>(
///     '/auth/refresh',
///     data: {'refreshToken': refreshToken},
///   );
///   final access = res.data?['accessToken'];
///   final refresh = res.data?['refreshToken'];
///   if (access is! String || refresh is! String) return null;
///   return (accessToken: access, refreshToken: refresh);
/// }),
/// ```
///
/// Implementasi lengkap untuk DummyJSON ada di branch `example`.
final tokenRefresherProvider = Provider<TokenRefresher?>((ref) => null);
