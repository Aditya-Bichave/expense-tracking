import 'package:expense_tracker/features/reports/presentation/widgets/report_page_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ReportPageWrapper renders correctly with title and child', (
    tester,
  ) async {
    const tTitle = 'Test Report';
    const tChildKey = Key('child');

    await tester.pumpWidget(
      MaterialApp(
        home: ReportPageWrapper(
          title: tTitle,
          body: const SizedBox(key: tChildKey),
        ),
      ),
    );

    expect(find.text(tTitle), findsOneWidget);
    expect(find.byKey(tChildKey), findsOneWidget);
    // expect(find.byIcon(Icons.arrow_back), findsOneWidget); // Depends on navigation stack
  });

  // Removed onFilterPressed test as the widget opens a bottom sheet internally
}
