import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:flutter_antigravity_starter_pack/core/error/app_exception.dart';
import 'package:flutter_antigravity_starter_pack/features/profile/data/models/employee_profile.dart';
import 'package:flutter_antigravity_starter_pack/features/profile/data/profile_repository.dart';
import 'package:flutter_antigravity_starter_pack/features/profile/presentation/profile_page.dart';

class _MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  const sampleProfile = EmployeeProfile(
    id: 12,
    name: 'Budi Santoso',
    email: 'budi@example.com',
    role: 'employee',
    department: 'Engineering',
    position: 'Senior Mobile Engineer',
    employeeId: 'EMP-012',
    phone: '081234567890',
    address: 'Jakarta Selatan',
    joinDate: '2024-01-15',
  );

  Future<void> pumpProfilePage(
    WidgetTester tester, {
    required ProfileRepository repository,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [profileRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: ProfilePage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('menampilkan data lengkap profil pegawai dari /api/auth/me', (
    tester,
  ) async {
    final repository = _MockProfileRepository();
    when(
      () => repository.fetchProfile(cancelToken: any(named: 'cancelToken')),
    ).thenAnswer((_) async => sampleProfile);

    await pumpProfilePage(tester, repository: repository);

    expect(find.text('Profil Pegawai'), findsOneWidget);
    expect(find.text('Budi Santoso'), findsOneWidget);
    expect(find.text('EMP-012'), findsOneWidget);
    expect(find.text('Senior Mobile Engineer'), findsOneWidget);
    expect(find.text('Engineering'), findsOneWidget);
    expect(find.text('Pegawai'), findsNWidgets(2));

    await tester.scrollUntilVisible(
      find.text('Jakarta Selatan'),
      200,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('15 Januari 2024'), findsOneWidget);
    expect(find.text('budi@example.com'), findsOneWidget);
    expect(find.text('081234567890'), findsOneWidget);
    expect(find.text('Jakarta Selatan'), findsOneWidget);
  });

  testWidgets('menampilkan error dan bisa coba lagi', (tester) async {
    final repository = _MockProfileRepository();
    var calls = 0;
    when(
      () => repository.fetchProfile(cancelToken: any(named: 'cancelToken')),
    ).thenAnswer((_) async {
      calls++;
      if (calls == 1) {
        throw const NetworkException('Gagal terhubung ke server.');
      }
      return sampleProfile;
    });

    await pumpProfilePage(tester, repository: repository);

    expect(find.text('Gagal terhubung ke server.'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);

    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();

    expect(find.text('Budi Santoso'), findsOneWidget);
    expect(calls, 2);
  });

  testWidgets('tombol refresh memuat ulang data profil', (tester) async {
    final repository = _MockProfileRepository();
    when(
      () => repository.fetchProfile(cancelToken: any(named: 'cancelToken')),
    ).thenAnswer((_) async => sampleProfile);

    await pumpProfilePage(tester, repository: repository);

    await tester.tap(find.byKey(const Key('profile.refresh')));
    await tester.pumpAndSettle();

    verify(
      () => repository.fetchProfile(cancelToken: any(named: 'cancelToken')),
    ).called(2);
  });
}
