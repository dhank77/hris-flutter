import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_antigravity_starter_pack/core/error/app_exception.dart';
import 'package:flutter_antigravity_starter_pack/core/location/location_service.dart';
import 'package:flutter_antigravity_starter_pack/features/attendance/data/attendance_repository.dart';
import 'package:flutter_antigravity_starter_pack/features/attendance/data/models/attendance.dart';

/// State UI untuk halaman absensi: data hari ini, riwayat, posisi GPS, dan jarak ke kantor.
class AttendanceViewState {
  const AttendanceViewState({
    required this.overview,
    required this.history,
    this.currentPosition,
    this.distanceMeters,
    this.locationError,
    this.isLocating = false,
    this.isSubmitting = false,
  });

  final AttendanceOverview overview;
  final List<Attendance> history;
  final LocationPoint? currentPosition;
  final double? distanceMeters;
  final String? locationError;
  final bool isLocating;
  final bool isSubmitting;

  OfficeLocation get office => overview.officeLocation;
  Attendance? get todayAttendance => overview.attendance;

  bool get isWithinRadius {
    final distance = distanceMeters;
    if (!office.isConfigured || distance == null) return false;
    return distance <= office.radiusMeters;
  }

  bool get hasClockedIn => todayAttendance?.clockInAt != null;
  bool get hasClockedOut => todayAttendance?.clockOutAt != null;

  bool get canClockIn =>
      !hasClockedIn &&
      isWithinRadius &&
      currentPosition != null &&
      !isLocating &&
      !isSubmitting;

  bool get canClockOut =>
      hasClockedIn &&
      !hasClockedOut &&
      isWithinRadius &&
      currentPosition != null &&
      !isLocating &&
      !isSubmitting;

  AttendanceViewState copyWith({
    AttendanceOverview? overview,
    List<Attendance>? history,
    LocationPoint? currentPosition,
    double? distanceMeters,
    String? locationError,
    bool clearLocationError = false,
    bool? isLocating,
    bool? isSubmitting,
  }) {
    return AttendanceViewState(
      overview: overview ?? this.overview,
      history: history ?? this.history,
      currentPosition: currentPosition ?? this.currentPosition,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      locationError: clearLocationError
          ? null
          : (locationError ?? this.locationError),
      isLocating: isLocating ?? this.isLocating,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

/// Controller halaman absensi: memuat ringkasan, memantau radius GPS, dan melakukan clock in/out.
class AttendanceController extends AsyncNotifier<AttendanceViewState> {
  @override
  Future<AttendanceViewState> build() async {
    final repo = ref.watch(attendanceRepositoryProvider);
    final locationService = ref.watch(locationServiceProvider);

    final results = await Future.wait([
      repo.getTodayOverview(),
      repo.getHistory(),
    ]);
    final overview = results[0] as AttendanceOverview;
    final history = results[1] as List<Attendance>;

    LocationPoint? position;
    double? distance;
    String? locationError;

    try {
      position = await locationService.getCurrentPosition();
      distance = _computeDistance(
        locationService: locationService,
        position: position,
        office: overview.officeLocation,
      );
    } catch (error) {
      locationError = describeError(error);
    }

    return AttendanceViewState(
      overview: overview,
      history: history,
      currentPosition: position,
      distanceMeters: distance,
      locationError: locationError,
    );
  }

  /// Muat ulang data absensi dari server dan perbarui lokasi GPS.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }

  /// Ambil ulang titik koordinat GPS terkini dan hitung jarak ke kantor.
  Future<void> refreshLocation() async {
    final current = state.asData?.value;
    if (current == null) {
      await refresh();
      return;
    }

    state = AsyncData(
      current.copyWith(isLocating: true, clearLocationError: true),
    );

    final locationService = ref.read(locationServiceProvider);
    try {
      final position = await locationService.getCurrentPosition();
      if (!ref.mounted) return;
      final latest = state.asData?.value ?? current;
      final distance = _computeDistance(
        locationService: locationService,
        position: position,
        office: latest.office,
      );
      state = AsyncData(
        latest.copyWith(
          currentPosition: position,
          distanceMeters: distance,
          isLocating: false,
          clearLocationError: true,
        ),
      );
    } catch (error) {
      if (!ref.mounted) return;
      final latest = state.asData?.value ?? current;
      state = AsyncData(
        latest.copyWith(isLocating: false, locationError: describeError(error)),
      );
    }
  }

  /// Kirim clock in setelah verifikasi wajah jika pegawai berada di dalam radius kantor.
  Future<String> clockIn({
    required List<double> faceEmbedding,
    String? notes,
  }) => _submitAttendance(
    isClockIn: true,
    faceEmbedding: faceEmbedding,
    notes: notes,
  );

  /// Kirim clock out setelah verifikasi wajah jika pegawai berada di dalam radius kantor.
  Future<String> clockOut({
    required List<double> faceEmbedding,
    String? notes,
  }) => _submitAttendance(
    isClockIn: false,
    faceEmbedding: faceEmbedding,
    notes: notes,
  );

  Future<String> _submitAttendance({
    required bool isClockIn,
    required List<double> faceEmbedding,
    String? notes,
  }) async {
    final current = state.asData?.value;
    if (current == null) {
      throw StateError('Data absensi belum siap.');
    }

    final position = current.currentPosition;
    if (position == null) {
      throw StateError(
        current.locationError ?? 'Lokasi GPS belum ditemukan. Perbarui lokasi.',
      );
    }

    state = AsyncData(current.copyWith(isSubmitting: true));
    final repo = ref.read(attendanceRepositoryProvider);

    try {
      final result = isClockIn
          ? await repo.clockIn(
              latitude: position.latitude,
              longitude: position.longitude,
              faceEmbedding: faceEmbedding,
              notes: notes,
            )
          : await repo.clockOut(
              latitude: position.latitude,
              longitude: position.longitude,
              faceEmbedding: faceEmbedding,
              notes: notes,
            );

      final updatedHistory = await repo.getHistory();
      if (!ref.mounted) return result.message;

      final latest = state.asData?.value ?? current;
      state = AsyncData(
        latest.copyWith(
          overview: latest.overview.copyWith(attendance: result.attendance),
          history: updatedHistory,
          isSubmitting: false,
        ),
      );
      ref.invalidate(todayAttendanceOverviewProvider);

      return result.message;
    } catch (error) {
      if (ref.mounted) {
        final latest = state.asData?.value ?? current;
        state = AsyncData(latest.copyWith(isSubmitting: false));
      }
      rethrow;
    }
  }

  double? _computeDistance({
    required LocationService locationService,
    required LocationPoint position,
    required OfficeLocation office,
  }) {
    final lat = office.latitude;
    final lng = office.longitude;
    if (!office.isConfigured || lat == null || lng == null) {
      return null;
    }
    return locationService.distanceBetweenMeters(
      startLat: position.latitude,
      startLng: position.longitude,
      endLat: lat,
      endLng: lng,
    );
  }
}

final attendanceControllerProvider =
    AsyncNotifierProvider.autoDispose<
      AttendanceController,
      AttendanceViewState
    >(AttendanceController.new);

/// Ringkasan absensi hari ini dari API (tanpa memicu pembacaan GPS).
final todayAttendanceOverviewProvider =
    FutureProvider.autoDispose<AttendanceOverview>(
      (ref) => ref.watch(attendanceRepositoryProvider).getTodayOverview(),
    );
