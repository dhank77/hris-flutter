import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_antigravity_starter_pack/features/attendance/data/attendance_api.dart';
import 'package:flutter_antigravity_starter_pack/features/attendance/data/models/attendance.dart';

/// Repository fitur Absensi.
class AttendanceRepository {
  AttendanceRepository(this._api);

  final AttendanceApi _api;

  Future<AttendanceOverview> getTodayOverview() => _api.fetchToday();

  Future<List<Attendance>> getHistory({int limit = 30}) =>
      _api.fetchHistory(limit: limit);

  Future<AttendanceActionResult> clockIn({
    required double latitude,
    required double longitude,
    required List<double> faceEmbedding,
    String? notes,
  }) => _api.clockIn(
    latitude: latitude,
    longitude: longitude,
    faceEmbedding: faceEmbedding,
    notes: notes,
  );

  Future<AttendanceActionResult> clockOut({
    required double latitude,
    required double longitude,
    required List<double> faceEmbedding,
    String? notes,
  }) => _api.clockOut(
    latitude: latitude,
    longitude: longitude,
    faceEmbedding: faceEmbedding,
    notes: notes,
  );
}

final attendanceRepositoryProvider = Provider<AttendanceRepository>(
  (ref) => AttendanceRepository(ref.watch(attendanceApiProvider)),
);
