import 'package:freezed_annotation/freezed_annotation.dart';

part 'attendance.freezed.dart';
part 'attendance.g.dart';

/// Data absensi harian pegawai.
@freezed
abstract class Attendance with _$Attendance {
  const factory Attendance({
    required int id,
    required String date,
    @JsonKey(name: 'clock_in_at') String? clockInAt,
    @JsonKey(name: 'clock_out_at') String? clockOutAt,
    @JsonKey(name: 'clock_in_lat') double? clockInLat,
    @JsonKey(name: 'clock_in_lng') double? clockInLng,
    @JsonKey(name: 'clock_out_lat') double? clockOutLat,
    @JsonKey(name: 'clock_out_lng') double? clockOutLng,
    @Default('present') String status,
    @JsonKey(name: 'late_minutes') @Default(0) int lateMinutes,
    String? notes,
  }) = _Attendance;

  factory Attendance.fromJson(Map<String, dynamic> json) =>
      _$AttendanceFromJson(json);
}

/// Konfigurasi titik koordinat dan radius lokasi kantor dari server.
@freezed
abstract class OfficeLocation with _$OfficeLocation {
  const factory OfficeLocation({
    @Default('Kantor Pusat') String name,
    double? latitude,
    double? longitude,
    @JsonKey(name: 'radius_meters') @Default(100) int radiusMeters,
    @JsonKey(name: 'is_configured') @Default(false) bool isConfigured,
  }) = _OfficeLocation;

  factory OfficeLocation.fromJson(Map<String, dynamic> json) =>
      _$OfficeLocationFromJson(json);
}

/// Ringkasan absensi bulan berjalan.
@freezed
abstract class AttendanceRecap with _$AttendanceRecap {
  const factory AttendanceRecap({
    @Default(0) int present,
    @Default(0) int late,
    @Default(0) int absent,
    @Default(0) int leave,
    @Default(0) int total,
  }) = _AttendanceRecap;

  factory AttendanceRecap.fromJson(Map<String, dynamic> json) =>
      _$AttendanceRecapFromJson(json);
}

/// Ringkasan absensi hari ini beserta lokasi kantor dan rekap bulanan.
@freezed
abstract class AttendanceOverview with _$AttendanceOverview {
  const factory AttendanceOverview({
    required String today,
    Attendance? attendance,
    @JsonKey(name: 'office_location') required OfficeLocation officeLocation,
    required AttendanceRecap recap,
  }) = _AttendanceOverview;

  factory AttendanceOverview.fromJson(Map<String, dynamic> json) =>
      _$AttendanceOverviewFromJson(json);
}

/// Respons setelah clock in / clock out berhasil.
@freezed
abstract class AttendanceActionResult with _$AttendanceActionResult {
  const factory AttendanceActionResult({
    required String message,
    required Attendance attendance,
    @JsonKey(name: 'distance_meters') double? distanceMeters,
  }) = _AttendanceActionResult;

  factory AttendanceActionResult.fromJson(Map<String, dynamic> json) =>
      _$AttendanceActionResultFromJson(json);
}
