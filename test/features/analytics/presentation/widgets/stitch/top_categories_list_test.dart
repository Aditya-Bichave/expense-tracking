import 'package:expense_tracker/features/analytics/presentation/widgets/stitch/top_categories_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('TopCategoriesList renders correctly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: TopCategoriesList())),
    );

    expect(find.text('Top Categories'), findsOneWidget);
    expect(find.text('Food & Drinks'), findsOneWidget); // Static data
    expect(find.text('\$840.20'), findsOneWidget);
  });
}
