import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/features/transactions/presentation/widgets/transaction_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pump_app.dart';
import '../../../../helpers/test_data.dart';

void main() {
  setupFaker();

  final mockCategory = const Category(
    id: 'cat1',
    name: 'Food',
    iconName: 'food',
    colorHex: '#FFFF00',
    type: CategoryType.expense,
    isCustom: true,
  );
  final mockDate = DateTime(2023, 1, 15);

  final mockExpense = TransactionEntity(
    id: faker.guid.guid(),
    type: TransactionType.expense,
    title: 'Groceries',
    amount: 123.45,
    date: mockDate,
    category: mockCategory,
    isRecurring: false,
  );

  final mockIncome = mockExpense.copyWith(
    type: TransactionType.income,
    title: 'Paycheck',
    amount: 2500.00,
  );

  group('TransactionListItem Accessibility', () {
    testWidgets('Amount has semantic label for Expense', (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: TransactionListItem(
          transaction: mockExpense,
          currencySymbol: '\$',
          onTap: () {},
        ),
      );

      // Use RegExp to match the semantic label flexibly (ignoring specific whitespace or exact currency format)
      expect(find.bySemanticsLabel(RegExp(r'Expense of.*123\.45')),
          findsOneWidget);
    });

    testWidgets('Amount has semantic label for Income', (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: TransactionListItem(
          transaction: mockIncome,
          currencySymbol: '€',
          onTap: () {},
        ),
      );

      // Use RegExp to match the semantic label flexibly
      expect(find.bySemanticsLabel(RegExp(r'Income of.*2,500\.00')),
          findsOneWidget);
    });

    testWidgets('Leading icon is excluded from semantics', (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: TransactionListItem(
          transaction: mockExpense,
          currencySymbol: '\$',
          onTap: () {},
        ),
      );

      // Find the CircleAvatar
      final circleAvatarFinder = find.byType(CircleAvatar);
      expect(circleAvatarFinder, findsOneWidget);

      // Ensure it has an ExcludeSemantics ancestor
      final excludeSemanticsAncestor = find.ancestor(
        of: circleAvatarFinder,
        matching: find.byType(ExcludeSemantics),
      );

      expect(excludeSemanticsAncestor, findsOneWidget);
    });
  });
}
