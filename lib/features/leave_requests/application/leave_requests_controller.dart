import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_antigravity_starter_pack/features/leave_requests/data/leave_requests_repository.dart';
import 'package:flutter_antigravity_starter_pack/features/leave_requests/data/models/leave_request.dart';

/// State tampilan halaman Pengajuan Cuti & Izin.
class LeaveRequestsViewState {
  const LeaveRequestsViewState({
    required this.items,
    required this.summary,
    this.selectedStatus,
    this.isSubmitting = false,
    this.cancellingId,
  });

  final List<LeaveRequest> items;
  final LeaveRequestSummary summary;

  /// Filter status aktif: `null` (semua), `pending`, `approved`, atau `rejected`.
  final String? selectedStatus;
  final bool isSubmitting;
  final int? cancellingId;

  LeaveRequestsViewState copyWith({
    List<LeaveRequest>? items,
    LeaveRequestSummary? summary,
    String? selectedStatus,
    bool clearSelectedStatus = false,
    bool? isSubmitting,
    int? cancellingId,
    bool clearCancellingId = false,
  }) {
    return LeaveRequestsViewState(
      items: items ?? this.items,
      summary: summary ?? this.summary,
      selectedStatus: clearSelectedStatus
          ? null
          : (selectedStatus ?? this.selectedStatus),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      cancellingId: clearCancellingId
          ? null
          : (cancellingId ?? this.cancellingId),
    );
  }
}

/// Controller halaman Pengajuan Cuti & Izin.
///
/// `autoDispose`: data dibuang saat halaman ditutup dan dimuat ulang saat dibuka.
class LeaveRequestsController extends AsyncNotifier<LeaveRequestsViewState> {
  @override
  Future<LeaveRequestsViewState> build() async {
    final result = await ref.watch(leaveRequestsRepositoryProvider).fetchAll();
    return LeaveRequestsViewState(
      items: result.leaveRequests,
      summary: result.summary,
    );
  }

  /// Muat ulang daftar pengajuan sesuai filter status yang sedang aktif.
  Future<void> refresh() async {
    final currentStatus = state.asData?.value.selectedStatus;
    final result = await AsyncValue.guard(() async {
      final fetched = await ref
          .read(leaveRequestsRepositoryProvider)
          .fetchAll(status: currentStatus);
      return LeaveRequestsViewState(
        items: fetched.leaveRequests,
        summary: fetched.summary,
        selectedStatus: currentStatus,
      );
    });
    if (!ref.mounted) return;
    state = result;
  }

  /// Ubah filter status dan muat ulang daftar dari server.
  Future<void> setStatusFilter(String? status) async {
    final current = state.asData?.value;
    if (current != null && current.selectedStatus == status) return;

    if (current != null) {
      state = AsyncData(
        current.copyWith(
          selectedStatus: status,
          clearSelectedStatus: status == null,
        ),
      );
    }

    final result = await AsyncValue.guard(() async {
      final fetched = await ref
          .read(leaveRequestsRepositoryProvider)
          .fetchAll(status: status);
      return LeaveRequestsViewState(
        items: fetched.leaveRequests,
        summary: fetched.summary,
        selectedStatus: status,
      );
    });
    if (!ref.mounted) return;
    state = result;
  }

  /// Kirim pengajuan cuti baru ke admin melalui API lalu muat ulang daftar.
  Future<String> submit({
    required String type,
    required String startDate,
    required String endDate,
    required String reason,
  }) async {
    final current = state.asData?.value;
    if (current != null) {
      state = AsyncData(current.copyWith(isSubmitting: true));
    }

    final repo = ref.read(leaveRequestsRepositoryProvider);
    try {
      final response = await repo.submit(
        type: type,
        startDate: startDate,
        endDate: endDate,
        reason: reason,
      );

      final filterStatus = current?.selectedStatus;
      final fetched = await repo.fetchAll(status: filterStatus);
      if (!ref.mounted) return response.message;

      state = AsyncData(
        LeaveRequestsViewState(
          items: fetched.leaveRequests,
          summary: fetched.summary,
          selectedStatus: filterStatus,
        ),
      );
      return response.message;
    } catch (_) {
      if (ref.mounted && current != null) {
        final latest = state.asData?.value ?? current;
        state = AsyncData(latest.copyWith(isSubmitting: false));
      }
      rethrow;
    }
  }

  /// Batalkan pengajuan cuti berstatus menunggu lalu muat ulang daftar.
  Future<String> cancel(int id) async {
    final current = state.asData?.value;
    if (current != null) {
      state = AsyncData(current.copyWith(cancellingId: id));
    }

    final repo = ref.read(leaveRequestsRepositoryProvider);
    try {
      final message = await repo.cancel(id);
      final filterStatus = current?.selectedStatus;
      final fetched = await repo.fetchAll(status: filterStatus);
      if (!ref.mounted) return message;

      state = AsyncData(
        LeaveRequestsViewState(
          items: fetched.leaveRequests,
          summary: fetched.summary,
          selectedStatus: filterStatus,
        ),
      );
      return message;
    } catch (_) {
      if (ref.mounted && current != null) {
        final latest = state.asData?.value ?? current;
        state = AsyncData(latest.copyWith(clearCancellingId: true));
      }
      rethrow;
    }
  }
}

final leaveRequestsControllerProvider =
    AsyncNotifierProvider.autoDispose<
      LeaveRequestsController,
      LeaveRequestsViewState
    >(LeaveRequestsController.new);
