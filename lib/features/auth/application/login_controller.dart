import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_antigravity_starter_pack/core/error/app_exception.dart';
import 'package:flutter_antigravity_starter_pack/features/auth/application/auth_controller.dart';

/// State pengiriman form login (loading & error terpisah dari sesi global).
class LoginController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> submit({required String email, required String password}) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref
          .read(authControllerProvider.notifier)
          .login(email: email, password: password),
    );
    if (!ref.mounted) return false;
    state = result;
    return !result.hasError;
  }

  Future<bool> submitGoogle() async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(authControllerProvider.notifier).loginWithGoogle(),
    );
    if (!ref.mounted) return false;
    if (result.error is CancelledException) {
      state = const AsyncData(null);
      return false;
    }
    state = result;
    return !result.hasError;
  }
}

final loginControllerProvider =
    AsyncNotifierProvider.autoDispose<LoginController, void>(
      LoginController.new,
    );
