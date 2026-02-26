// ignore_for_file: directives_ordering

import 'package:expense_tracker/core/widgets/category_selector_multi_tile.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CategorySelectorMultiTile', () {
    final tCategories = [
      Category(
        id: 'c1',
        name: 'Cat 1',
        iconName: 'icon1',
        colorHex: 'FFFFFF',
        isCustom: false,
        type: CategoryType.expense,
      ),
      Category(
        id: 'c2',
        name: 'Cat 2',
        iconName: 'icon2',
        colorHex: 'FFFFFF',
        isCustom: false,
        type: CategoryType.expense,
      ),
      Category(
        id: 'c3',
        name: 'Cat 3',
        iconName: 'icon3',
        colorHex: 'FFFFFF',
        isCustom: false,
        type: CategoryType.expense,
      ),
      Category(
        id: 'c4',
        name: 'Cat 4',
        iconName: 'icon4',
        colorHex: 'FFFFFF',
        isCustom: false,
        type: CategoryType.expense,
      ),
    ];

    testWidgets('renders hint text when no categories are selected', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategorySelectorMultiTile(
              selectedCategoryIds: const [],
              availableCategories: tCategories,
              onTap: () {},
              hint: 'Select Multiple',
            ),
          ),
        ),
      );

      expect(find.text('Select Multiple'), findsOneWidget);
      expect(find.byIcon(Icons.category_outlined), findsOneWidget);
    });

    testWidgets('renders count and icons when 1 category is selected', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategorySelectorMultiTile(
              selectedCategoryIds: const ['c1'],
              availableCategories: tCategories,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('1 Categories Selected'), findsOneWidget);
      // Should show 1 icon row
      expect(find.byType(Row), findsWidgets);
      // Verify Padding which wraps the icons
      expect(find.byType(Padding), findsWidgets);
    });

    testWidgets(
      'displays more indicator when more than 3 categories are selected',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CategorySelectorMultiTile(
                selectedCategoryIds: const ['c1', 'c2', 'c3', 'c4'],
                availableCategories: tCategories,
                onTap: () {},
              ),
            ),
          ),
        );

        // +1 text should be visible (4 selected, max 3 shown)
        expect(find.text('+1'), findsOneWidget);
      },
    );

    testWidgets('calls onTap when the tile is tapped', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategorySelectorMultiTile(
              selectedCategoryIds: const [],
              availableCategories: tCategories,
              onTap: () => tapped = true,
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
            body: CategorySelectorMultiTile(
              selectedCategoryIds: const [],
              availableCategories: tCategories,
              onTap: () {},
              errorText: 'Required',
            ),
          ),
        ),
      );

      expect(find.text('Required'), findsOneWidget);
    });
  });
}
