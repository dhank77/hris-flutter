import 'package:flutter/material.dart';

/// Logo resmi aplikasi HRIS yang dapat dipakai ulang di berbagai layar
/// (seperti Splash dan Login).
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 72, this.borderRadius});

  static const assetPath = 'assets/images/app_logo.png';

  final double size;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? size * 0.22;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        semanticLabel: 'Logo HRIS',
      ),
    );
  }
}
