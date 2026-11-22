import 'package:freezed_annotation/freezed_annotation.dart';

part 'face_profile.freezed.dart';
part 'face_profile.g.dart';

/// Profil embedding wajah pegawai yang tersimpan di server Laravel.
@freezed
abstract class FaceProfile with _$FaceProfile {
  const factory FaceProfile({
    required int id,
    @JsonKey(name: 'model_version')
    @Default('mobilefacenet')
    String modelVersion,
    @JsonKey(name: 'registered_at') String? registeredAt,
    @Default(<double>[]) List<double> embedding,
  }) = _FaceProfile;

  factory FaceProfile.fromJson(Map<String, dynamic> json) =>
      _$FaceProfileFromJson(json);
}

/// Status registrasi wajah dari `GET /api/face`.
@freezed
abstract class FaceStatus with _$FaceStatus {
  const factory FaceStatus({
    @Default(false) bool registered,
    @JsonKey(name: 'face_profile') FaceProfile? faceProfile,
  }) = _FaceStatus;

  factory FaceStatus.fromJson(Map<String, dynamic> json) =>
      _$FaceStatusFromJson(json);
}

/// Respons registrasi wajah dari `POST /api/face/register`.
@freezed
abstract class FaceRegisterResult with _$FaceRegisterResult {
  const factory FaceRegisterResult({
    @Default('') String message,
    @Default(true) bool registered,
    @JsonKey(name: 'face_profile') FaceProfile? faceProfile,
  }) = _FaceRegisterResult;

  factory FaceRegisterResult.fromJson(Map<String, dynamic> json) =>
      _$FaceRegisterResultFromJson(json);
}

/// Respons verifikasi pengenalan wajah dari `POST /api/face/verify`.
@freezed
abstract class FaceVerifyResult with _$FaceVerifyResult {
  const factory FaceVerifyResult({
    @Default(false) bool matched,
    @Default(0.0) double similarity,
    @Default(0.0) double distance,
    @Default(0.75) double threshold,
    @Default('') String message,
  }) = _FaceVerifyResult;

  factory FaceVerifyResult.fromJson(Map<String, dynamic> json) =>
      _$FaceVerifyResultFromJson(json);
}
