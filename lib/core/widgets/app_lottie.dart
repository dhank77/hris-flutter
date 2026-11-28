import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Daftar path aset animasi Lottie yang tersedia di proyek.
abstract final class AppLottieAssets {
  static const loading = 'assets/lotties/loading.json';
  static const biometric = 'assets/lotties/biometric.json';
}

/// Widget reusable untuk menampilkan animasi Lottie dari aset lokal.
class AppLottie extends StatelessWidget {
  const AppLottie({
    required this.asset,
    this.size,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.repeat = true,
    this.animate = true,
    super.key,
  });

  /// Animasi loading standar aplikasi (`assets/lotties/loading.json`).
  const AppLottie.loading({
    double size = 120,
    BoxFit fit = BoxFit.contain,
    bool repeat = true,
    bool animate = true,
    Key? key,
  }) : this(
         key: key,
         asset: AppLottieAssets.loading,
         size: size,
         fit: fit,
         repeat: repeat,
         animate: animate,
       );

  /// Animasi biometrik / pemindaian wajah (`assets/lotties/biometric.json`).
  const AppLottie.biometric({
    double size = 120,
    BoxFit fit = BoxFit.contain,
    bool repeat = true,
    bool animate = true,
    Key? key,
  }) : this(
         key: key,
         asset: AppLottieAssets.biometric,
         size: size,
         fit: fit,
         repeat: repeat,
         animate: animate,
       );

  final String asset;
  final double? size;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool repeat;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final effectiveWidth = width ?? size;
    final effectiveHeight = height ?? size;

    return Lottie.asset(
      asset,
      width: effectiveWidth,
      height: effectiveHeight,
      fit: fit,
      repeat: repeat,
      animate: animate,
      errorBuilder: (context, error, stackTrace) => SizedBox(
        width: effectiveWidth ?? 36,
        height: effectiveHeight ?? 36,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
      ),
    );
  }
}
