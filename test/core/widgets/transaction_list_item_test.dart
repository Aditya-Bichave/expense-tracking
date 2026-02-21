import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/widgets/transaction_list_item.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/categorization_status.dart';

void main() {
  final tDate = DateTime(2023, 1, 1);
  final tCategory = Category.uncategorized;
  final tTransaction = TransactionEntity(
    id: '1',
    type: TransactionType.expense,
    title: 'Test Expense',
    amount: 100.0,
    date: tDate,
    category: tCategory,
    status: CategorizationStatus.categorized,
  );

  testWidgets('TransactionListItem renders correctly for expense', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TransactionListItem(
            transaction: tTransaction,
            currencySymbol: '\$',
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('Test Expense'), findsOneWidget);
    // Date formatting depends on locale, assuming default US or checking partial match
    // DateFormatter.formatDate(tDate) -> likely "Jan 1, 2023" or similar
    // We can check if it finds *something* with date.

    // Amount
    expect(find.text('- \$100.00'), findsOneWidget); // Assuming standard formatting

    // Subtitle contains Category name
    expect(find.textContaining('Uncategorized'), findsOneWidget);
  });

  testWidgets('TransactionListItem renders correctly for income', (WidgetTester tester) async {
     final tIncome = TransactionEntity(
      id: '2',
      type: TransactionType.income,
      title: 'Test Income',
      amount: 200.0,
      date: tDate,
      category: tCategory,
      status: CategorizationStatus.categorized,
    );

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

    expect(find.text('Test Income'), findsOneWidget);
    expect(find.text('+ \$200.00'), findsOneWidget);
  });

  testWidgets('TransactionListItem handles tap', (WidgetTester tester) async {
    bool tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TransactionListItem(
            transaction: tTransaction,
            currencySymbol: '\$',
            onTap: () {
              tapped = true;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byType(ListTile));
    expect(tapped, true);
  });
}
