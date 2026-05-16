import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/categories/presentation/widgets/category_list_item_widget.dart';
import 'package:expense_tracker/features/categories/presentation/widgets/category_list_section_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'CategoryListSectionWidget shows empty message when categories list is empty',
    (WidgetTester tester) async {
      const emptyMessage = 'No categories found.';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryListSectionWidget(
              categories: const [],
              emptyMessage: emptyMessage,
              onEditCategory: (_) {},
              onDeleteCategory: (_) {},
              onPersonalizeCategory: (_) {},
            ),
          ),
        ),
      );

      expect(find.text(emptyMessage), findsOneWidget);
    },
  );

  testWidgets(
    'CategoryListSectionWidget renders a sorted list of CategoryListItemWidgets and handles updates',
    (WidgetTester tester) async {
      final category1 = Category(
        id: '1',
        name: 'B Category',
        iconName: 'home',
        colorHex: '#000000',
        type: CategoryType.expense,
        isCustom: false,
      );
      final category2 = Category(
        id: '2',
        name: 'A Category',
        iconName: 'work',
        colorHex: '#FFFFFF',
        type: CategoryType.expense,
        isCustom: false,
      );

      final categories = [category1, category2];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryListSectionWidget(
              categories: categories,
              emptyMessage: 'Empty',
              onEditCategory: (_) {},
              onDeleteCategory: (_) {},
              onPersonalizeCategory: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(CategoryListItemWidget), findsNWidgets(2));

      // Update with new list to test didUpdateWidget
      final category3 = Category(
        id: '3',
        name: 'C Category',
        iconName: 'work',
        colorHex: '#FFFFFF',
        type: CategoryType.expense,
        isCustom: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryListSectionWidget(
              categories: [category3],
              emptyMessage: 'Empty',
              onEditCategory: (_) {},
              onDeleteCategory: (_) {},
              onPersonalizeCategory: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(CategoryListItemWidget), findsNWidgets(1));
    },
  );
}
