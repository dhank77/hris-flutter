import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_antigravity_starter_pack/features/leave_requests/data/attachment_picker.dart';
import 'package:flutter_antigravity_starter_pack/features/leave_requests/data/leave_requests_api.dart';
import 'package:flutter_antigravity_starter_pack/features/leave_requests/data/models/leave_request.dart';

/// Pintu masuk data Pengajuan Cuti untuk layer aplikasi.
class LeaveRequestsRepository {
  LeaveRequestsRepository(this._api);

  final LeaveRequestsApi _api;

  Future<LeaveRequestListResult> fetchAll({String? status, int limit = 30}) =>
      _api.fetchAll(status: status, limit: limit);

  Future<LeaveRequestSubmitResult> submit({
    required String type,
    required String startDate,
    required String endDate,
    required String reason,
    PickedAttachment? attachment,
  }) => _api.submit(
    type: type,
    startDate: startDate,
    endDate: endDate,
    reason: reason,
    attachment: attachment,
  );

  Future<String> cancel(int id) => _api.cancel(id);
}

final leaveRequestsRepositoryProvider = Provider<LeaveRequestsRepository>(
  (ref) => LeaveRequestsRepository(ref.watch(leaveRequestsApiProvider)),
);
