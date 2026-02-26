import 'package:expense_tracker/ui_kit/showcase/ui_kit_showcase_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('UiKitShowcasePage renders without crashing', (tester) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: UiKitShowcasePage()));

    // Use pump instead of pumpAndSettle because of infinite animations (e.g. Skeleton)
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('UI Kit Showcase'), findsOneWidget);
    expect(find.text('Typography'), findsOneWidget);
    expect(find.text('Buttons'), findsOneWidget);
  });
}
