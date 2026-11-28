import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_antigravity_starter_pack/core/network/api_guard.dart';
import 'package:flutter_antigravity_starter_pack/core/network/dio_provider.dart';
import 'package:flutter_antigravity_starter_pack/features/leave_requests/data/models/leave_request.dart';

/// Data source HTTP untuk fitur Pengajuan Cuti & Izin.
class LeaveRequestsApi {
  LeaveRequestsApi(this._dio);

  final Dio _dio;

  /// Ambil daftar pengajuan cuti milik pegawai beserta ringkasan statusnya.
  Future<LeaveRequestListResult> fetchAll({String? status, int limit = 30}) =>
      guardApi(() async {
        final response = await _dio.get<Object?>(
          '/leave-requests',
          queryParameters: {
            'limit': limit,
            if (status != null && status.isNotEmpty) 'status': status,
          },
        );
        return LeaveRequestListResult.fromJson(asJsonObject(response.data));
      });

  /// Kirim pengajuan cuti / sakit / izin baru ke admin.
  Future<LeaveRequestSubmitResult> submit({
    required String type,
    required String startDate,
    required String endDate,
    required String reason,
  }) => guardApi(() async {
    final response = await _dio.post<Object?>(
      '/leave-requests',
      data: {
        'type': type,
        'start_date': startDate,
        'end_date': endDate,
        'reason': reason.trim(),
      },
    );
    return LeaveRequestSubmitResult.fromJson(asJsonObject(response.data));
  });

  /// Batalkan pengajuan cuti yang masih berstatus menunggu (pending).
  Future<String> cancel(int id) => guardApi(() async {
    final response = await _dio.delete<Object?>('/leave-requests/$id');
    final json = asJsonObject(response.data);
    final message = json['message'];
    return message is String && message.isNotEmpty
        ? message
        : 'Pengajuan cuti berhasil dibatalkan.';
  });
}

final leaveRequestsApiProvider = Provider<LeaveRequestsApi>(
  (ref) => LeaveRequestsApi(ref.watch(dioProvider)),
);
