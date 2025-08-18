import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/categories/presentation/widgets/category_picker_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  final mockCategories = [
    const Category(
      id: '1',
      name: 'Food',
      iconName: 'food',
      colorHex: '#ff0000',
      type: CategoryType.expense,
      isCustom: true,
    ),
    const Category(
      id: '2',
      name: 'Shopping',
      iconName: 'shopping',
      colorHex: '#00ff00',
      type: CategoryType.expense,
      isCustom: true,
    ),
  ];

  group('CategoryPickerDialogContent', () {
    testWidgets('renders a list of categories', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CategoryPickerDialogContent(
            categoryType: CategoryTypeFilter.expense,
            categories: mockCategories,
          ),
        ),
      ));

      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Shopping'), findsOneWidget);
    });

    testWidgets('filters categories based on search', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CategoryPickerDialogContent(
            categoryType: CategoryTypeFilter.expense,
            categories: mockCategories,
          ),
        ),
      ));

      await tester.enterText(find.byType(TextField), 'shop');
      await tester.pump();

      expect(find.text('Food'), findsNothing);
      expect(find.text('Shopping'), findsOneWidget);
    });

    testWidgets('tapping a category pops with the selected category',
        (tester) async {
      Category? result;
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) {
          return Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await showCategoryPicker(
                    context, CategoryTypeFilter.expense, mockCategories);
              },
              child: const Text('Show'),
            ),
          );
        }),
      ));

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Food'));
      await tester.pumpAndSettle();

      expect(result, mockCategories.first);
    });

    testWidgets('shows "Add New" button', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: CategoryPickerDialogContent(
            categoryType: CategoryTypeFilter.expense,
            categories: [],
          ),
        ),
      ));
      expect(
        find.byKey(const ValueKey('button_add_new_category')),
        findsOneWidget,
      );
    });
  });
}
