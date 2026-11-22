import 'package:flutter/material.dart';

import 'package:flutter_antigravity_starter_pack/core/extensions/context_extensions.dart';

/// Tab yang tersedia pada bottom navigation bar utama aplikasi.
enum AppBottomNavTab { home, absensi, settings }

/// Bottom navigation bar yang dapat digunakan ulang di berbagai halaman
/// (misalnya Beranda, Pengaturan, dan halaman lainnya), lengkap dengan
/// tombol Absensi bulat besar di tengah.
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    required this.currentTab,
    this.onHomeTap,
    this.onAbsensiTap,
    this.onSettingsTap,
    super.key,
  });

  final AppBottomNavTab currentTab;
  final VoidCallback? onHomeTap;
  final VoidCallback? onAbsensiTap;
  final VoidCallback? onSettingsTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return SizedBox(
      height: 84 + bottomPadding,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            height: 64 + bottomPadding,
            padding: EdgeInsets.only(bottom: bottomPadding),
            decoration: BoxDecoration(
              color: colors.surfaceContainer,
              border: Border(
                top: BorderSide(color: colors.outlineVariant, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _NavItem(
                    key: const Key('home.nav.home'),
                    icon: Icons.home_rounded,
                    label: 'Home',
                    isActive: currentTab == AppBottomNavTab.home,
                    onTap: onHomeTap ?? () {},
                  ),
                ),
                const SizedBox(width: 80),
                Expanded(
                  child: _NavItem(
                    key: const Key('home.settings'),
                    icon: Icons.settings_outlined,
                    label: 'Setting',
                    isActive: currentTab == AppBottomNavTab.settings,
                    onTap: onSettingsTap ?? () {},
                  ),
                ),
              ],
            ),
          ),
          // Tombol Absensi bulat besar di tengah — disiapkan sebagai placeholder UI.
          Positioned(
            top: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Material(
                  key: const Key('home.absensi'),
                  color: colors.primary,
                  elevation: 4,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onAbsensiTap ?? () {},
                    child: SizedBox(
                      width: 60,
                      height: 60,
                      child: Icon(
                        Icons.fingerprint_rounded,
                        color: colors.onPrimary,
                        size: 32,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Absensi',
                  style: context.textTheme.labelSmall?.copyWith(
                    color: currentTab == AppBottomNavTab.absensi
                        ? colors.primary
                        : colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
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

class _NavItem extends StatelessWidget {
  const _NavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = isActive ? colors.primary : colors.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: context.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
