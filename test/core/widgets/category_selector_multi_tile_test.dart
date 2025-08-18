import 'package:expense_tracker/core/widgets/category_selector_multi_tile.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/pump_app.dart';

class MockOnTap extends Mock {
  void call();
}

void main() {
  final mockCategories = const [
    Category(
      id: '1',
      name: 'Groceries',
      iconName: 'groceries',
      colorHex: '#00FF00',
      type: CategoryType.expense,
      isCustom: true,
    ),
    Category(
      id: '2',
      name: 'Transport',
      iconName: 'transport',
      colorHex: '#FF0000',
      type: CategoryType.expense,
      isCustom: true,
    ),
    Category(
      id: '3',
      name: 'Bills',
      iconName: 'bills',
      colorHex: '#0000FF',
      type: CategoryType.expense,
      isCustom: true,
    ),
    Category(
      id: '4',
      name: 'Fun',
      iconName: 'fun',
      colorHex: '#FFFF00',
      type: CategoryType.expense,
      isCustom: true,
    ),
  ];

  group('CategorySelectorMultiTile', () {
    testWidgets('renders hint text when no categories are selected',
        (tester) async {
      // ARRANGE
      await pumpWidgetWithProviders(
        tester: tester,
        widget: Material(
          child: CategorySelectorMultiTile(
            selectedCategoryIds: const [],
            availableCategories: mockCategories,
            onTap: () {},
            hint: 'Select a category',
          ),
        ),
      );

      // ASSERT
      expect(find.text('Select a category'), findsOneWidget);
      expect(find.byIcon(Icons.category_outlined), findsOneWidget);
    });

    testWidgets('renders count and icons when 1 category is selected',
        (tester) async {
      // ARRANGE
      await pumpWidgetWithProviders(
        tester: tester,
        widget: Material(
          child: CategorySelectorMultiTile(
            selectedCategoryIds: const ['1'],
            availableCategories: mockCategories,
            onTap: () {},
          ),
        ),
      );

      // ASSERT
      expect(find.text('1 Categories Selected'), findsOneWidget);
      // The icon is rendered, we can check for the parent Row
      final iconRow = find.descendant(
        of: find.byType(ListTile),
        matching: find.byType(Row),
      );
      expect(iconRow, findsOneWidget);
    });

    testWidgets(
        'displays more indicator when more than 3 categories are selected',
        (tester) async {
      // ARRANGE
      await pumpWidgetWithProviders(
        tester: tester,
        widget: Material(
          child: CategorySelectorMultiTile(
            selectedCategoryIds: const ['1', '2', '3', '4'],
            availableCategories: mockCategories,
            onTap: () {},
          ),
        ),
      );

      // ASSERT
      expect(find.text('4 Categories Selected'), findsOneWidget);
      expect(find.text('+1'), findsOneWidget);
    });

    testWidgets('calls onTap when the tile is tapped', (tester) async {
      // ARRANGE
      final mockOnTap = MockOnTap();
      await pumpWidgetWithProviders(
        tester: tester,
        widget: Material(
          child: CategorySelectorMultiTile(
            key: const ValueKey('category_selector'),
            selectedCategoryIds: const [],
            availableCategories: mockCategories,
            onTap: mockOnTap.call,
          ),
        ),
      );

      // ACT
      await tester.tap(find.byKey(const ValueKey('category_selector')));

      // ASSERT
      verify(() => mockOnTap.call()).called(1);
    });

    testWidgets('displays error text and styling when errorText is provided',
        (tester) async {
      // ARRANGE
      const errorText = 'This is an error';
      await pumpWidgetWithProviders(
        tester: tester,
        widget: Material(
          child: CategorySelectorMultiTile(
            selectedCategoryIds: const [],
            availableCategories: mockCategories,
            onTap: () {},
            errorText: errorText,
          ),
        ),
      );

      // ASSERT
      expect(find.text(errorText), findsOneWidget);

      final tile = tester.widget<ListTile>(find.byType(ListTile));
      final tileShape = tile.shape as OutlineInputBorder;
      final titleWidget = tester.widget<Text>(find.descendant(
        of: find.byType(ListTile),
        matching: find.text('Select Categories'),
      ));
      final errorWidget = tester.widget<Text>(find.text(errorText));

      final theme = Theme.of(tester.element(find.byType(Material)));
      final errorColor = theme.colorScheme.error;

      expect(tileShape.borderSide.color, errorColor);
      expect(titleWidget.style?.color, errorColor);
      expect(errorWidget.style?.color, errorColor);
    });
  });
}
