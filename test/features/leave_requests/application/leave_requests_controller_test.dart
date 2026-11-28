import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:flutter_antigravity_starter_pack/core/error/app_exception.dart';
import 'package:flutter_antigravity_starter_pack/features/leave_requests/application/leave_requests_controller.dart';
import 'package:flutter_antigravity_starter_pack/features/leave_requests/data/attachment_picker.dart';
import 'package:flutter_antigravity_starter_pack/features/leave_requests/data/leave_requests_repository.dart';
import 'package:flutter_antigravity_starter_pack/features/leave_requests/data/models/leave_request.dart';

class _MockRepository extends Mock implements LeaveRequestsRepository {}

void main() {
  late _MockRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = _MockRepository();
    container = ProviderContainer.test(
      overrides: [
        leaveRequestsRepositoryProvider.overrideWithValue(repository),
      ],
      retry: (_, _) => null,
    );
  });

  Future<AsyncValue<LeaveRequestsViewState>> load() async {
    // Provider autoDispose butuh listener agar tidak langsung dibuang.
    final sub = container.listen(leaveRequestsControllerProvider, (_, _) {});
    addTearDown(sub.close);
    for (var i = 0; i < 10; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    return container.read(leaveRequestsControllerProvider);
  }

  test('memuat daftar pengajuan cuti dan ringkasan', () async {
    const sample = LeaveRequest(
      id: 1,
      type: 'leave',
      startDate: '2026-12-01',
      endDate: '2026-12-03',
      days: 3,
      reason: 'Acara keluarga',
      status: 'pending',
    );
    when(() => repository.fetchAll()).thenAnswer(
      (_) async => const LeaveRequestListResult(
        leaveRequests: [sample],
        summary: LeaveRequestSummary(pending: 1, total: 1),
      ),
    );

    final state = await load();

    expect(state.requireValue.items.single.reason, 'Acara keluarga');
    expect(state.requireValue.summary.pending, 1);
  });

  test('submit mengirim pengajuan ke API dan memuat ulang daftar', () async {
    const created = LeaveRequest(
      id: 2,
      type: 'sick',
      startDate: '2026-12-05',
      endDate: '2026-12-05',
      days: 1,
      reason: 'Demam tinggi',
      status: 'pending',
    );
    when(
      () => repository.fetchAll(status: any(named: 'status')),
    ).thenAnswer((_) async => const LeaveRequestListResult());

    await load();

    when(
      () => repository.submit(
        type: 'sick',
        startDate: '2026-12-05',
        endDate: '2026-12-05',
        reason: 'Demam tinggi',
      ),
    ).thenAnswer(
      (_) async => const LeaveRequestSubmitResult(
        message: 'Pengajuan cuti berhasil dikirim ke admin.',
        leaveRequest: created,
      ),
    );
    when(() => repository.fetchAll(status: any(named: 'status'))).thenAnswer(
      (_) async => const LeaveRequestListResult(
        leaveRequests: [created],
        summary: LeaveRequestSummary(pending: 1, total: 1),
      ),
    );

    final message = await container
        .read(leaveRequestsControllerProvider.notifier)
        .submit(
          type: 'sick',
          startDate: '2026-12-05',
          endDate: '2026-12-05',
          reason: 'Demam tinggi',
        );

    expect(message, 'Pengajuan cuti berhasil dikirim ke admin.');
    final updated = container
        .read(leaveRequestsControllerProvider)
        .requireValue;
    expect(updated.items.single.id, 2);
    expect(updated.summary.pending, 1);
  });

  test('error menjadi AsyncError', () async {
    when(
      () => repository.fetchAll(),
    ).thenThrow(const NetworkException('offline'));

    final state = await load();

    expect(state.hasError, isTrue);
  });

  test(
    'fromJson: field opsional hilang memakai default dan parsing lengkap',
    () {
      final minimal = LeaveRequest.fromJson({'id': 1});
      expect(minimal.type, 'leave');
      expect(minimal.status, 'pending');
      expect(minimal.days, 1);

      final full = LeaveRequest.fromJson({
        'id': 10,
        'type': 'permission',
        'start_date': '2026-12-10',
        'end_date': '2026-12-12',
        'days': 3,
        'reason': 'Urusan keluarga',
        'status': 'rejected',
        'approver_name': 'Admin HR',
        'rejection_reason': 'Jadwal padat',
      });
      expect(full.startDate, '2026-12-10');
      expect(full.approverName, 'Admin HR');
      expect(full.rejectionReason, 'Jadwal padat');
    },
  );

  test('submit meneruskan lampiran file ke repository', () async {
    final attachment = PickedAttachment(
      name: 'surat-dokter.pdf',
      sizeBytes: 2048,
      bytes: Uint8List.fromList([1, 2, 3, 4]),
    );
    const created = LeaveRequest(
      id: 3,
      type: 'sick',
      startDate: '2026-12-15',
      endDate: '2026-12-16',
      days: 2,
      reason: 'Rawat jalan',
      attachmentUrl: 'https://example.com/storage/leave-attachments/doc.pdf',
      status: 'pending',
    );

    when(
      () => repository.fetchAll(status: any(named: 'status')),
    ).thenAnswer((_) async => const LeaveRequestListResult());
    await load();

    when(
      () => repository.submit(
        type: 'sick',
        startDate: '2026-12-15',
        endDate: '2026-12-16',
        reason: 'Rawat jalan',
        attachment: attachment,
      ),
    ).thenAnswer(
      (_) async => const LeaveRequestSubmitResult(
        message: 'Pengajuan cuti berhasil dikirim ke admin.',
        leaveRequest: created,
      ),
    );
    when(() => repository.fetchAll(status: any(named: 'status'))).thenAnswer(
      (_) async => const LeaveRequestListResult(
        leaveRequests: [created],
        summary: LeaveRequestSummary(pending: 1, total: 1),
      ),
    );

    final message = await container
        .read(leaveRequestsControllerProvider.notifier)
        .submit(
          type: 'sick',
          startDate: '2026-12-15',
          endDate: '2026-12-16',
          reason: 'Rawat jalan',
          attachment: attachment,
        );

    expect(message, 'Pengajuan cuti berhasil dikirim ke admin.');
    expect(attachment.isPdf, isTrue);
    expect(attachment.isWithinSizeLimit, isTrue);
    expect(attachment.formattedSize, '2 KB');
    final updated = container
        .read(leaveRequestsControllerProvider)
        .requireValue;
    expect(updated.items.single.attachmentUrl, isNotNull);
  });
}
