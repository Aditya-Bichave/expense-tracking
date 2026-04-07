import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/ui_kit/showcase/ui_kit_showcase_page.dart';

void main() {
  testWidgets('UiKitShowcasePage renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: UiKitShowcasePage()));
    expect(find.byType(UiKitShowcasePage), findsOneWidget);
    expect(find.text('UI Kit Showcase'), findsOneWidget);
  });
}
