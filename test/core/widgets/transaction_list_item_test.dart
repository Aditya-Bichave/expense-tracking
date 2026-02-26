// ignore_for_file: directives_ordering

import 'package:expense_tracker/core/widgets/transaction_list_item.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TransactionListItem', () {
    final tDate = DateTime(2023, 1, 1);
    final tCategory = Category(
      id: 'c1',
      name: 'Food',
      iconName: 'food_icon_that_definitely_falls_back', // Use unknown icon
      colorHex: 'FF0000',
      isCustom: false,
      type: CategoryType.expense,
    );

    final tExpense = TransactionEntity(
      id: '1',
      type: TransactionType.expense,
      title: 'Lunch',
      amount: 10.0,
      date: tDate,
      category: tCategory,
      accountId: 'acc1',
    );

    final tIncome = TransactionEntity(
      id: '2',
      type: TransactionType.income,
      title: 'Salary',
      amount: 1000.0,
      date: tDate,
      category: null, // Should default to uncategorized
      accountId: 'acc1',
      isRecurring: true,
    );

    testWidgets('renders correctly for expense', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionListItem(
              transaction: tExpense,
              currencySymbol: '\$',
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Lunch'), findsOneWidget);
      expect(find.textContaining('Food'), findsOneWidget); // Subtitle
      expect(find.text('- \$10.00'), findsOneWidget); // Trailing

      // Verify an icon is present (fallback or otherwise)
      expect(find.byType(Icon), findsWidgets);
    });

    testWidgets('renders correctly for income', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionListItem(
              transaction: tIncome,
              currencySymbol: '\$',
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Salary'), findsOneWidget);
      expect(find.textContaining('Uncategorized'), findsOneWidget);
      expect(find.text('+ \$1,000.00'), findsOneWidget);
      // Should show recurring icon
      expect(find.byType(SvgPicture), findsOneWidget);
    });

    testWidgets('handles tap', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionListItem(
              transaction: tExpense,
              currencySymbol: '\$',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ListTile));
      expect(tapped, true);
    });
  });
}
