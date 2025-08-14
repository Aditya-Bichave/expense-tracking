import 'package:expense_tracker/features/transactions/domain/usecases/get_transactions_usecase.dart';
import 'package:expense_tracker/features/transactions/presentation/widgets/transaction_sort_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows default direction icons for unselected options', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: TransactionSortSheet(
            currentSortBy: TransactionSortBy.date,
            currentSortDirection: SortDirection.descending,
            onApplySort: (_, __) {},
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.arrow_downward_rounded), findsNWidgets(2));
    expect(find.byIcon(Icons.arrow_upward_rounded), findsNWidgets(2));
  });

  test('default direction mapping works correctly', () {
    SortDirection defaultDir(TransactionSortBy sortBy) {
      switch (sortBy) {
        case TransactionSortBy.date:
        case TransactionSortBy.amount:
          return SortDirection.descending;
        case TransactionSortBy.category:
        case TransactionSortBy.title:
          return SortDirection.ascending;
      }
    }

    expect(defaultDir(TransactionSortBy.date), SortDirection.descending);
    expect(defaultDir(TransactionSortBy.amount), SortDirection.descending);
    expect(defaultDir(TransactionSortBy.title), SortDirection.ascending);
    expect(defaultDir(TransactionSortBy.category), SortDirection.ascending);
  });
}
