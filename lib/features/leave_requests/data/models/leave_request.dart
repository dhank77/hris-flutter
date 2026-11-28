import 'package:freezed_annotation/freezed_annotation.dart';

part 'leave_request.freezed.dart';
part 'leave_request.g.dart';

/// Data pengajuan cuti / sakit / izin pegawai.
@freezed
abstract class LeaveRequest with _$LeaveRequest {
  const factory LeaveRequest({
    required int id,
    @Default('leave') String type,
    @JsonKey(name: 'start_date') @Default('') String startDate,
    @JsonKey(name: 'end_date') @Default('') String endDate,
    @Default(1) int days,
    @Default('') String reason,
    @JsonKey(name: 'attachment_url') String? attachmentUrl,
    @Default('pending') String status,
    @JsonKey(name: 'approver_name') String? approverName,
    @JsonKey(name: 'approved_at') String? approvedAt,
    @JsonKey(name: 'rejection_reason') String? rejectionReason,
    @JsonKey(name: 'created_at') String? createdAt,
  }) = _LeaveRequest;

  factory LeaveRequest.fromJson(Map<String, dynamic> json) =>
      _$LeaveRequestFromJson(json);
}

/// Ringkasan jumlah pengajuan berdasarkan status.
@freezed
abstract class LeaveRequestSummary with _$LeaveRequestSummary {
  const factory LeaveRequestSummary({
    @Default(0) int pending,
    @Default(0) int approved,
    @Default(0) int rejected,
    @Default(0) int total,
  }) = _LeaveRequestSummary;

  factory LeaveRequestSummary.fromJson(Map<String, dynamic> json) =>
      _$LeaveRequestSummaryFromJson(json);
}

/// Respons daftar pengajuan cuti beserta ringkasannya.
@freezed
abstract class LeaveRequestListResult with _$LeaveRequestListResult {
  const factory LeaveRequestListResult({
    @JsonKey(name: 'leave_requests')
    @Default(<LeaveRequest>[])
    List<LeaveRequest> leaveRequests,
    @Default(LeaveRequestSummary()) LeaveRequestSummary summary,
  }) = _LeaveRequestListResult;

  factory LeaveRequestListResult.fromJson(Map<String, dynamic> json) =>
      _$LeaveRequestListResultFromJson(json);
}

/// Respons setelah pengajuan cuti berhasil dikirim ke admin.
@freezed
abstract class LeaveRequestSubmitResult with _$LeaveRequestSubmitResult {
  const factory LeaveRequestSubmitResult({
    required String message,
    @JsonKey(name: 'leave_request') required LeaveRequest leaveRequest,
  }) = _LeaveRequestSubmitResult;

  factory LeaveRequestSubmitResult.fromJson(Map<String, dynamic> json) =>
      _$LeaveRequestSubmitResultFromJson(json);
}
