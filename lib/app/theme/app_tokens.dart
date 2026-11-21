/// Design token: angka jarak, radius, dan durasi yang dipakai konsisten di
/// seluruh UI. Ubah di sini, seluruh aplikasi ikut berubah.
///
/// Contoh: `const SizedBox(height: AppSpacing.md)`,
/// `EdgeInsets.all(AppSpacing.lg)`.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
}

abstract final class AppDurations {
  static const fast = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 250);

  /// Jeda debounce untuk input pencarian.
  static const debounce = Duration(milliseconds: 400);

  /// Durasi minimum tampilnya halaman splash saat memeriksa sesi.
  static const splash = Duration(seconds: 2);
}
