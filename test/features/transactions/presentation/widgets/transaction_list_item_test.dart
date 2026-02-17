import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/core/widgets/transaction_list_item.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/pump_app.dart';
import '../../../../helpers/test_data.dart';

class MockOnTap extends Mock {
  void call();
}

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

  final mockRecurringExpense = mockExpense.copyWith(isRecurring: true);

  group('TransactionListItem', () {
    testWidgets('renders expense transaction correctly', (tester) async {
      // ARRANGE
      await pumpWidgetWithProviders(
        tester: tester,
        widget: TransactionListItem(
          transaction: mockExpense,
          currencySymbol: '\$',
          onTap: () {},
        ),
      );

      // ASSERT
      expect(find.text('Groceries'), findsOneWidget);
      expect(
        find.text(
          '${mockCategory.name} • ${DateFormatter.formatDate(mockDate)}',
        ),
        findsOneWidget,
      );
      expect(find.text('- \$123.45'), findsOneWidget);

      final amountText = tester.widget<Text>(find.text('- \$123.45'));
      final theme = Theme.of(tester.element(find.byType(TransactionListItem)));
      expect(amountText.style?.color, theme.colorScheme.error);

      expect(find.byType(SvgPicture), findsNothing);
    });

    testWidgets('renders income transaction correctly', (tester) async {
      // ARRANGE
      await pumpWidgetWithProviders(
        tester: tester,
        widget: TransactionListItem(
          transaction: mockIncome,
          currencySymbol: '€',
          onTap: () {},
        ),
      );

      // ASSERT
      expect(find.text('Paycheck'), findsOneWidget);
      expect(find.text('+ €2,500.00'), findsOneWidget);

      final amountText = tester.widget<Text>(find.text('+ €2,500.00'));
      final theme = Theme.of(tester.element(find.byType(TransactionListItem)));
      expect(amountText.style?.color, theme.colorScheme.primary);
    });

    testWidgets('renders recurring icon when isRecurring is true', (
      tester,
    ) async {
      // ARRANGE
      await pumpWidgetWithProviders(
        tester: tester,
        widget: TransactionListItem(
          transaction: mockRecurringExpense,
          currencySymbol: '\$',
          onTap: () {},
        ),
      );

      // ASSERT
      expect(find.byType(SvgPicture), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      // ARRANGE
      final mockOnTap = MockOnTap();
      await pumpWidgetWithProviders(
        tester: tester,
        widget: TransactionListItem(
          key: const ValueKey('tx_item'),
          transaction: mockExpense,
          currencySymbol: '\$',
          onTap: mockOnTap.call,
        ),
      );

      // ACT
      await tester.tap(find.byKey(const ValueKey('tx_item')));
      await tester.pump();

      // ASSERT
      verify(() => mockOnTap.call()).called(1);
    });
  });
}
