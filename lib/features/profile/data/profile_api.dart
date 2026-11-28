import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_antigravity_starter_pack/core/network/api_guard.dart';
import 'package:flutter_antigravity_starter_pack/core/network/dio_provider.dart';
import 'package:flutter_antigravity_starter_pack/features/profile/data/models/employee_profile.dart';

/// Data source HTTP untuk fitur Profil Pegawai (`GET /api/auth/me`).
class ProfileApi {
  ProfileApi(this._dio);

  final Dio _dio;

  /// Mengambil data profil pegawai yang sedang login dari endpoint `/auth/me`.
  /// Mendukung respons Laravel berbentuk `{"user": {...}}`, `{"data": {...}}`,
  /// maupun objek JSON langsung `{...}`.
  Future<EmployeeProfile> fetchProfile({CancelToken? cancelToken}) =>
      guardApi(() async {
        final response = await _dio.get<Object?>(
          '/auth/me',
          cancelToken: cancelToken,
        );
        final json = asJsonObject(response.data);
        final nested = json['user'] ?? json['data'];
        final payload = nested is Map<String, dynamic> ? nested : json;
        return EmployeeProfile.fromJson(payload);
      });
}

final profileApiProvider = Provider<ProfileApi>(
  (ref) => ProfileApi(ref.watch(dioProvider)),
);
