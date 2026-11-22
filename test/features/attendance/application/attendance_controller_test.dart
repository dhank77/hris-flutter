import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:flutter_antigravity_starter_pack/core/error/app_exception.dart';
import 'package:flutter_antigravity_starter_pack/core/location/location_service.dart';
import 'package:flutter_antigravity_starter_pack/features/attendance/application/attendance_controller.dart';
import 'package:flutter_antigravity_starter_pack/features/attendance/data/attendance_repository.dart';
import 'package:flutter_antigravity_starter_pack/features/attendance/data/models/attendance.dart';

class _MockRepository extends Mock implements AttendanceRepository {}

class _FakeLocationService implements LocationService {
  _FakeLocationService({required this.point, required this.distance});

  LocationPoint point;
  double distance;

  @override
  Future<LocationPoint> getCurrentPosition() async => point;

  @override
  double distanceBetweenMeters({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) => distance;
}

void main() {
  late _MockRepository repository;
  late _FakeLocationService locationService;
  late ProviderContainer container;

  const configuredOffice = OfficeLocation(
    name: 'Kantor Pusat',
    latitude: -6.2088,
    longitude: 106.8456,
    radiusMeters: 100,
    isConfigured: true,
  );

  const emptyOverview = AttendanceOverview(
    today: '2026-11-22',
    officeLocation: configuredOffice,
    recap: AttendanceRecap(
      present: 10,
      late: 1,
      absent: 0,
      leave: 0,
      total: 11,
    ),
  );

  setUp(() {
    repository = _MockRepository();
    locationService = _FakeLocationService(
      point: const LocationPoint(latitude: -6.2088, longitude: 106.8456),
      distance: 25,
    );
    container = ProviderContainer.test(
      overrides: [
        attendanceRepositoryProvider.overrideWithValue(repository),
        locationServiceProvider.overrideWithValue(locationService),
      ],
      retry: (_, _) => null,
    );
  });

  Future<AsyncValue<AttendanceViewState>> load() async {
    final sub = container.listen(attendanceControllerProvider, (_, _) {});
    addTearDown(sub.close);
    for (var i = 0; i < 10; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    return container.read(attendanceControllerProvider);
  }

  test('memuat data absensi dan menandai dalam radius kantor', () async {
    when(
      () => repository.getTodayOverview(),
    ).thenAnswer((_) async => emptyOverview);
    when(() => repository.getHistory()).thenAnswer((_) async => const []);

    final state = await load();
    final value = state.requireValue;

    expect(value.isWithinRadius, isTrue);
    expect(value.canClockIn, isTrue);
    expect(value.canClockOut, isFalse);
    expect(value.distanceMeters, 25);
  });

  test('pegawai di luar radius tidak dapat clock in', () async {
    locationService.distance = 350;
    when(
      () => repository.getTodayOverview(),
    ).thenAnswer((_) async => emptyOverview);
    when(() => repository.getHistory()).thenAnswer((_) async => const []);

    final state = await load();
    final value = state.requireValue;

    expect(value.isWithinRadius, isFalse);
    expect(value.canClockIn, isFalse);
  });

  test('clockIn memperbarui state absensi hari ini', () async {
    when(
      () => repository.getTodayOverview(),
    ).thenAnswer((_) async => emptyOverview);
    when(() => repository.getHistory()).thenAnswer((_) async => const []);

    const clockedIn = Attendance(
      id: 1,
      date: '2026-11-22',
      clockInAt: '2026-11-22T08:00:00+08:00',
      status: 'present',
    );
    when(
      () => repository.clockIn(
        latitude: -6.2088,
        longitude: 106.8456,
        notes: 'Hadir',
      ),
    ).thenAnswer(
      (_) async => const AttendanceActionResult(
        message: 'Clock in berhasil.',
        attendance: clockedIn,
        distanceMeters: 25,
      ),
    );

    await load();
    final message = await container
        .read(attendanceControllerProvider.notifier)
        .clockIn(notes: 'Hadir');

    final updated = container.read(attendanceControllerProvider).requireValue;
    expect(message, 'Clock in berhasil.');
    expect(updated.hasClockedIn, isTrue);
    expect(updated.canClockOut, isTrue);
  });

  test('error repository menjadi AsyncError', () async {
    when(
      () => repository.getTodayOverview(),
    ).thenThrow(const NetworkException('offline'));
    when(() => repository.getHistory()).thenAnswer((_) async => const []);

    final state = await load();

    expect(state.hasError, isTrue);
  });

  test('AttendanceOverview.fromJson mem-parse JSON server Laravel', () {
    final overview = AttendanceOverview.fromJson({
      'today': '2026-11-22',
      'attendance': null,
      'office_location': {
        'name': 'Kantor Pusat',
        'latitude': -6.2088,
        'longitude': 106.8456,
        'radius_meters': 150,
        'is_configured': true,
      },
      'recap': {'present': 5, 'late': 1, 'absent': 0, 'leave': 0, 'total': 6},
    });

    expect(overview.officeLocation.name, 'Kantor Pusat');
    expect(overview.officeLocation.radiusMeters, 150);
    expect(overview.officeLocation.isConfigured, isTrue);
    expect(overview.recap.present, 5);
  });
}
