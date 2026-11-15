import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_antigravity_starter_pack/app/router/app_routes.dart';
import 'package:flutter_antigravity_starter_pack/app/theme/app_tokens.dart';
import 'package:flutter_antigravity_starter_pack/core/extensions/context_extensions.dart';

/// Halaman awal boilerplate. Ganti isinya dengan layar pertama aplikasimu,
/// atau arahkan [AppRoutes.home] ke fitur lain.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const _steps = [
    ('Buat fitur pertama', 'make feature name=posts'),
    ('Jalankan pengecekan', 'make check'),
    ('Lihat contoh lengkap', 'git switch example'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beranda'),
        actions: [
          IconButton(
            key: const Key('home.settings'),
            tooltip: 'Pengaturan',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Icon(
            Icons.rocket_launch_outlined,
            size: 56,
            color: context.colors.primary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Siap dibangun',
            textAlign: TextAlign.center,
            style: context.textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Fondasi sudah terpasang: router, tema, networking, '
            'penanganan error, dan toolkit agen AI.',
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final (title, command) in _steps)
            Card(
              child: ListTile(
                title: Text(title),
                subtitle: Text(
                  command,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
