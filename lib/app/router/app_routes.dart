/// Semua path route di satu tempat — UI tidak boleh menulis string path
/// sendiri. Pakai `context.go(AppRoutes.settings)` / `context.push(...)`.
abstract final class AppRoutes {
  static const splash = '/splash';
  static const home = '/';
  static const settings = '/settings';
  static const aboutInfo = '/settings/info';
  static const login = '/login';

  static const attendance = '/attendance';

  static const faceRecognition = '/face-recognition';

  static const profile = '/profile';

  static const leaveRequests = '/leave-requests';

  // <generator:paths> — scripts/new_feature.sh menambahkan path di atas baris ini.
}
