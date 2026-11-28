import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_user.freezed.dart';
part 'auth_user.g.dart';

/// Data pengguna yang sedang login (kontrak Laravel Sanctum `/auth/login` & `/auth/me`).
@freezed
abstract class AuthUser with _$AuthUser {
  const AuthUser._();

  const factory AuthUser({
    required int id,
    required String name,
    required String email,
    String? avatar,
    @Default('employee') String role,
    String? department,
    String? position,
  }) = _AuthUser;

  factory AuthUser.fromJson(Map<String, dynamic> json) =>
      _$AuthUserFromJson(json);

  String get fullName => name.trim().isEmpty ? email : name.trim();

  /// Inisial 1–2 huruf untuk avatar fallback bila pengguna belum memiliki foto.
  String get initials {
    final parts = fullName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'K';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  /// Mengubah path [avatar] (URL penuh atau path relatif storage Laravel)
  /// menjadi URL siap pakai, atau `null` bila kosong.
  String? resolveAvatarUrl(String apiBaseUrl) {
    final raw = avatar?.trim();
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }
    final baseUri = Uri.tryParse(apiBaseUrl);
    if (baseUri == null || !baseUri.hasScheme || baseUri.host.isEmpty) {
      return null;
    }
    final origin = Uri(
      scheme: baseUri.scheme,
      host: baseUri.host,
      port: baseUri.hasPort ? baseUri.port : null,
    ).toString();
    final cleaned = raw.startsWith('/') ? raw.substring(1) : raw;
    if (cleaned.startsWith('storage/')) {
      return '$origin/$cleaned';
    }
    return '$origin/storage/$cleaned';
  }
}
