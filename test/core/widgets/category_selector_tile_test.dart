import 'package:expense_tracker/core/widgets/category_selector_tile.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/pump_app.dart';

class MockOnTap extends Mock {
  void call();
}

void main() {
  final uncategorized = Category(id: 'uncat', name: 'Uncategorized', iconName: 'help', color: 0xFF888888);
  final mockCategory = Category(id: '1', name: 'Groceries', iconName: 'groceries', color: 0xFF00FF00);

  group('CategorySelectorTile', () {
    testWidgets('renders hint text and uncategorized icon when no category is selected', (tester) async {
      // ARRANGE
      await pumpWidgetWithProviders(
        tester: tester,
        widget: Material(
          child: CategorySelectorTile(
            selectedCategory: null,
            uncategorizedCategory: uncategorized,
            onTap: () {},
            hint: 'Please select one',
          ),
        ),
      );

      // ASSERT
      expect(find.text('Please select one'), findsOneWidget);
      // We expect the icon from the 'uncategorized' placeholder to be used
      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.color, Colors.grey.shade600); // disabledColor
    });

    testWidgets('renders selected category name and icon', (tester) async {
      // ARRANGE
      await pumpWidgetWithProviders(
        tester: tester,
        widget: Material(
          child: CategorySelectorTile(
            selectedCategory: mockCategory,
            uncategorizedCategory: uncategorized,
            onTap: () {},
          ),
        ),
      );

      // ASSERT
      expect(find.text('Groceries'), findsOneWidget);
      // Check that the icon is present and has the correct color
      final icon = find.byType(Icon); // Assuming fallback icon
      final iconWidget = tester.widget<Icon>(icon);
      expect(iconWidget.color, mockCategory.displayColor);
    });

    testWidgets('calls onTap when the tile is tapped', (tester) async {
      // ARRANGE
      final mockOnTap = MockOnTap();
      await pumpWidgetWithProviders(
        tester: tester,
        widget: Material(
          child: CategorySelectorTile(
            key: const ValueKey('category_tile'),
            selectedCategory: null,
            uncategorizedCategory: uncategorized,
            onTap: mockOnTap.call,
          ),
        ),
      );

      // ACT
      await tester.tap(find.byKey(const ValueKey('category_tile')));

      // ASSERT
      verify(() => mockOnTap.call()).called(1);
    });

    testWidgets('displays error text and styling when errorText is provided', (tester) async {
      // ARRANGE
      const errorText = 'Category is required';
      await pumpWidgetWithProviders(
        tester: tester,
        widget: Material(
          child: CategorySelectorTile(
            selectedCategory: null,
            uncategorizedCategory: uncategorized,
            onTap: () {},
            errorText: errorText,
            hint: 'Select Category',
          ),
        ),
      );

      // ASSERT
      expect(find.text(errorText), findsOneWidget);

      final theme = Theme.of(tester.element(find.byType(Material)));
      final errorColor = theme.colorScheme.error;

      final tile = tester.widget<ListTile>(find.byType(ListTile));
      final tileShape = tile.shape as OutlineInputBorder;
      expect(tileShape.borderSide.color, errorColor);

      final titleWidget = tester.widget<Text>(find.text('Select Category'));
      expect(titleWidget.style?.color, errorColor);
    });
  });
}
