import 'package:expense_tracker/features/transactions/presentation/widgets/stitch/stitch_type_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('StitchTypeSelector renders options and handles selection', (
    WidgetTester tester,
  ) async {
    int? selectedIndex;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StitchTypeSelector(
            onTypeChanged: (index) => selectedIndex = index,
          ),
        ),
      ),
    );

    expect(find.text('Personal'), findsOneWidget);
    expect(find.text('Group'), findsOneWidget);

    // Tap Group (index 1)
    await tester.tap(find.text('Group'));
    await tester.pumpAndSettle();

    expect(selectedIndex, equals(1));
  });
}
