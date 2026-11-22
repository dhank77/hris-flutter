import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_antigravity_starter_pack/app/router/app_routes.dart';
import 'package:flutter_antigravity_starter_pack/app/theme/app_tokens.dart';
import 'package:flutter_antigravity_starter_pack/core/extensions/context_extensions.dart';
import 'package:flutter_antigravity_starter_pack/core/widgets/app_bottom_nav_bar.dart';
import 'package:flutter_antigravity_starter_pack/features/auth/application/auth_controller.dart';
import 'package:flutter_antigravity_starter_pack/features/auth/data/models/auth_user.dart';

/// Halaman utama (dashboard) yang menyambut pengguna setelah login.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).asData?.value;

    return Scaffold(
      appBar: AppBar(title: const Text('Beranda')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        children: [
          _WelcomeBanner(user: user),
          const SizedBox(height: AppSpacing.md),
          const _AttendanceSummaryCard(),
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
      bottomNavigationBar: AppBottomNavBar(
        currentTab: AppBottomNavTab.home,
        onAbsensiTap: () => context.go(AppRoutes.attendance),
        onSettingsTap: () => context.go(AppRoutes.settings),
      ),
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  const _WelcomeBanner({required this.user});

  final AuthUser? user;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final displayName = user?.fullName ?? 'Karyawan';
    final subtitle = (user?.email.isNotEmpty ?? false)
        ? user!.email
        : 'Selamat bekerja hari ini';
    final initial = displayName.isNotEmpty
        ? displayName.characters.first.toUpperCase()
        : 'K';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: colors.primary,
            foregroundColor: colors.onPrimary,
            child: Text(
              initial,
              style: context.textTheme.titleLarge?.copyWith(
                color: colors.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selamat datang,',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: colors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.titleLarge?.copyWith(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: colors.onPrimaryContainer.withValues(alpha: 0.8),
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

class _AttendanceSummaryCard extends StatelessWidget {
  const _AttendanceSummaryCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

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
                    color: colors.secondaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    'Belum Absen',
                    style: context.textTheme.labelSmall?.copyWith(
                      color: colors.onSecondaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Row(
              children: [
                Expanded(
                  child: _TimeInfoTile(
                    icon: Icons.login_rounded,
                    label: 'Jam Masuk',
                    value: '--:--',
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _TimeInfoTile(
                    icon: Icons.logout_rounded,
                    label: 'Jam Pulang',
                    value: '--:--',
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
    (Icons.event_available_outlined, 'Cuti & Izin'),
    (Icons.receipt_long_outlined, 'Slip Gaji'),
    (Icons.history_rounded, 'Riwayat'),
    (Icons.calendar_month_outlined, 'Jadwal'),
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
        for (final (icon, label) in _menus)
          Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.md),
              onTap: () => context.showSnackBar('Fitur $label segera hadir'),
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
