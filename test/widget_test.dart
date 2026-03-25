// Smoke test verifying the Flutter test framework is functional.
// DrawbackApp cannot be pumped in unit tests because it depends on
// platform plugins (Firebase, FlutterSecureStorage) that require a real
// device or integration-test environment. End-to-end app boot is covered
// by the integration tests in integration_test/.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('test framework smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold()));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
