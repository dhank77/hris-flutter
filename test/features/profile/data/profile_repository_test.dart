import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_antigravity_starter_pack/core/error/app_exception.dart';
import 'package:flutter_antigravity_starter_pack/features/profile/data/models/employee_profile.dart';
import 'package:flutter_antigravity_starter_pack/features/profile/data/profile_api.dart';
import 'package:flutter_antigravity_starter_pack/features/profile/data/profile_repository.dart';

import '../../../helpers/fakes.dart';

void main() {
  Dio createDio(FakeHttpAdapter adapter) =>
      Dio(BaseOptions(baseUrl: 'https://hris.test/api'))
        ..httpClientAdapter = adapter;

  group('EmployeeProfile.fromJson', () {
    test('mem-parse payload lengkap dari /api/auth/me', () {
      final profile = EmployeeProfile.fromJson({
        'id': 7,
        'name': 'Siti Rahma',
        'email': 'siti@example.com',
        'avatar': 'avatars/siti.png',
        'role': 'manager',
        'department': 'Human Resources',
        'position': 'HR Manager',
        'employee_id': 'EMP-007',
        'phone': '081234567890',
        'address': 'Jl. Sudirman No. 10, Jakarta',
        'join_date': '2024-03-15',
        'email_verified_at': '2024-03-15T08:00:00Z',
        'created_at': '2024-03-15T07:00:00Z',
      });

      expect(profile.id, 7);
      expect(profile.fullName, 'Siti Rahma');
      expect(profile.initials, 'SR');
      expect(profile.roleLabel, 'Manajer');
      expect(profile.department, 'Human Resources');
      expect(profile.position, 'HR Manager');
      expect(profile.employeeId, 'EMP-007');
      expect(profile.phone, '081234567890');
      expect(profile.address, 'Jl. Sudirman No. 10, Jakarta');
      expect(
        profile.resolveAvatarUrl('http://127.0.0.1:8000/api'),
        'http://127.0.0.1:8000/storage/avatars/siti.png',
      );
    });

    test('field opsional hilang memakai nilai default', () {
      final profile = EmployeeProfile.fromJson({
        'id': 1,
        'name': 'Budi',
        'email': 'budi@example.com',
      });

      expect(profile.role, 'employee');
      expect(profile.roleLabel, 'Pegawai');
      expect(profile.initials, 'B');
      expect(profile.department, isNull);
      expect(profile.position, isNull);
      expect(profile.employeeId, isNull);
      expect(profile.resolveAvatarUrl('http://127.0.0.1:8000/api'), isNull);
    });

    test('avatar URL penuh dikembalikan apa adanya', () {
      const profile = EmployeeProfile(
        id: 2,
        name: 'Andi',
        email: 'andi@example.com',
        avatar: 'https://cdn.example.com/andi.jpg',
      );

      expect(
        profile.resolveAvatarUrl('http://127.0.0.1:8000/api'),
        'https://cdn.example.com/andi.jpg',
      );
    });

    test('field wajib hilang melempar TypeError', () {
      expect(
        () => EmployeeProfile.fromJson({'id': 1}),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('ProfileRepository', () {
    test('memanggil GET /auth/me dan mem-parse wrapper user', () async {
      final adapter = FakeHttpAdapter((options) {
        expect(options.method, 'GET');
        expect(options.path, '/auth/me');
        return const FakeResponse(200, {
          'user': {
            'id': 1,
            'name': 'Budi Santoso',
            'email': 'budi@example.com',
            'role': 'employee',
            'department': 'Engineering',
            'position': 'Mobile Engineer',
          },
        });
      });
      final repo = ProfileRepository(ProfileApi(createDio(adapter)));

      final profile = await repo.fetchProfile();

      expect(profile.id, 1);
      expect(profile.fullName, 'Budi Santoso');
      expect(profile.department, 'Engineering');
      expect(profile.position, 'Mobile Engineer');
    });

    test('mendukung wrapper data maupun objek langsung', () async {
      final adapter = FakeHttpAdapter((options) {
        return const FakeResponse(200, {
          'data': {
            'id': 2,
            'name': 'Dewi Lestari',
            'email': 'dewi@example.com',
          },
        });
      });
      final repo = ProfileRepository(ProfileApi(createDio(adapter)));

      final profile = await repo.fetchProfile();
      expect(profile.fullName, 'Dewi Lestari');

      final directAdapter = FakeHttpAdapter((options) {
        return const FakeResponse(200, {
          'id': 3,
          'name': 'Rudi Hartono',
          'email': 'rudi@example.com',
        });
      });
      final directRepo = ProfileRepository(
        ProfileApi(createDio(directAdapter)),
      );

      final directProfile = await directRepo.fetchProfile();
      expect(directProfile.fullName, 'Rudi Hartono');
    });

    test('memetakan 401 ke UnauthorizedException', () async {
      final adapter = FakeHttpAdapter(
        (_) => const FakeResponse(401, {'message': 'Unauthenticated.'}),
      );
      final repo = ProfileRepository(ProfileApi(createDio(adapter)));

      await expectLater(
        repo.fetchProfile,
        throwsA(isA<UnauthorizedException>()),
      );
    });
  });
}
