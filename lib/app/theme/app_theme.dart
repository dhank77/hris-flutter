import 'package:flutter/material.dart';

import 'package:flutter_antigravity_starter_pack/app/theme/app_tokens.dart';

/// Tema Material 3 aplikasi. Ganti [seedColor] untuk mengganti warna brand;
/// seluruh palet terang & gelap diturunkan otomatis.
abstract final class AppTheme {
  static const seedColor = Color(0xFF2563EB);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final colors = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );
    final roundedMd = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    );

    return ThemeData(
      colorScheme: colors,
      useMaterial3: true,
      appBarTheme: const AppBarTheme(centerTitle: false),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: roundedMd,
        ),
      ),
      cardTheme: CardThemeData(shape: roundedMd, margin: EdgeInsets.zero),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      ),
    );
  }
}
