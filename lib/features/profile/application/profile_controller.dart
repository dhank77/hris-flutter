import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_antigravity_starter_pack/features/profile/data/models/employee_profile.dart';
import 'package:flutter_antigravity_starter_pack/features/profile/data/profile_repository.dart';

/// State profil pegawai yang sedang login (dari `GET /api/auth/me`).
///
/// Menggunakan `autoDispose` agar data profil selalu segar ketika pengguna
/// membuka halaman profil dan langsung dibersihkan saat halaman ditutup.
class ProfileController extends AsyncNotifier<EmployeeProfile> {
  @override
  Future<EmployeeProfile> build() {
    final cancelToken = CancelToken();
    ref.onDispose(cancelToken.cancel);
    return ref
        .watch(profileRepositoryProvider)
        .fetchProfile(cancelToken: cancelToken);
  }

  /// Memuat ulang profil pegawai; data lama tetap tampil sampai respons tiba.
  Future<void> refresh() async {
    final result = await AsyncValue.guard(
      () => ref.read(profileRepositoryProvider).fetchProfile(),
    );
    if (!ref.mounted) return;
    state = result;
  }
}

final profileControllerProvider =
    AsyncNotifierProvider.autoDispose<ProfileController, EmployeeProfile>(
      ProfileController.new,
    );
