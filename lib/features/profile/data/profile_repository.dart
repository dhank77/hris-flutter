import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_antigravity_starter_pack/features/profile/data/models/employee_profile.dart';
import 'package:flutter_antigravity_starter_pack/features/profile/data/profile_api.dart';

/// Pintu masuk data Profil Pegawai untuk layer aplikasi.
class ProfileRepository {
  ProfileRepository(this._api);

  final ProfileApi _api;

  Future<EmployeeProfile> fetchProfile({CancelToken? cancelToken}) =>
      _api.fetchProfile(cancelToken: cancelToken);
}

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(profileApiProvider)),
);
