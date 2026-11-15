import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Instance [SharedPreferences] dibuat sekali di `main()` lalu di-inject lewat
/// override, sehingga provider lain bisa membacanya secara sinkron.
///
/// Hanya untuk data NON-sensitif (tema, flag onboarding, dsb).
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider harus di-override di main() / test.',
  ),
);
