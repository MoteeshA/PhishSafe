import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:phishsafe_app/main.dart';

void main() {
  testWidgets('PhishSafe UI and toggle test', (WidgetTester tester) async {
    // Build the app and trigger a frame
    await tester.pumpWidget(const PhishSafeApp());

    // Check if the app title is shown
    expect(find.text('PhishSafe'), findsWidgets);

    // Check if Protection Active is visible initially
    expect(find.text('Protection Active'), findsOneWidget);
    expect(find.text('Stop Protection'), findsOneWidget);

    // Tap the stop protection button
    await tester.tap(find.text('Stop Protection'));
    await tester.pumpAndSettle();

    // Check if state changed to paused
    expect(find.text('Protection Paused'), findsOneWidget);
    expect(find.text('Start Protection'), findsOneWidget);

    // Tap the start protection button
    await tester.tap(find.text('Start Protection'));
    await tester.pumpAndSettle();

    // Verify it toggled back
    expect(find.text('Protection Active'), findsOneWidget);
    expect(find.text('Stop Protection'), findsOneWidget);
  });
}
