import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "Event bus" kecil: layer network (core) memberi tahu bahwa sesi sudah
/// tidak valid, tanpa harus bergantung pada fitur auth.
///
/// Nilainya adalah penghitung; setiap kenaikan berarti satu kejadian
/// "sesi kedaluwarsa". Fitur auth melakukan `ref.listen` pada provider ini.
class SessionExpiryNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void notifyExpired() => state++;
}

final sessionExpiryProvider = NotifierProvider<SessionExpiryNotifier, int>(
  SessionExpiryNotifier.new,
);
