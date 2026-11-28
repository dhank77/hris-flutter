import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

import 'package:flutter_antigravity_starter_pack/core/widgets/app_lottie.dart';
import 'package:flutter_antigravity_starter_pack/core/widgets/state_views.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('AppLottie.loading memuat aset loading.json', (tester) async {
    await tester.pumpWidget(_wrap(const AppLottie.loading(size: 96)));

    final appLottie = tester.widget<AppLottie>(find.byType(AppLottie));
    expect(appLottie.asset, AppLottieAssets.loading);
    expect(appLottie.size, 96);
    expect(find.byType(Lottie), findsOneWidget);
  });

  testWidgets('AppLottie.biometric memuat aset biometric.json', (tester) async {
    await tester.pumpWidget(_wrap(const AppLottie.biometric(size: 80)));

    final appLottie = tester.widget<AppLottie>(find.byType(AppLottie));
    expect(appLottie.asset, AppLottieAssets.biometric);
    expect(appLottie.size, 80);
    expect(find.byType(Lottie), findsOneWidget);
  });

  testWidgets('LoadingView menampilkan AppLottie dan pesan opsional', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const LoadingView(message: 'Memuat data...')),
    );

    expect(find.byType(AppLottie), findsOneWidget);
    expect(find.text('Memuat data...'), findsOneWidget);
  });
}
