import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_antigravity_starter_pack/app/router/app_routes.dart';
import 'package:flutter_antigravity_starter_pack/app/theme/app_tokens.dart';
import 'package:flutter_antigravity_starter_pack/core/config/env.dart';
import 'package:flutter_antigravity_starter_pack/core/extensions/context_extensions.dart';
import 'package:flutter_antigravity_starter_pack/core/widgets/app_bottom_nav_bar.dart';
import 'package:flutter_antigravity_starter_pack/features/attendance/application/attendance_controller.dart';
import 'package:flutter_antigravity_starter_pack/features/attendance/data/models/attendance.dart';
import 'package:flutter_antigravity_starter_pack/features/auth/application/auth_controller.dart';
import 'package:flutter_antigravity_starter_pack/features/auth/data/models/auth_user.dart';

/// Halaman utama (dashboard) yang menyambut pengguna setelah login.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).asData?.value;
    final overview = ref.watch(todayAttendanceOverviewProvider).asData?.value;
    final apiBaseUrl = ref.watch(envProvider).apiBaseUrl;

    return Scaffold(
      appBar: AppBar(title: const Text('Beranda')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(todayAttendanceOverviewProvider.future),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.lg,
          ),
          children: [
            _WelcomeBanner(user: user, apiBaseUrl: apiBaseUrl),
            const SizedBox(height: AppSpacing.md),
            _AttendanceSummaryCard(attendance: overview?.attendance),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Menu Cepat',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const _QuickMenuGrid(),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentTab: AppBottomNavTab.home,
        onAbsensiTap: () => context.go(AppRoutes.attendance),
        onSettingsTap: () => context.go(AppRoutes.settings),
      ),
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  const _WelcomeBanner({required this.user, required this.apiBaseUrl});

  final AuthUser? user;
  final String apiBaseUrl;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayName = user?.fullName ?? 'Karyawan';
    final initials = user?.initials ?? 'K';
    final avatarUrl = user?.resolveAvatarUrl(apiBaseUrl);

    final position = user?.position?.trim();
    final department = user?.department?.trim();
    final subtitleLines = <String>[
      if (position != null && position.isNotEmpty) position,
      if (department != null && department.isNotEmpty) department,
    ];
    final subtitle = subtitleLines.isNotEmpty
        ? subtitleLines.join('\n')
        : (user?.email.isNotEmpty ?? false)
        ? user!.email
        : 'Selamat bekerja hari ini';

    final cardColor = isDark
        ? colors.surfaceContainerHigh
        : colors.surfaceContainerLowest;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Aksen pita diagonal di kanan atas belakang kartu (di-clip rapi).
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 120,
          child: ClipRect(
            child: Stack(
              children: [
                Positioned(
                  top: -28,
                  right: 54,
                  child: Transform.rotate(
                    angle: -0.78,
                    child: Container(
                      width: 44,
                      height: 112,
                      decoration: BoxDecoration(
                        color: AppAccentColors.coralSoft.withValues(
                          alpha: isDark ? 0.55 : 0.85,
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: -20,
                  right: -18,
                  child: Transform.rotate(
                    angle: -0.78,
                    child: Container(
                      width: 52,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppAccentColors.amber.withValues(
                          alpha: isDark ? 0.65 : 1,
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Kartu profil utama (sedikit turun agar avatar oval menonjol di atas).
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.lg),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow.withValues(alpha: isDark ? 0.28 : 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              child: InkWell(
                key: const Key('home.profileBanner'),
                borderRadius: BorderRadius.circular(AppRadius.xl),
                onTap: () => context.push(AppRoutes.profile),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 136),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      136,
                      AppSpacing.lg,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.headlineSmall?.copyWith(
                            color: colors.onSurface,
                            fontWeight: FontWeight.bold,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppAccentColors.coralSoft,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Foto profil berbentuk oval yang menonjol di sisi kanan atas kartu.
        Positioned(
          top: 0,
          right: AppSpacing.md,
          child: IgnorePointer(
            child: _BannerProfileAvatar(
              avatarUrl: avatarUrl,
              initials: initials,
            ),
          ),
        ),
      ],
    );
  }
}

class _BannerProfileAvatar extends StatelessWidget {
  const _BannerProfileAvatar({required this.avatarUrl, required this.initials});

  final String? avatarUrl;
  final String initials;

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl;

    return Container(
      key: const Key('home.profileAvatar'),
      width: 108,
      height: 128,
      decoration: const BoxDecoration(
        color: AppAccentColors.coral,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.all(Radius.elliptical(54, 64)),
      ),
      clipBehavior: Clip.antiAlias,
      child: url != null && url.isNotEmpty
          ? Image.network(
              url,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (_, _, _) => _AvatarInitials(initials: initials),
            )
          : _AvatarInitials(initials: initials),
    );
  }
}

class _AvatarInitials extends StatelessWidget {
  const _AvatarInitials({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: context.textTheme.headlineMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _AttendanceSummaryCard extends StatelessWidget {
  const _AttendanceSummaryCard({required this.attendance});

  final Attendance? attendance;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasClockIn = attendance?.clockInAt != null;
    final hasClockOut = attendance?.clockOutAt != null;

    final String statusLabel;
    final Color badgeBg;
    final Color badgeFg;

    if (hasClockOut) {
      statusLabel = 'Selesai';
      badgeBg = colors.primaryContainer;
      badgeFg = colors.onPrimaryContainer;
    } else if (hasClockIn) {
      statusLabel = attendance?.status == 'late' ? 'Terlambat' : 'Sudah Absen';
      badgeBg = attendance?.status == 'late'
          ? colors.errorContainer
          : colors.primaryContainer;
      badgeFg = attendance?.status == 'late'
          ? colors.onErrorContainer
          : colors.onPrimaryContainer;
    } else {
      statusLabel = 'Belum Absen';
      badgeBg = colors.secondaryContainer;
      badgeFg = colors.onSecondaryContainer;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ringkasan Hari Ini',
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
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
                  child: _TimeInfoTile(
                    icon: Icons.login_rounded,
                    label: 'Jam Masuk',
                    value: _formatAttendanceTime(attendance?.clockInAt),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _TimeInfoTile(
                    icon: Icons.logout_rounded,
                    label: 'Jam Pulang',
                    value: _formatAttendanceTime(attendance?.clockOutAt),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _formatAttendanceTime(String? isoString) {
  if (isoString == null || isoString.isEmpty) return '--:--';
  final parsed = DateTime.tryParse(isoString)?.toLocal();
  if (parsed == null) return '--:--';
  final hh = parsed.hour.toString().padLeft(2, '0');
  final mm = parsed.minute.toString().padLeft(2, '0');
  return '$hh:$mm';
}

class _TimeInfoTile extends StatelessWidget {
  const _TimeInfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: context.textTheme.labelSmall),
                Text(
                  value,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickMenuGrid extends StatelessWidget {
  const _QuickMenuGrid();

  static const _menus = [
    (
      Icons.face_retouching_natural,
      'Pengenalan Wajah',
      AppRoutes.faceRecognition,
    ),
    (Icons.event_available_outlined, 'Cuti & Izin', AppRoutes.leaveRequests),
    (Icons.receipt_long_outlined, 'Slip Gaji', null),
    (Icons.history_rounded, 'Riwayat', null),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 2.3,
      children: [
        for (final (icon, label, route) in _menus)
          Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.md),
              onTap: () {
                if (route != null) {
                  context.push(route);
                } else {
                  context.showSnackBar('Fitur $label segera hadir');
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  children: [
                    Icon(icon, color: colors.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.titleSmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
