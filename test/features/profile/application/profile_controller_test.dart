import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:flutter_antigravity_starter_pack/core/error/app_exception.dart';
import 'package:flutter_antigravity_starter_pack/features/profile/application/profile_controller.dart';
import 'package:flutter_antigravity_starter_pack/features/profile/data/models/employee_profile.dart';
import 'package:flutter_antigravity_starter_pack/features/profile/data/profile_repository.dart';

import '../../../helpers/fakes.dart';

class _MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late _MockProfileRepository repository;
  late ProviderContainer container;

  const sampleProfile = EmployeeProfile(
    id: 1,
    name: 'Budi Santoso',
    email: 'budi@example.com',
    department: 'Engineering',
    position: 'Software Engineer',
  );

  setUp(() {
    repository = _MockProfileRepository();
    container = ProviderContainer.test(
      overrides: [profileRepositoryProvider.overrideWithValue(repository)],
      retry: (_, _) => null,
    );
  });

  Future<AsyncValue<EmployeeProfile>> load() async {
    final sub = container.listen(profileControllerProvider, (_, _) {});
    addTearDown(sub.close);
    await settle();
    return container.read(profileControllerProvider);
  }

  test('memuat data profil pegawai dari repository', () async {
    when(
      () => repository.fetchProfile(cancelToken: any(named: 'cancelToken')),
    ).thenAnswer((_) async => sampleProfile);

    final state = await load();

    expect(state.requireValue, sampleProfile);
  });

  test('error dari repository menjadi AsyncError', () async {
    when(
      () => repository.fetchProfile(cancelToken: any(named: 'cancelToken')),
    ).thenThrow(const NetworkException('offline'));

    final state = await load();

    expect(state.hasError, isTrue);
    expect(state.error, isA<NetworkException>());
  });

  test('refresh memperbarui state dengan profil terbaru', () async {
    const updatedProfile = EmployeeProfile(
      id: 1,
      name: 'Budi Santoso',
      email: 'budi@example.com',
      department: 'Platform',
      position: 'Lead Engineer',
    );
    var callCount = 0;
    when(
      () => repository.fetchProfile(cancelToken: any(named: 'cancelToken')),
    ).thenAnswer(
      (_) async => ++callCount == 1 ? sampleProfile : updatedProfile,
    );

    await load();
    await container.read(profileControllerProvider.notifier).refresh();

    expect(
      container.read(profileControllerProvider).requireValue,
      updatedProfile,
    );
  });
}
