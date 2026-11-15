import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_antigravity_starter_pack/app/app.dart';
import 'package:flutter_antigravity_starter_pack/core/storage/preferences.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('membuka Beranda lalu pindah ke Pengaturan', (tester) async {
    await pumpApp(tester);
    expect(find.text('Beranda'), findsOneWidget);

    await tester.tap(find.byKey(const Key('home.settings')));
    await tester.pumpAndSettle();

    expect(find.text('Pengaturan'), findsOneWidget);
    expect(find.text('Tema'), findsOneWidget);
  });

  testWidgets('mengganti tema tersimpan di preferences', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('home.settings')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Gelap'));
    await tester.pumpAndSettle();

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('settings.theme_mode'), 'dark');
  });
}
