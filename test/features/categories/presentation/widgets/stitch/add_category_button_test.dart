import 'package:expense_tracker/features/categories/presentation/widgets/stitch/add_category_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AddCategoryButton renders and handles tap', (
    WidgetTester tester,
  ) async {
    bool tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AddCategoryButton(onTap: () => tapped = true)),
      ),
    );

    expect(find.text('Create Custom Category'), findsOneWidget);
    expect(find.byIcon(Icons.add_circle), findsOneWidget);

    await tester.tap(find.byType(AddCategoryButton));
    expect(tapped, isTrue);
  });
}
