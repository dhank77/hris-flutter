import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_antigravity_starter_pack/features/settings/presentation/about_info_page.dart';

void main() {
  testWidgets(
    'memuat URL landing page informasi, menampilkan progress lalu selesai',
    (tester) async {
      Uri? loadedUri;
      late ValueChanged<int> triggerProgress;
      late VoidCallback triggerFinished;
      var reloadCount = 0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            infoWebViewBuilderProvider.overrideWithValue(({
              required initialUri,
              required onProgress,
              required onPageFinished,
              required onError,
              required onReloadReady,
            }) {
              loadedUri = initialUri;
              triggerProgress = onProgress;
              triggerFinished = onPageFinished;
              onReloadReady(() async {
                reloadCount++;
              });
              return const Center(child: Text('Fake WebView'));
            }),
          ],
          child: const MaterialApp(home: AboutInfoPage()),
        ),
      );

      expect(
        loadedUri.toString(),
        'https://darkred-mule-141907.hostingersite.com/',
      );
      expect(find.text('Tentang & Informasi'), findsOneWidget);
      expect(find.byKey(const Key('aboutInfo.progress')), findsOneWidget);
      expect(find.text('Fake WebView'), findsOneWidget);

      triggerProgress(50);
      await tester.pump();
      expect(find.byKey(const Key('aboutInfo.progress')), findsOneWidget);

      triggerFinished();
      await tester.pump();
      expect(find.byKey(const Key('aboutInfo.progress')), findsNothing);

      await tester.tap(find.byKey(const Key('aboutInfo.refresh')));
      await tester.pump();
      expect(reloadCount, 1);
      expect(find.byKey(const Key('aboutInfo.progress')), findsOneWidget);
    },
  );

  testWidgets('menampilkan ErrorView saat gagal memuat dan bisa coba lagi', (
    tester,
  ) async {
    late ValueChanged<String> triggerError;
    var reloadCount = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          infoWebViewBuilderProvider.overrideWithValue(({
            required initialUri,
            required onProgress,
            required onPageFinished,
            required onError,
            required onReloadReady,
          }) {
            triggerError = onError;
            onReloadReady(() async {
              reloadCount++;
            });
            return const SizedBox.shrink();
          }),
        ],
        child: const MaterialApp(home: AboutInfoPage()),
      ),
    );

    triggerError('Koneksi terputus');
    await tester.pump();

    expect(find.text('Koneksi terputus'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);

    await tester.tap(find.text('Coba lagi'));
    await tester.pump();

    expect(reloadCount, 1);
    expect(find.text('Koneksi terputus'), findsNothing);
  });
}
