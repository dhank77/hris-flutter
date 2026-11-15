import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_antigravity_starter_pack/core/widgets/state_views.dart';

/// Menampilkan [AsyncValue] dengan UI standar:
/// loading → [LoadingView], error → [ErrorView] (+ tombol coba lagi),
/// data → [data].
///
/// ```dart
/// AsyncValueView(
///   value: ref.watch(productDetailProvider(id)),
///   onRetry: () => ref.invalidate(productDetailProvider(id)),
///   data: (product) => ProductDetail(product: product),
/// )
/// ```
///
/// Saat provider di-refresh dan data lama masih ada, data lama tetap
/// ditampilkan (perilaku default `AsyncValue.when`).
class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({
    required this.value,
    required this.data,
    this.onRetry,
    this.loading,
    super.key,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;

  /// Ganti tampilan loading default, mis. skeleton.
  final Widget? loading;

  @override
  Widget build(BuildContext context) => value.when(
    data: data,
    error: (error, _) => ErrorView(error: error, onRetry: onRetry),
    loading: () => loading ?? const LoadingView(),
  );
}
