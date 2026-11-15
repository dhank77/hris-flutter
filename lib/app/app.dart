import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_antigravity_starter_pack/app/router/app_router.dart';
import 'package:flutter_antigravity_starter_pack/app/theme/app_theme.dart';
import 'package:flutter_antigravity_starter_pack/app/theme/theme_mode_controller.dart';

/// Widget akar: menyatukan router, tema, dan mode tema.
class App extends ConsumerWidget {
  const App({super.key});

  static const title = 'Flutter AI Starter';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeControllerProvider);

    return MaterialApp.router(
      title: title,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
