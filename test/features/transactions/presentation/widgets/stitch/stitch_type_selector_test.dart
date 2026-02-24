import 'package:expense_tracker/features/transactions/presentation/widgets/stitch/stitch_type_selector.dart';
import 'package:expense_tracker/features/transactions/presentation/widgets/stitch/stitch_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('StitchTypeSelector renders options and handles selection', (
    WidgetTester tester,
  ) async {
    StitchTab? selectedTab;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StitchTypeSelector(onTypeChanged: (tab) => selectedTab = tab),
        ),
      ),
    );

    expect(find.text('Personal'), findsOneWidget);
    expect(find.text('Group'), findsOneWidget);

    // Tap Group
    await tester.tap(find.text('Group'));
    await tester.pumpAndSettle();

    expect(selectedTab, equals(StitchTab.group));
  });
}
