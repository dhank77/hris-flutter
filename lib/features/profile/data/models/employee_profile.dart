import 'package:freezed_annotation/freezed_annotation.dart';

part 'employee_profile.freezed.dart';
part 'employee_profile.g.dart';

/// Data profil pegawai yang sedang login (kontrak Laravel `GET /api/auth/me`).
@freezed
abstract class EmployeeProfile with _$EmployeeProfile {
  const EmployeeProfile._();

  const factory EmployeeProfile({
    required int id,
    required String name,
    required String email,
    String? avatar,
    @Default('employee') String role,
    String? department,
    String? position,
    @JsonKey(name: 'employee_id') String? employeeId,
    String? phone,
    String? address,
    @JsonKey(name: 'join_date') String? joinDate,
    @JsonKey(name: 'email_verified_at') String? emailVerifiedAt,
    @JsonKey(name: 'created_at') String? createdAt,
  }) = _EmployeeProfile;

  factory EmployeeProfile.fromJson(Map<String, dynamic> json) =>
      _$EmployeeProfileFromJson(json);

  /// Nama tampilan: memakai [name] bila tidak kosong, jika kosong pakai [email].
  String get fullName => name.trim().isEmpty ? email : name.trim();

  /// Inisial 1–2 huruf untuk avatar fallback.
  String get initials {
    final parts = fullName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'P';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  /// Label peran dalam Bahasa Indonesia.
  String get roleLabel => switch (role.toLowerCase()) {
    'admin' || 'super_admin' || 'superadmin' => 'Administrator',
    'hr' || 'hrd' => 'HRD',
    'manager' => 'Manajer',
    'employee' => 'Pegawai',
    final other when other.isNotEmpty =>
      '${other[0].toUpperCase()}${other.substring(1)}',
    _ => 'Pegawai',
  };

  /// Mengubah path avatar (URL penuh maupun path relatif storage Laravel)
  /// menjadi URL siap pakai, atau `null` bila tidak ada avatar.
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
