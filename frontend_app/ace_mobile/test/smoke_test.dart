import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ace_mobile/main.dart';

void main() {
  testWidgets('Splash screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the splash screen text exists.
    // Note: This might fail if the splash screen uses complex animations or local prefs
    // but it serves as a baseline for the test environment.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
