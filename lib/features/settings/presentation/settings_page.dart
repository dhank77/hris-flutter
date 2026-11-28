import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_antigravity_starter_pack/app/router/app_routes.dart';
import 'package:flutter_antigravity_starter_pack/app/theme/app_tokens.dart';
import 'package:flutter_antigravity_starter_pack/app/theme/theme_mode_controller.dart';
import 'package:flutter_antigravity_starter_pack/core/config/env.dart';
import 'package:flutter_antigravity_starter_pack/core/extensions/context_extensions.dart';
import 'package:flutter_antigravity_starter_pack/core/widgets/app_bottom_nav_bar.dart';
import 'package:flutter_antigravity_starter_pack/features/auth/application/auth_controller.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeControllerProvider);
    final env = ref.watch(envProvider);
    final user = ref.watch(authControllerProvider).asData?.value;

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        children: [
          if (user != null) ...[
            ListTile(
              leading: CircleAvatar(
                child: Text(user.fullName.characters.first.toUpperCase()),
              ),
              title: Text(user.fullName),
              subtitle: Text(user.email),
            ),
            const Divider(height: AppSpacing.md),
          ],
          const ListTile(title: Text('Tema')),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.brightness_auto),
                  label: Text('Sistem'),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode),
                  label: Text('Terang'),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode),
                  label: Text('Gelap'),
                ),
              ],
              selected: {themeMode},
              onSelectionChanged: (selection) => ref
                  .read(themeModeControllerProvider.notifier)
                  .setThemeMode(selection.first),
            ),
          ),
          const Divider(height: AppSpacing.xl),
          ListTile(
            key: const Key('settings.faceRecognition'),
            leading: const Icon(Icons.face_retouching_natural),
            title: const Text('Registrasi & Pengenalan Wajah'),
            subtitle: const Text(
              'Kelola data wajah untuk verifikasi biometrik',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.faceRecognition),
          ),
          const Divider(height: AppSpacing.xl),
          ListTile(
            key: const Key('settings.aboutInfo'),
            leading: const Icon(Icons.info_outline),
            title: const Text('Tentang & Informasi'),
            subtitle: const Text('Halaman informasi dan profil aplikasi'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.aboutInfo),
          ),
          const Divider(height: AppSpacing.xl),
          ListTile(
            leading: const Icon(Icons.cloud_outlined),
            title: const Text('API'),
            subtitle: Text(env.apiBaseUrl),
          ),
          if (user != null) ...[
            const Divider(height: AppSpacing.xl),
            ListTile(
              key: const Key('settings.logout'),
              leading: Icon(Icons.logout, color: context.colors.error),
              title: Text(
                'Keluar',
                style: TextStyle(color: context.colors.error),
              ),
              onTap: () => ref.read(authControllerProvider.notifier).logout(),
            ),
          ],
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentTab: AppBottomNavTab.settings,
        onHomeTap: () => context.go(AppRoutes.home),
        onAbsensiTap: () => context.go(AppRoutes.attendance),
      ),
    );
  }
}
