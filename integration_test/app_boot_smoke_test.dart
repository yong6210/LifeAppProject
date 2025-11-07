import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:life_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('launches Life App shell', (tester) async {
    await app.main();
    // Allow initial animations/network stubs to settle.
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
