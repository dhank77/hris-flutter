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
}
