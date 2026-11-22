import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_antigravity_starter_pack/core/network/api_guard.dart';
import 'package:flutter_antigravity_starter_pack/core/network/dio_provider.dart';
import 'package:flutter_antigravity_starter_pack/features/attendance/data/models/attendance.dart';

/// Data source HTTP untuk fitur Absensi.
class AttendanceApi {
  AttendanceApi(this._dio);

  final Dio _dio;

  Future<AttendanceOverview> fetchToday() => guardApi(() async {
    final response = await _dio.get<Object?>('/attendance/today');
    final json = asJsonObject(response.data);
    return AttendanceOverview.fromJson(json);
  });

  Future<List<Attendance>> fetchHistory({int limit = 30}) => guardApi(() async {
    final response = await _dio.get<Object?>(
      '/attendance/history',
      queryParameters: {'limit': limit},
    );
    final json = asJsonObject(response.data);
    final rawList = json['attendances'];
    if (rawList is! List) return const [];
    return rawList
        .whereType<Map<String, dynamic>>()
        .map(Attendance.fromJson)
        .toList();
  });

  Future<AttendanceActionResult> clockIn({
    required double latitude,
    required double longitude,
    String? notes,
  }) => guardApi(() async {
    final response = await _dio.post<Object?>(
      '/attendance/clock-in',
      data: {
        'latitude': latitude,
        'longitude': longitude,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      },
    );
    final json = asJsonObject(response.data);
    return AttendanceActionResult.fromJson(json);
  });

  Future<AttendanceActionResult> clockOut({
    required double latitude,
    required double longitude,
    String? notes,
  }) => guardApi(() async {
    final response = await _dio.post<Object?>(
      '/attendance/clock-out',
      data: {
        'latitude': latitude,
        'longitude': longitude,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      },
    );
    final json = asJsonObject(response.data);
    return AttendanceActionResult.fromJson(json);
  });
}

final attendanceApiProvider = Provider<AttendanceApi>(
  (ref) => AttendanceApi(ref.watch(dioProvider)),
);
