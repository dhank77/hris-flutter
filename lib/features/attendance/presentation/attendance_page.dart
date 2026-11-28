import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_antigravity_starter_pack/app/router/app_routes.dart';
import 'package:flutter_antigravity_starter_pack/app/theme/app_tokens.dart';
import 'package:flutter_antigravity_starter_pack/core/error/app_exception.dart';
import 'package:flutter_antigravity_starter_pack/core/extensions/context_extensions.dart';
import 'package:flutter_antigravity_starter_pack/core/widgets/app_bottom_nav_bar.dart';
import 'package:flutter_antigravity_starter_pack/core/widgets/app_lottie.dart';
import 'package:flutter_antigravity_starter_pack/core/widgets/async_value_view.dart';
import 'package:flutter_antigravity_starter_pack/features/attendance/application/attendance_controller.dart';
import 'package:flutter_antigravity_starter_pack/features/attendance/data/models/attendance.dart';

/// Halaman absensi pegawai dengan validasi radius lokasi kantor berbasis GPS.
class AttendancePage extends ConsumerStatefulWidget {
  const AttendancePage({super.key});

  @override
  ConsumerState<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends ConsumerState<AttendancePage> {
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleClockAction({required bool isClockIn}) async {
    final verifiedEmbedding = await context.push<List<double>>(
      '${AppRoutes.faceRecognition}?mode=attendance',
    );
    if (verifiedEmbedding == null || !mounted) return;

    final controller = ref.read(attendanceControllerProvider.notifier);
    final notes = _notesController.text;
    try {
      final message = isClockIn
          ? await controller.clockIn(
              faceEmbedding: verifiedEmbedding,
              notes: notes,
            )
          : await controller.clockOut(
              faceEmbedding: verifiedEmbedding,
              notes: notes,
            );
      if (!mounted) return;
      _notesController.clear();
      context.showSnackBar(message);
    } catch (error) {
      if (!mounted) return;
      context.showSnackBar(describeError(error), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(attendanceControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Absensi'),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(attendanceControllerProvider.notifier).refresh(),
          ),
        ],
      ),
      body: AsyncValueView(
        value: state,
        onRetry: () =>
            ref.read(attendanceControllerProvider.notifier).refresh(),
        data: (data) => RefreshIndicator(
          onRefresh: () =>
              ref.read(attendanceControllerProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.xl,
            ),
            children: [
              _TodayStatusCard(viewState: data),
              const SizedBox(height: AppSpacing.md),
              _OfficeRadiusCard(
                viewState: data,
                onRefreshLocation: () => ref
                    .read(attendanceControllerProvider.notifier)
                    .refreshLocation(),
              ),
              const SizedBox(height: AppSpacing.md),
              _AttendanceActionCard(
                viewState: data,
                notesController: _notesController,
                onClockIn: () => _handleClockAction(isClockIn: true),
                onClockOut: () => _handleClockAction(isClockIn: false),
              ),
              const SizedBox(height: AppSpacing.lg),
              _MonthlyRecapRow(recap: data.overview.recap),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Riwayat Absensi Terbaru',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (data.history.isEmpty)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: context.colors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: context.colors.outlineVariant,
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    'Belum ada riwayat absensi.',
                    textAlign: TextAlign.center,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                )
              else
                ...data.history.map((item) => _HistoryTile(attendance: item)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentTab: AppBottomNavTab.absensi,
        onHomeTap: () => context.go(AppRoutes.home),
        onSettingsTap: () => context.go(AppRoutes.settings),
      ),
    );
  }
}

class _TodayStatusCard extends StatelessWidget {
  const _TodayStatusCard({required this.viewState});

  final AttendanceViewState viewState;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final attendance = viewState.todayAttendance;

    final String statusLabel;
    final Color badgeBg;
    final Color badgeFg;

    if (viewState.hasClockedOut) {
      statusLabel = 'Selesai';
      badgeBg = colors.primaryContainer;
      badgeFg = colors.onPrimaryContainer;
    } else if (viewState.hasClockedIn) {
      statusLabel = attendance?.status == 'late'
          ? 'Terlambat (${attendance?.lateMinutes ?? 0} mnt)'
          : 'Sudah Clock In';
      badgeBg = attendance?.status == 'late'
          ? colors.errorContainer
          : colors.secondaryContainer;
      badgeFg = attendance?.status == 'late'
          ? colors.onErrorContainer
          : colors.onSecondaryContainer;
    } else {
      statusLabel = 'Belum Clock In';
      badgeBg = colors.surfaceContainerHighest;
      badgeFg = colors.onSurfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.outlineVariant, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Absensi Hari Ini',
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      viewState.overview.today,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusLabel,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: badgeFg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _TimeBox(
                  label: 'Clock In',
                  value: _formatTime(attendance?.clockInAt),
                  icon: Icons.login_rounded,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _TimeBox(
                  label: 'Clock Out',
                  value: _formatTime(attendance?.clockOutAt),
                  icon: Icons.logout_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimeBox extends StatelessWidget {
  const _TimeBox({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.outlineVariant, width: 0.5),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colors.primary),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: context.textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OfficeRadiusCard extends StatelessWidget {
  const _OfficeRadiusCard({
    required this.viewState,
    required this.onRefreshLocation,
  });

  final AttendanceViewState viewState;
  final VoidCallback onRefreshLocation;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final office = viewState.office;
    final distance = viewState.distanceMeters;
    final within = viewState.isWithinRadius;

    final Color statusColor;
    final IconData statusIcon;
    final String statusText;

    if (!office.isConfigured) {
      statusColor = colors.error;
      statusIcon = Icons.location_off_rounded;
      statusText = 'Titik lokasi kantor belum diatur oleh admin/HR.';
    } else if (viewState.isLocating) {
      statusColor = colors.primary;
      statusIcon = Icons.my_location_rounded;
      statusText = 'Mengambil koordinat GPS Anda...';
    } else if (viewState.locationError != null) {
      statusColor = colors.error;
      statusIcon = Icons.gps_off_rounded;
      statusText = viewState.locationError!;
    } else if (distance == null) {
      statusColor = colors.error;
      statusIcon = Icons.location_searching_rounded;
      statusText = 'Koordinat GPS belum tersedia.';
    } else if (within) {
      statusColor = Colors.green.shade700;
      statusIcon = Icons.verified_rounded;
      statusText =
          'Di dalam radius kantor (${distance.round()} m / maks ${office.radiusMeters} m)';
    } else {
      statusColor = colors.error;
      statusIcon = Icons.wrong_location_rounded;
      statusText =
          'Di luar radius kantor (${distance.round()} m / maks ${office.radiusMeters} m)';
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: within ? Colors.green.shade400 : colors.outlineVariant,
          width: within ? 1.2 : 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.business_rounded, size: 20, color: colors.primary),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  office.name,
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: viewState.isLocating ? null : onRefreshLocation,
                icon: viewState.isLocating
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location_rounded, size: 16),
                label: const Text('Perbarui'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(statusIcon, size: 18, color: statusColor),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  statusText,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (viewState.currentPosition != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'GPS Anda: ${viewState.currentPosition!.latitude.toStringAsFixed(6)}, '
              '${viewState.currentPosition!.longitude.toStringAsFixed(6)}',
              style: context.textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AttendanceActionCard extends StatelessWidget {
  const _AttendanceActionCard({
    required this.viewState,
    required this.notesController,
    required this.onClockIn,
    required this.onClockOut,
  });

  final AttendanceViewState viewState;
  final TextEditingController notesController;
  final VoidCallback onClockIn;
  final VoidCallback onClockOut;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (viewState.hasClockedOut) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.primaryContainer.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: colors.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Absensi hari ini sudah lengkap (Clock In & Clock Out).',
                style: context.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final isClockOutMode = viewState.hasClockedIn;
    final enabled = isClockOutMode
        ? viewState.canClockOut
        : viewState.canClockIn;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.outlineVariant, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: notesController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Catatan (opsional)',
              hintText: 'Contoh: Hadir di kantor lantai 2',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            key: Key(
              isClockOutMode ? 'attendance.clockOut' : 'attendance.clockIn',
            ),
            onPressed: enabled
                ? (isClockOutMode ? onClockOut : onClockIn)
                : null,
            icon: viewState.isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    isClockOutMode
                        ? Icons.logout_rounded
                        : Icons.fingerprint_rounded,
                  ),
            label: Text(
              viewState.isSubmitting
                  ? 'Memproses...'
                  : isClockOutMode
                  ? 'Clock Out Sekarang'
                  : 'Clock In Sekarang',
            ),
          ),
          if (viewState.isSubmitting) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AppLottie.biometric(
                  key: Key('attendance.biometricSubmitting'),
                  size: 48,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Mengirim verifikasi absensi biometrik...',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
          if (!viewState.isWithinRadius && !viewState.isLocating) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Tombol absensi aktif otomatis saat Anda berada di dalam radius kantor.',
              textAlign: TextAlign.center,
              style: context.textTheme.labelSmall?.copyWith(
                color: colors.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MonthlyRecapRow extends StatelessWidget {
  const _MonthlyRecapRow({required this.recap});

  final AttendanceRecap recap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _RecapBox(label: 'Hadir', value: recap.present.toString()),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _RecapBox(label: 'Terlambat', value: recap.late.toString()),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _RecapBox(label: 'Izin/Cuti', value: recap.leave.toString()),
        ),
      ],
    );
  }
}

class _RecapBox extends StatelessWidget {
  const _RecapBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.outlineVariant, width: 0.5),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: context.textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.attendance});

  final Attendance attendance;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      elevation: 0,
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: colors.outlineVariant, width: 0.5),
      ),
      child: ListTile(
        leading: Icon(
          attendance.status == 'late'
              ? Icons.schedule_rounded
              : Icons.check_circle_outline_rounded,
          color: attendance.status == 'late' ? colors.error : colors.primary,
        ),
        title: Text(
          attendance.date,
          style: context.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          'Masuk: ${_formatTime(attendance.clockInAt)} • '
          'Pulang: ${_formatTime(attendance.clockOutAt)}',
          style: context.textTheme.bodySmall,
        ),
        trailing: Text(
          attendance.status == 'late'
              ? 'Telat ${attendance.lateMinutes}m'
              : 'Hadir',
          style: context.textTheme.labelMedium?.copyWith(
            color: attendance.status == 'late' ? colors.error : colors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

String _formatTime(String? isoString) {
  if (isoString == null || isoString.isEmpty) return '--:--';
  final parsed = DateTime.tryParse(isoString)?.toLocal();
  if (parsed == null) return '--:--';
  final hh = parsed.hour.toString().padLeft(2, '0');
  final mm = parsed.minute.toString().padLeft(2, '0');
  return '$hh:$mm';
}
