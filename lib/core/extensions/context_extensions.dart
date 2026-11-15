import 'package:flutter/material.dart';

/// Jalan pintas yang sering dipakai di widget:
/// `context.colors.primary`, `context.textTheme.titleLarge`,
/// `context.showSnackBar('Tersimpan')`.
extension BuildContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Lebar layar ≥ 600 dp (tablet / web) — untuk layout responsif sederhana.
  bool get isWide => MediaQuery.sizeOf(this).width >= 600;

  /// Menampilkan snackbar dan menutup snackbar sebelumnya.
  void showSnackBar(String message, {bool isError = false}) {
    final messenger = ScaffoldMessenger.of(this)..hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? colors.error : null,
      ),
    );
  }
}
