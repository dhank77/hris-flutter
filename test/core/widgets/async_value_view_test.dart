import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_antigravity_starter_pack/core/error/app_exception.dart';
import 'package:flutter_antigravity_starter_pack/core/widgets/async_value_view.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('loading menampilkan indikator', (tester) async {
    await tester.pumpWidget(
      _wrap(
        AsyncValueView<String>(
          value: const AsyncLoading(),
          data: (value) => Text(value),
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('data menampilkan builder', (tester) async {
    await tester.pumpWidget(
      _wrap(
        AsyncValueView<String>(
          value: const AsyncData('halo'),
          data: (value) => Text(value),
        ),
      ),
    );
    expect(find.text('halo'), findsOneWidget);
  });

  testWidgets('error menampilkan pesan + tombol coba lagi', (tester) async {
    var retried = 0;
    await tester.pumpWidget(
      _wrap(
        AsyncValueView<String>(
          value: const AsyncError(
            NetworkException('offline'),
            StackTrace.empty,
          ),
          onRetry: () => retried++,
          data: (value) => Text(value),
        ),
      ),
    );

    expect(find.text('offline'), findsOneWidget);
    await tester.tap(find.text('Coba lagi'));
    expect(retried, 1);
  });
}
