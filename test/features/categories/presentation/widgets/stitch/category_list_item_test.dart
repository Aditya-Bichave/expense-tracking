import 'package:expense_tracker/features/categories/presentation/widgets/stitch/category_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CategoryListItem renders correctly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CategoryListItem(
            name: 'Food',
            description: 'Eating out',
            icon: Icons.restaurant,
            iconColor: Colors.orange,
          ),
        ),
      ),
    );

    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Eating out'), findsOneWidget);
    expect(find.byIcon(Icons.restaurant), findsOneWidget);
  });
}
