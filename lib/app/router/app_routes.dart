/// Semua path route di satu tempat — UI tidak boleh menulis string path
/// sendiri. Pakai `context.go(AppRoutes.settings)` / `context.push(...)`.
abstract final class AppRoutes {
  static const splash = '/splash';
  static const home = '/';
  static const settings = '/settings';
  static const login = '/login';

  // <generator:paths> — scripts/new_feature.sh menambahkan path di atas baris ini.
}
