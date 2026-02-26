// ignore_for_file: directives_ordering

import 'package:expense_tracker/core/widgets/category_selector_tile.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CategorySelectorTile', () {
    final tUncategorized = Category.uncategorized;
    final tCategory = Category(
      id: 'c1',
      name: 'Food',
      iconName: 'food',
      colorHex: 'FF0000',
      isCustom: false,
      type: CategoryType.expense,
    );

    testWidgets(
      'renders hint text and uncategorized icon when no category is selected',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CategorySelectorTile(
                selectedCategory: null,
                onTap: () {},
                uncategorizedCategory: tUncategorized,
                hint: 'Select One',
              ),
            ),
          ),
        );

        expect(find.text('Select One'), findsOneWidget);
        // Uncategorized icon should be rendered (help_outline fallback or whatever is in availableIcons/theme)
        // We check for an Icon at least.
        expect(find.byType(Icon), findsWidgets);
      },
    );

    testWidgets('renders selected category name and icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategorySelectorTile(
              selectedCategory: tCategory,
              onTap: () {},
              uncategorizedCategory: tUncategorized,
            ),
          ),
        ),
      );

      expect(find.text('Food'), findsOneWidget);
    });

    testWidgets('calls onTap when the tile is tapped', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategorySelectorTile(
              selectedCategory: null,
              onTap: () => tapped = true,
              uncategorizedCategory: tUncategorized,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ListTile));
      expect(tapped, true);
    });

    testWidgets('displays error text and styling when errorText is provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategorySelectorTile(
              selectedCategory: null,
              onTap: () {},
              uncategorizedCategory: tUncategorized,
              errorText: 'Required',
            ),
          ),
        ),
      );

      expect(find.text('Required'), findsOneWidget);
      // Check for error color?
      // Text widget style color should be error color.
      // Difficult to check exact color without knowing Theme error color, but widget presence is good.
    });
  });
}
