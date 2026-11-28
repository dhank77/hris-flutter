import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_antigravity_starter_pack/app/theme/app_tokens.dart';
import 'package:flutter_antigravity_starter_pack/core/error/app_exception.dart';
import 'package:flutter_antigravity_starter_pack/core/extensions/context_extensions.dart';
import 'package:flutter_antigravity_starter_pack/core/widgets/async_value_view.dart';
import 'package:flutter_antigravity_starter_pack/core/widgets/state_views.dart';
import 'package:flutter_antigravity_starter_pack/features/leave_requests/application/leave_requests_controller.dart';
import 'package:flutter_antigravity_starter_pack/features/leave_requests/data/models/leave_request.dart';

/// Halaman daftar dan pengajuan Cuti & Izin yang dikirim ke admin via API.
class LeaveRequestsPage extends ConsumerWidget {
  const LeaveRequestsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewState = ref.watch(leaveRequestsControllerProvider);
    final controller = ref.read(leaveRequestsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Cuti & Izin')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openFormSheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Ajukan Cuti'),
      ),
      body: AsyncValueView<LeaveRequestsViewState>(
        value: viewState,
        onRetry: () => ref.invalidate(leaveRequestsControllerProvider),
        data: (data) => RefreshIndicator(
          onRefresh: controller.refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              96,
            ),
            children: [
              _SummarySection(summary: data.summary),
              const SizedBox(height: AppSpacing.md),
              _StatusFilterBar(
                selectedStatus: data.selectedStatus,
                onSelected: controller.setStatusFilter,
              ),
              const SizedBox(height: AppSpacing.md),
              if (data.items.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: AppSpacing.xl),
                  child: EmptyView(
                    icon: Icons.event_available_outlined,
                    message:
                        'Belum ada pengajuan cuti atau izin.\nTekan "Ajukan Cuti" untuk mengirim pengajuan ke admin.',
                  ),
                )
              else
                for (final item in data.items) ...[
                  _LeaveRequestCard(
                    item: item,
                    isCancelling: data.cancellingId == item.id,
                    onCancel: item.status == 'pending'
                        ? () => _confirmCancel(context, ref, item)
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openFormSheet(BuildContext context, WidgetRef ref) async {
    final submittedMessage = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const _LeaveRequestFormSheet(),
    );
    if (submittedMessage != null && context.mounted) {
      context.showSnackBar(submittedMessage);
    }
  }

  Future<void> _confirmCancel(
    BuildContext context,
    WidgetRef ref,
    LeaveRequest item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Batalkan Pengajuan?'),
        content: Text(
          'Pengajuan ${_typeLabel(item.type).toLowerCase()} untuk tanggal '
          '${_formatDateRange(item.startDate, item.endDate)} akan dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Tidak'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Batalkan'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      final message = await ref
          .read(leaveRequestsControllerProvider.notifier)
          .cancel(item.id);
      if (context.mounted) {
        context.showSnackBar(message);
      }
    } catch (error) {
      if (context.mounted) {
        context.showSnackBar(describeError(error));
      }
    }
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({required this.summary});

  final LeaveRequestSummary summary;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      children: [
        Expanded(
          child: _SummaryTile(
            label: 'Menunggu',
            count: summary.pending,
            color: colors.tertiary,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _SummaryTile(
            label: 'Disetujui',
            count: summary.approved,
            color: colors.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _SummaryTile(
            label: 'Ditolak',
            count: summary.rejected,
            color: colors.error,
          ),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.md,
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: context.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: context.textTheme.labelMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusFilterBar extends StatelessWidget {
  const _StatusFilterBar({
    required this.selectedStatus,
    required this.onSelected,
  });

  final String? selectedStatus;
  final ValueChanged<String?> onSelected;

  static const _options = [
    (null, 'Semua'),
    ('pending', 'Menunggu'),
    ('approved', 'Disetujui'),
    ('rejected', 'Ditolak'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (value, label) in _options) ...[
            ChoiceChip(
              label: Text(label),
              selected: selectedStatus == value,
              onSelected: (_) => onSelected(value),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _LeaveRequestCard extends StatelessWidget {
  const _LeaveRequestCard({
    required this.item,
    required this.isCancelling,
    this.onCancel,
  });

  final LeaveRequest item;
  final bool isCancelling;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (statusLabel, statusBg, statusFg) = _statusBadgeStyle(
      item.status,
      colors,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_typeIcon(item.type), size: 18, color: colors.primary),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    _typeLabel(item.type),
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    statusLabel,
                    style: context.textTheme.labelSmall?.copyWith(
                      color: statusFg,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 15,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    '${_formatDateRange(item.startDate, item.endDate)} · ${item.days} hari',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(item.reason, style: context.textTheme.bodyMedium),
            if (item.approverName != null && item.approverName!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                item.status == 'rejected'
                    ? 'Ditolak oleh ${item.approverName}'
                    : 'Disetujui oleh ${item.approverName}',
                style: context.textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
            if (item.rejectionReason != null &&
                item.rejectionReason!.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: colors.errorContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  'Alasan penolakan: ${item.rejectionReason}',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: colors.onErrorContainer,
                  ),
                ),
              ),
            ],
            if (onCancel != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: isCancelling ? null : onCancel,
                  icon: isCancelling
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.close, size: 18),
                  label: const Text('Batalkan'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LeaveRequestFormSheet extends ConsumerStatefulWidget {
  const _LeaveRequestFormSheet();

  @override
  ConsumerState<_LeaveRequestFormSheet> createState() =>
      _LeaveRequestFormSheetState();
}

class _LeaveRequestFormSheetState
    extends ConsumerState<_LeaveRequestFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  String _type = 'leave';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  bool _submitting = false;
  String? _errorText;

  static const _types = [
    ('leave', 'Cuti', Icons.beach_access_outlined),
    ('sick', 'Sakit', Icons.local_hospital_outlined),
    ('permission', 'Izin', Icons.assignment_outlined),
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  int get _durationDays {
    final start = DateTime(_startDate.year, _startDate.month, _startDate.day);
    final end = DateTime(_endDate.year, _endDate.month, _endDate.day);
    return end.difference(start).inDays + 1;
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked == null) return;
    setState(() {
      _startDate = picked;
      if (_endDate.isBefore(picked)) {
        _endDate = picked;
      }
    });
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate.isBefore(_startDate) ? _startDate : _endDate,
      firstDate: _startDate,
      lastDate: DateTime(now.year + 2),
    );
    if (picked == null) return;
    setState(() => _endDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _errorText = null;
    });

    try {
      final message = await ref
          .read(leaveRequestsControllerProvider.notifier)
          .submit(
            type: _type,
            startDate: _toApiDate(_startDate),
            endDate: _toApiDate(_endDate),
            reason: _reasonController.text,
          );
      if (mounted) {
        Navigator.of(context).pop(message);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _errorText = describeError(error);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        bottomInset + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Ajukan Cuti & Izin',
                style: context.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Pengajuan akan langsung dikirim ke admin untuk ditinjau.',
                style: context.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Jenis Pengajuan', style: context.textTheme.labelLarge),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  for (final (value, label, icon) in _types)
                    ChoiceChip(
                      avatar: Icon(icon, size: 18),
                      label: Text(label),
                      selected: _type == value,
                      onSelected: _submitting
                          ? null
                          : (_) => setState(() => _type = value),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _DatePickerField(
                      label: 'Tanggal Mulai',
                      value: _formatDisplayDate(_startDate),
                      onTap: _submitting ? null : _pickStartDate,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _DatePickerField(
                      label: 'Tanggal Selesai',
                      value: _formatDisplayDate(_endDate),
                      onTap: _submitting ? null : _pickEndDate,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Total durasi: $_durationDays hari',
                style: context.textTheme.labelMedium?.copyWith(
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _reasonController,
                enabled: !_submitting,
                maxLines: 3,
                maxLength: 1000,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  labelText: 'Alasan Pengajuan',
                  hintText: 'Tuliskan alasan cuti, sakit, atau izin Anda...',
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Alasan pengajuan wajib diisi.';
                  }
                  return null;
                },
              ),
              if (_errorText != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _errorText!,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: colors.error,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(
                  _submitting ? 'Mengirim...' : 'Kirim Pengajuan ke Admin',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.label,
    required this.value,
    this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_month_outlined, size: 18),
        ),
        child: Text(
          value,
          style: context.textTheme.bodyMedium?.copyWith(
            color: colors.onSurface,
          ),
        ),
      ),
    );
  }
}

String _typeLabel(String type) => switch (type) {
  'leave' => 'Cuti',
  'sick' => 'Sakit',
  'permission' => 'Izin',
  _ => type,
};

IconData _typeIcon(String type) => switch (type) {
  'leave' => Icons.beach_access_outlined,
  'sick' => Icons.local_hospital_outlined,
  'permission' => Icons.assignment_outlined,
  _ => Icons.event_note_outlined,
};

(String, Color, Color) _statusBadgeStyle(String status, ColorScheme colors) =>
    switch (status) {
      'approved' => (
        'Disetujui',
        colors.primaryContainer,
        colors.onPrimaryContainer,
      ),
      'rejected' => ('Ditolak', colors.errorContainer, colors.onErrorContainer),
      _ => ('Menunggu', colors.tertiaryContainer, colors.onTertiaryContainer),
    };

String _toApiDate(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

const _monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

String _formatDisplayDate(DateTime date) =>
    '${date.day} ${_monthNames[date.month - 1]} ${date.year}';

String _formatDateRange(String startRaw, String endRaw) {
  final start = DateTime.tryParse(startRaw);
  final end = DateTime.tryParse(endRaw);
  if (start == null || end == null) {
    return startRaw == endRaw ? startRaw : '$startRaw - $endRaw';
  }
  final startLabel = _formatDisplayDate(start);
  final endLabel = _formatDisplayDate(end);
  return startLabel == endLabel ? startLabel : '$startLabel - $endLabel';
}
